# HASS_TEMPer2
Home Assistant shell script & configuration suitable for many TEMPer2 USB devices.

Intended for users of HASSOS / Supervised version of Home Assistant. For others, YMMV.

Tested on 
  - Raspberry Pi 3b+
  - Home Assistant 2023.8.3
  - Supervisor 2023.08.1
  - Operating System 10.5
  - Frontend 20230802.1 - latest

## Recipe
### Edit the device IDs in the script
1. In a text editor, open config/sh/temper2.sh
2. Swap out the 'DEVICEIDS=1a86:e025,3553:a001' with a comma separated list of VendorID:ProductID of your TEMPer2 devices, and save.

### Add udev rule for the device
1. Shut down Home Assistant.
2. Extract the SD Card & plug it in another computer.
3. On the Overlay partition, create file /etc/udev/rules.d/99-temper-rules
   In a text editor populate the file as follows, swapping the VendorID:ProductID of your TEMPer2 devices, and save. Use one line per VendorID & Product ID combination.
```
     SUBSYSTEMS==“usb”, ACTION==“add”, ATTRS{idVendor}==“1a86”, ATTRS{idProduct}==“e025”, MODE=“666”
     SUBSYSTEMS==“usb”, ACTION==“add”, ATTRS{idVendor}==“3553”, ATTRS{idProduct}==“a001”, MODE=“666”
```
4. Safely eject from the other computer. Replace in the HASS machine and restart.

### Configure HASS
The addon, 'Samba share' is helpful for the file placement:
1. Create folder '/config/sh' and place the script 'temper2.sh' within.
2. Create folder '/config/files' to receive the output file of the script.
3. Create folder '/config/packages' and place the package file, 'temper2.yaml' within.
4. In '/config/configuration.yaml', allow external files [^1], and packages [^2]. E.g.
```
   homeassistant:
     # We are using packages
     packages: !include_dir_named packages
     # We are sourcing data from non standard directories
     allowlist_external_dirs:
       - /config/files`
```

### Try it
1. Make a hard restart of HASS.
2. When restarted, look for sensors:
   - sensor.temper2_stick_1_device
   - sensor.temper2_stick_1_probe
   - sensor.temper2_stick_2_device
   - sensor.temper2_stick_2_probe

### Temperature Corrections
These devices are certainly not accurate to two decimal places! The corrections to the values sent by the device are in the 'value_template' lines of the packages/temper2.yaml file, after the '|float'

[^1]: See: [allowlist_external_dirs](https://www.home-assistant.io/docs/configuration/basic/). 
[^2]: See: [packages](https://www.home-assistant.io/docs/configuration/packages/).

