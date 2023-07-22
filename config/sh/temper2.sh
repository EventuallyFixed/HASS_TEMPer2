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
ERRFILE=files/temper2_err.txt
JSONFILE=files/temper2.json

hidstr=$(dmesg 2>/dev/null | grep -E  -m 1 'Device.*1a86:e025')
if [ -z "$hidstr" ]; then
  echo "No TEMPer device found. Are you running as root? Is the device allowed in UDEV rules?" > $ERRFILE
else 
  # find the postion of the "hidraw" string
  hidpos=$(echo $hidstr | awk '{print match($0, ",hidraw")}')

  if [ -z "$hidpos" ]; then
    echo "No TEMPer device found" >> $ERRFILE
  else
    # Get the hidraw device id from the string
    # It is extracted as a substring of the hidstr
    # For HASS we must add two to the position
    hidpos=$(($hidpos + 2))
    hid=$(echo "/dev/${hidstr:hidpos:7}")
    # Set variable
    exec 5<> $hid
    # send out query msg
    echo -e '\x00\x01\x80\x33\x01\x00\x00\x00\x00\c' >&5
    # get binary response
    OUT=$(dd count=2 bs=8 <&5 2>/dev/null | xxd -p)

    # DEVICE READING
    # characters 5-8 is the device temp in hex x1000
    DHEX4=${OUT:4:4}
    DDVAL=$((16#$DHEX4))
    DCTEMP=$(bc <<< "scale=2; $DDVAL/100")

    # PROBE READING
    # characters 20-23 is the probe temp in hex x1000
    PHEX4=${OUT:20:4}
    PDVAL=$((16#$PHEX4))
    PCTEMP=$(bc <<< "scale=2; $PDVAL/100")

    # Output the temperatures in JSON format
    echo "{ \"Device\" : \"$DCTEMP\" , \"Probe\" : \"$PCTEMP\" }" > $JSONFILE
  fi 
fi

