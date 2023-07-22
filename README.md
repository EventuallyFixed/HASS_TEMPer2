# HASS_TEMPer2
Home Assistant configuration for the TEMPer2 USB device: `1a86:e025`

Intended for users of HASSOS / Supervised version of Home Assistant.

Tested on 
  - Raspberry Pi 3b+
  - Home Assistant 2023.7.3
  - Supervisor 2023.07.1
  - Operating System 10.3
  - Frontend 20230705.1 - latest

## Recipe

### Add udev rule for the device
1. Shut down Home Assistant.
2. Extract the SD Card & plug it in another computer.
3. On the Overlay partition, create file /etc/udev/rules.d/99-temper-rules
   Populate the file as follows, and save:
```
     SUBSYSTEMS==“usb”, ACTION==“add”, ATTRS{idVendor}==“1a86”, ATTRS{idProduct}==“e025”, MODE=“666”
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
   - sensor.temper2_device
   - sensor.temper2_probe

[^1]: See: [allowlist_external_dirs](https://www.home-assistant.io/docs/configuration/basic/). 
[^2]: See: [packages](https://www.home-assistant.io/docs/configuration/packages/).

