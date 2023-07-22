#!/bin/bash
# 
# By: Sheila S. Wilson
# Get the temperature from a USB Temper Thermometer
#
# Original from: https://funprojects.blog/2021/05/02/temper-usb-temperature-sensor
#   Archived as: https://archive.fo/nrR0r
#   
# Adapted for Home Assistant on HASSOS by Steven Tierney
#   
#   find the HID device from the kernel msg via dmesg
#   parse the line get HID device
JSONFILE=files/temper2.json
LOGFILE=files/temper2.log

hidstr=$(dmesg 2>/dev/null | grep -E  -m 1 'Device.*1a86:e025')
if [ -z "$hidstr" ]; then
  echo "No TEMPer device found. Are you running as root? Is the device allowed in UDEV rules?" > $LOGFILE
else 
  # find the postion of the "hidraw" string
  echo "hidstr:" > $LOGFILE
  echo $hidstr > $LOGFILE
#  hidpos=$(echo $hidstr | awk '{print match($0, ",hidraw")}')
#  echo "hidpos: $hidpos" >> $LOGFILE
  hidpos=$(echo $hidstr | awk '{print index($0, ",hidraw")}')
  echo "hidpos: $hidpos" >> $LOGFILE

  if [ -z "$hidpos" ]; then
    echo "No TEMPer device found" >> $ERRFILE
  else
    # Get the hidraw device id from the string
    # E.g. hidstr='[ 3.672655] hid-generic 0003:1A86:E025.0002: input,hidraw1: USB HID v1.10 Device [HID 1a86:e025] on usb-3f980000.usb-1.2/input1'
    # Substring field 2 with the comma as a delimiter
    hid=$(echo $hidstr | awk -F "," '{print $2}')
    # echo "hid: $hid" >> $LOGFILE
    # Substring field 1 with the colon as a delimiter
    hid=$(echo $hid | awk -F ":" '{print $1}')
	hid="/dev/$hid"
    echo "hid: $hid" >> $LOGFILE
    # Set variable
    exec 5<> $hid
    # send out query msg
    echo -e '\x00\x01\x80\x33\x01\x00\x00\x00\x00\c' >&5
    # get binary response
    OUT=$(dd count=2 bs=8 <&5 2>/dev/null | xxd -p)
    echo "OUT: $OUT" >> $LOGFILE

    # DEVICE READING
    # characters 5-8 is the device temp in hex x1000
    DHEX4=${OUT:4:4}
    DDVAL=$((16#$DHEX4))
    DCTEMP=$(bc <<< "scale=2; $DDVAL/100")
    echo "DEVICE TEMP: $DCTEMP" >> $LOGFILE

    # PROBE READING
    # characters 20-23 is the probe temp in hex x1000
    PHEX4=${OUT:20:4}
    PDVAL=$((16#$PHEX4))
    PCTEMP=$(bc <<< "scale=2; $PDVAL/100")
    echo "PROBE TEMP: $PCTEMP" >> $LOGFILE

    # Output the temperatures in JSON format
    echo "{ \"Device\" : \"$DCTEMP\" , \"Probe\" : \"$PCTEMP\" }" > $JSONFILE
  fi 
fi

