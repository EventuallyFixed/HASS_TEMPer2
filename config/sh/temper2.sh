#!/bin/bash
#
# File outputs
JSONFILE=/config/files/temper2.json
LOGFILE=/config/files/temper2.log
# Comma separated list of USB Device IDs
DEVICEIDS=1a86:e025,3553:a001
# Array of hid devices
HIDDEVICES=()

# echo "BEGIN SCRIPT" > $LOGFILE

# Get the possible hid devices from /sys/class/hidraw
HIDDIRS=$(find /sys/class/hidraw/*)
for HIDDIR in $HIDDIRS
do
    # Form the uevent path
    UEVENT_FILE=$(echo "$HIDDIR/device/uevent")

    for DEVICEID in $(echo "$DEVICEIDS" | sed "s/,/\n/g")
    do
        DEVICE_VENDOR=$(echo $DEVICEID | cut -d':' -f1)
        DEVICE_PRODUCT=$(echo $DEVICEID | cut -d':' -f2)

        IS_TEMPER=$(grep -i "HID_ID" $UEVENT_FILE | grep -i $DEVICE_VENDOR | grep -i $DEVICE_PRODUCT)

        if [ ! -z "$IS_TEMPER" ]; then
            INPUT_STR=$(grep -i "HID_PHYS" $UEVENT_FILE | cut -d'/' -f2)

            # Not null so it's a TEMPer2 device
            if [ "$INPUT_STR" == "input1" ]; then
                # Get the HID device from the end of the directory string
                HIDDEV=$(echo "$HIDDIR" | cut -d'/' -f5)

                # Add to the associative array with value as /dev/$HIDDEV
                HIDDEVICES[${#HIDDEVICES[@]}]="$HIDDEV"

                # Echo out the result
                # echo "HIDDEVICE: $HIDDEV" >> $LOGFILE
            fi
        fi
    done
done 

# Loop through the devices array & get the outputs
OUTTEXT="{ \"temper2\" : [ "
CNT=0
for HIDDEV in "${HIDDEVICES[@]}"
do
    # echo "HID KEY: $CNT" >> $LOGFILE
    # echo "HID DEV: $HIDDEV" >> $LOGFILE
    HID="/dev/$HIDDEV"
    # echo "HID FOUND: $HID" >> $LOGFILE
    exec 5<> $HID
    echo -e '\x00\x01\x80\x33\x01\x00\x00\x00\x00\c' >&5
    # get binary response
    OUT=$(dd count=2 bs=8 <&5 2>/dev/null | xxd -p)
    # echo "Output: $OUT" >> $LOGFILE

    # DEVICE READING
    # characters 5-8 is the device temp in hex x1000
    DHEX4=${OUT:4:4}
    DDVAL=$((16#$DHEX4))
    DCTEMP=$(bc <<< "scale=2; $DDVAL/100")
    # echo "DEVICE TEMP: $DCTEMP" >> $LOGFILE

    # PROBE READING
    # characters 20-23 is the probe temp in hex x1000
    PHEX4=${OUT:20:4}
    PDVAL=$((16#$PHEX4))
    PCTEMP=$(bc <<< "scale=2; $PDVAL/100")
    # echo "PROBE TEMP: $PCTEMP" >> $LOGFILE

    # Output the temperatures in JSON format
    if [ $CNT -ne 0 ]; then
        CMA=" , "
    fi
    OUTTEXT="$OUTTEXT$CMA{ \"Name\" : \"$HIDDEV\" , \"DeviceTemp\" : \"$DCTEMP\" , \"ProbeTemp\" : \"$PCTEMP\" }"
    let CNT++
done

OUTTEXT="$OUTTEXT ] }"
echo "$OUTTEXT" > $JSONFILE

# echo "END SCRIPT" >> $LOGFILE


