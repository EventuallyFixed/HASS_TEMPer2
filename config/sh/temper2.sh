#!/bin/bash
#
# File outputs
JSONFILE=files/temper2.json
LOGFILE=files/temper2.log
# Comma separated list of USB Device IDs
DEVICEIDS=1a86:e025,3553:a001
declare -A hidDevices


#echo "BEGIN SCRIPT" > $LOGFILE

for DEVICEID in $(echo $DEVICEIDS | sed "s/,/ /g")
do
#    echo "Searching output of dmesg for lines having '$DEVICEID'" >> $LOGFILE

    while IFS= read -r hidstr
    do
        #whatever with value $hidstr
#        echo "hidstr: $hidstr" >> $LOGFILE

        # Extract the hid device
        hidpos=$(echo $hidstr | awk '{print index($0, ",hidraw")}')
#        echo "hidpos: $hidpos" >> $LOGFILE

        hid=$(echo $hidstr | awk -F "," '{print $2}')
#        echo "hid: $hid" >> $LOGFILE

        # Substring field 1 with the colon as a delimiter
        hid=$(echo $hid | awk -F ":" '{print $1}')

        # Add to the associative array
        hidDevices[$hid]=$hid

        # The output of the "dmesg | grep" below is 'injected' into the loop
    done < <(dmesg | grep -i "$DEVICEID" | grep -i "hidraw" | grep -i "device")
done

# Loop though the associative array

OUTTEXT="{ \"temper2\" : { "
cnt=0
for hiddev in "${!hidDevices[@]}"
do
#    echo "hiddev: $hiddev" >> $LOGFILE

    # Use the keys to make the device name
    hid=$(echo "/dev/$hiddev")
#    echo "hid: $hid" >> $LOGFILE
    exec 5<> $hid
    echo -e '\x00\x01\x80\x33\x01\x00\x00\x00\x00\c' >&5
    # get binary response
    OUT=$(dd count=2 bs=8 <&5 2>/dev/null | xxd -p)
#    echo "Output: $OUT" >> $LOGFILE

    # DEVICE READING
    # characters 5-8 is the device temp in hex x1000
    DHEX4=${OUT:4:4}
    DDVAL=$((16#$DHEX4))
    DCTEMP=$(bc <<< "scale=2; $DDVAL/100")
#    echo "DEVICE TEMP: $DCTEMP" >> $LOGFILE

    # PROBE READING
    # characters 20-23 is the probe temp in hex x1000
    PHEX4=${OUT:20:4}
    PDVAL=$((16#$PHEX4))
    PCTEMP=$(bc <<< "scale=2; $PDVAL/100")
#    echo "PROBE TEMP: $PCTEMP" >> $LOGFILE

    # Output the temperatures in JSON format
    cma="\"device$cnt\""
    if [ $cnt -ne 0 ]; then
        cma=" , $cma"
    fi
    OUTTEXT="$OUTTEXT$cma : { \"Name\" : \"$hiddev\" , \"DeviceTemp\" : \"$DCTEMP\" , \"ProbeTemp\" : \"$PCTEMP\" }"
    cnt=$(($cnt + 1))
done

OUTTEXT="$OUTTEXT } }"
echo "$OUTTEXT" > $JSONFILE

#echo "END SCRIPT" >> $LOGFILE




