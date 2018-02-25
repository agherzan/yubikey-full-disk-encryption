# Yubikey Full Disk Encryption

## Description

This project enables the ability to unlock LUKS partitions using a [Yubikey](https://www.yubico.com). It uses mkinitcpio to generate an initramfs image.

Be aware that this was only tested and intended for:
* Archlinux
* YubiKey 4

There is similar project targeting Debian/Ubuntu systems: https://github.com/cornelinux/yubikey-luks

## LUKS passphrase creation scheme

The passphrase for unlocking volumes encrypted with LUKS can be created in two ways using [YubiKey challenge-response](https://www.yubico.com/products/services-software/personalization-tools/challenge-response) feature:

* Challenge only mode (1FA)
* Challenge + password mode (2FA)

In *Challenge only mode* you have to create custom challenge (1-64 characters length) and write it to *ykfde.conf*. Keep in mind that challenge you set will be stored in cleartext inside in */etc/ykfde.conf* and the initramfs image:

```
YKFDE_CHALLENGE=12345678
```

The YubiKey response which is a 40 character length string will look like this *bd438575f4e8df965c80363f8aa6fe1debbe9ea9* and will be used as your LUKS passphrase. In this mode possession of your YubiKey is enough to unlock a LUKS encrypted volume (1FA). It allows for the easy unlocking of volumes at boot time without need for user action.

In *Challenge + password mode* you will be asked to provide a custom *password* which will be hashed using the SHA256 algorithm to achieve the maximum character length(64) for any given password. The hash will be used as the *challenge*:


```
YKFDE_CHALLENGE= password -> printf password | sha256sum | awk '{print $1}' -> 5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8
```

This password will never be stored and you will have to provide it every time you want to unlock the LUKS volume. It will be concatenated with the YubiKey response and assembled as your LUKS passphrase for a total character length of 104 (64+40).

```
CHALLENGE=5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8
RESPONSE=bd438575f4e8df965c80363f8aa6fe1debbe9ea9
LUKS PASSPHRASE=5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8bd438575f4e8df965c80363f8aa6fe1debbe9ea9
```

This strong passphrase cannot be broken by brute force. To recreate it one would need both your password (something you know) and your YubiKey (something you have) which means it's real 2FA.

Keep in mind that the above doesn't protect you from physical tampering like *Evil maid attack* and from *malware* running after you unlock and boot your system. Use security tools designed to prevent those attacks.

## LUKS partition configuration

In order to unlock the encrypted partition, this project relies on a YubiKey in challenge-response HMAC mode. The challenge is in a configuration file while the response is one (or the only) password used in the LUKS key slots.

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

You can also use the existing ykfde-enroll script, see ykfde-enroll -h for help.
```
sudo ykfde-enroll -d /dev/<device> -s <keyslot_number>
```
For unlocking an existing device on a running system, you can use ykfde-open script, see ykfde-open -h for help.

As unprivileged user using udisksctl:
```
ykfde-open -d /dev/<device>
```
As root using cryptsetup:
```
ykfde-open -d /dev/<device> -n <container_name>
```

For formatting new device, you can use ykfde-format script which is wrapper over "cryptsetup luksFormat" command.
```
ykfde-format --cipher aes-xts-plain64 --key-size 512 --hash sha256 --iter-time 5000 /dev/<device>
```

## Initramfs hooks installation and configuration

Install all the needed scripts by issuing:

```
sudo make install
```
or use makepkg on existing PKGBUILD and install it through pacman: https://github.com/agherzan/yubikey-full-disk-encryption/blob/master/PKGBUILD

Edit the /etc/ykfde.conf file.

Add the `ykfde` HOOK at the end of the definition of `HOOKS` in /etc/mkinitcpio.conf.

Regenerate initramfs:

```
sudo mkinitcpio -p linux
```

Reboot and test you configuration.

## Enable ykfde-suspend module

You can enable the ykfde-suspend module which allows for automatically locking encrypted LUKS containers and wiping keys from memory on suspend and unlocking them on resume by using luksSuspend, luksResume commands. Based on https://github.com/vianney/arch-luks-suspend

1. Edit /etc/mkinitcpio.conf and make sure the following hooks are enabled: udev, ykfde, shutdown.
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
* Added YubiKey detection (to complete the wait for YubiKey functionality of hook/ykfde script)
* Added a testrun.sh Test script to test the hook not first during boot-up ;)
* Added ykfde-suspend module
* Fixes most issues detected by shellcheck static analysis tool
* Added makepkg integration and PKGBUILD
* Hash password with sha256.
* Added ykfde-open and ykfde-enroll scripts
* Added design information in Readme
* Added udisksctl support
* Added ykfde-format script

## Security

For a security analysis of this improvement (and the idea to combine password (knowledge) with YubiKey (possession) security please see
[this very accurate analysis from Cornelinux](https://github.com/cornelinux/yubikey-luks/issues/1#issuecomment-326504799).

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
