# Yubikey Full Disk Encryption

## Description

This project enables unlocking of LUKS partitions using an [Yubikey](https://www.yubico.com). It uses initramfs to do this and mkinitcpio to generate it (the initramfs).

Be aware that this was only tested and intended for:
* Archlinux
* YubiKey 4

## LUKS partition configuration

In order to unlock the encrypted partition, this project relies on a yubikey in challenge-response HMAC mode. The challenge is in a configuration file while the response is one (or the only) password used in the LUKS key slots.

First of all we need to set a configuration slot in challenge-response HMAC mode using a command similar to:

```
ykpersonalize -v -1 -ochal-resp -ochal-hmac -ohmac-lt64 -ochal-btn-trig -oserial-api-visible
```

Make sure you customize the above line with the correct slot you want to set. I use `-ochal-btn-trig` to force touching the device before releasing the response.

Set the challenge...

```
read -s challenge
```

... and get the response:

```
ykchalresp "$challenge" | tr -d '\n'
```

Use the response as a new key for your LUKS partition:

```
cryptsetup luksAddKey /dev/<device>
```

You can also use existing ykfde-enroll script, see ykfde-enroll -h for help.
```
sudo ykfde-enroll -d /dev/<device> -s <keyslot_number>
```
For unlocking existing device on running system you can use ykfde-open script, see ykfde-open -h for help
```
sudo ykfde-open -d /dev/<device> -n <container_name>
```

## Initramfs hooks instalation and configuration

Install all the needed scripts by issuing:

```
sudo make install
```

Edit the /etc/ykfde.conf file.

Add the `ykfde` HOOK at the end of the definition of `HOOKS` in /etc/mkinitcpio.conf.

Regenerate initramfs:

```
sudo mkinitcpio -p linux
```

Reboot and test you configuration.

## Enable ykfde-suspend module

You can enable ykfde-suspend module which allows for automatically locking encrypted LUKS containers and wiping keys from memory on suspend and unlocking them on resume by using luksSuspend, luksResume commands. Based on https://github.com/vianney/arch-luks-suspend

1. Edit /etc/mkinitcpio.conf and make sure the following hooks are enabled:udev, shutdown, suspend.
2. Enable related systemd service:

```
systemctl enable ykfde-suspend.service
```

## Improvements

* Added DBG mode (turned on via etc/ykfde.conf if things don't work like they should and you would like to *exactly* understand what is going on ;))
* Added error codes + messages and added few more sanity checks (hook/ykfde)
* Added Documentation (to ykfde.conf and to hook/ykfde)
* Added Parameters (see ykfde.conf - e.g. slot, parameterized the sleep 5, because I don't need it ... ;) 
* Added Possibility to combine Password with Challenge-Response
* Made the hook/ykfde script overall more robust against typos, less error prone
* Added YubiKey detection (to complete the wait for yubiKey functionality of hook/ykfde script)
* Added a testrun.sh Test script to test the hook not first during boot-up ;)
* Added ykfde-suspend module
* Fixes most issues detected by shellcheck static analysis tool
* Adds makepkg integration and PKGBUILD
* Hash password with sha256.
* Adds ykfde-open and ykfde-enroll scripts

## Security

For a security analysis of this improvement (and the idea to combine password (knowledge) with YubiKey (possession) security please see
[this very acurate analisis from Cornelinux](https://github.com/cornelinux/yubikey-luks/issues/1#issuecomment-326504799).

## License

Copyright 2017 Andrei Gherzan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
