# YubiKey Full Disk Encryption

This project leverages a [YubiKey](https://wiki.archlinux.org/index.php/Yubikey) [HMAC-SHA1 Challenge-Response](https://wiki.archlinux.org/index.php/Yubikey#Challenge-Response) mode for creating strong [LUKS](https://gitlab.com/cryptsetup/cryptsetup) encrypted volume passphrases. It can be used in intramfs stage during boot process as well as on running system.

Be aware that this was only tested and intended for:

* [Arch Linux](https://www.archlinux.org/) and its derivatiwes
* [YubiKey 4](https://www.yubico.com/product/yubikey-4-series/)

There is similar project targeting [Debian](https://www.debian.org/)/[Ubuntu](https://www.ubuntu.com/) based systems: [yubikey-luks](https://github.com/cornelinux/yubikey-luks)

# Table of contents

   * [YubiKey Full Disk Encryption](#yubikey-full-disk-encryption)
   * [Table of contents](#table-of-contents)
   * [Design](#design)
      * [Automatic mode with stored challenge (1FA)](#automatic-mode-with-stored-challenge-1fa)
      * [Manual mode with secret challenge (2FA)](#manual-mode-with-secret-challenge-2fa)
   * [Installation](#installation)
      * [Creating and installing package through pacman (recommended)](#creating-and-installing-package-through-pacman-recommended)
      * [Manual download and installation](#manual-download-and-installation)
   * [Configuration](#configuration)
      * [Configuring HMAC-SHA1 Challenge-Response slot in YubiKey](#configuring-hmac-sha1-challenge-response-slot-in-yubikey)
      * [Editing /etc/ykfde.conf file](#editing-etcykfdeconf-file)
   * [Usage](#usage)
      * [Formatting new LUKS encrypted volume using ykfde passphrase](#formatting-new-luks-encrypted-volume-using-ykfde-passphrase)
      * [Enrolling ykfde passphrase to existing LUKS encrypted volume](#enrolling-ykfde-passphrase-to-existing-luks-encrypted-volume)
      * [Unlocking LUKS encrypted volume protected by ykfde passphrase](#unlocking-luks-encrypted-volume-protected-by-ykfde-passphrase)
      * [Enabling ykfde initramfs hook](#enabling-ykfde-initramfs-hook)
      * [Enabling ykfde suspend hook](#enabling-ykfde-suspend-hook)
   * [License](#license)

# Design

The passphrase for unlocking *LUKS* encrypted volumes can be created in two ways:

## Automatic mode with stored challenge (1FA)

In *Automatic mode* you create custom *challenge* with 0-64 byte length and store it in cleartext in */etc/ykfde.conf* and inside the initramfs image.

Example *challenge*:`123456abcdef`

The *YubiKey* *response* is a *HMAC-SHA1* 40 byte length string created from your provided challenge and secret key stored inside token. It will be used as your *LUKS* encrypted volume passphrase.

Example *response* (ykfde passphrase): `bd438575f4e8df965c80363f8aa6fe1debbe9ea9`

In this mode possession of your *YubiKey* is enough to unlock a *LUKS* encrypted volume (1FA). It allows for the easy unlocking of encrypted volumes when *YubiKey* is present without need for user action.


## Manual mode with secret challenge (2FA)

In *Secret mode* you will be asked to provide a custom *challenge* every time you want to unlock your *LUKS* encrypted volume as it will never be stored anywhere on system.

Example *challenge*: `123456abcdef`

It will be hashed using the *SHA256* algorithm to achieve the maximum byte length (64) for any given *challenge*. The hash will be used as the final *challenge* provided for *YubiKey*.

Hashing function:

```
printf 123456abcdef | sha256sum | awk '{print $1}'
```

Example hashed *challenge*: `8fa0acf6233b92d2d48a30a315cd213748d48f28eaa63d7590509392316b3016`

 The *YubiKey* *response* is a *HMAC-SHA1* 40 byte length string created from your provided *challenge* and secret key stored inside token. It will be concatenated with the *challenge* and used as your *LUKS* encrypted volume passphrase for a total length of 104 (64+40) bytes.

Example response: `bd438575f4e8df965c80363f8aa6fe1debbe9ea9`

Example ykfde passphrase: `8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92bd438575f4e8df965c80363f8aa6fe1debbe9ea9`

This strong passphrase cannot be broken by brute force. To recreate it one would need both your passphrase (something you know) and your *YubiKey* (something you have) which means it works like 2FA.

Keep in mind that the above doesn't protect you from physical tampering like *evil maid attack* and from *malware* running after you unlock and boot your system. Use security tools designed to prevent those attacks.

# Installation

## Creating and installing package through pacman (recommended)

```
wget https://raw.githubusercontent.com/agherzan/yubikey-full-disk-encryption/master/PKGBUILD
makepkg -srci
```

## Manual download and installation

```
git clone https://github.com/agherzan/yubikey-full-disk-encryption.git
sudo make install
```

When doing manual installation you also need to install [yubikey-personalization](https://www.archlinux.org/packages/community/x86_64/yubikey-personalization/) and [expect](https://www.archlinux.org/packages/extra/x86_64/expect/) packages.

# Configuration


## Configuring HMAC-SHA1 Challenge-Response slot in YubiKey

First of all you need to [setup a configuration slot](https://wiki.archlinux.org/index.php/Yubikey#Setup_the_slot) for *YubiKey HMAC-SHA1 Challenge-Response* mode using a command similar to:

```
ykpersonalize -v -2 -ochal-resp -ochal-hmac -ohmac-lt64 -oserial-api-visible -ochal-btn-trig
```

Above arguments mean:

* Verbose output (`-v`)
* Use slot 2 (`-2`)
* Set Challenge-Response mode (`-ochal-resp`)
* Generate HMAC-SHA1 challenge responses (`-ochal-hmac`)
* Calculate HMAC on less than 64 bytes input (`-ohmac-lt64`)
* Allow YubiKey serial number to be read using an API call (`-oserial-api-visible`)
* Require touching YubiKey before issue response (`-ochal-btn-trig`) *(optional)*

You may instead enable *HMAC-SHA1 Challenge-Response* mode using graphical interface through [yubikey-personalization-gui](https://www.archlinux.org/packages/community/x86_64/yubikey-personalization-gui/) package.

## Editing /etc/ykfde.conf file

Open the [/etc/ykfde.conf](https://github.com/agherzan/yubikey-full-disk-encryption/blob/master/src/ykfde.conf) file and adjust it for your needs. Alternatively to setting `YKFDE_DISK_UUID` and `YKFDE_LUKS_NAME`, you can use `cryptdevice` kernel parameter. The [syntax](https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption#Configuring_the_kernel_parameters) is compatible with Arch's `encrypt` hook. After making your changes [regenerate initramfs](https://wiki.archlinux.org/index.php/Mkinitcpio#Image_creation_and_activation):

```
sudo mkinitcpio -P
```


# Usage

## Formatting new LUKS encrypted volume using ykfde passphrase

For formatting new *LUKS* encrypted volume, you can use [ykfde-format](https://github.com/agherzan/yubikey-full-disk-encryption/blob/master/src/ykfde-format) script which is wrapper over `cryptsetup luksFormat` command, see `ykfde-format -h` for help:

```
ykfde-format --cipher aes-xts-plain64 --key-size 512 --hash sha256 --iter-time 5000 /dev/<device>
```

## Enrolling ykfde passphrase to existing LUKS encrypted volume

For enrolling new ykfde passphrase to existing *LUKS* encrypted volume you can use [ykfde-enroll](https://github.com/agherzan/yubikey-full-disk-encryption/blob/master/src/ykfde-enroll) script, see `ykfde-enroll -h` for help:

```
ykfde-enroll -d /dev/<device> -s <keyslot_number>
```

## Unlocking LUKS encrypted volume protected by ykfde passphrase

For unlocking *LUKS* encrypted volume on a running system, you can use [ykfde-open](https://github.com/agherzan/yubikey-full-disk-encryption/blob/master/src/ykfde-open) script, see `ykfde-open -h` for help.

As unprivileged user using udisksctl (recommended):

```
ykfde-open -d /dev/<device>
```

As root using cryptsetup (when udisks is not available):

```
ykfde-open -d /dev/<device> -n <container_name>
```

## Enabling ykfde initramfs hook

Edit `/etc/mkinitcpio.conf` and add the `ykfde` hook before or instead of `encrypt` hook as provided in [example](https://wiki.archlinux.org/index.php/Dm-crypt/System_configuration#Examples). After making your changes [regenerate initramfs](https://wiki.archlinux.org/index.php/Mkinitcpio#Image_creation_and_activation):

```
sudo mkinitcpio -P
```

Reboot and test your configuration.

## Enabling ykfde suspend hook

You can enable the `ykfde-suspend` hook which allows for automatically locking encrypted *LUKS* volumes and wiping keys from memory on suspend and unlocking them on resume by using `cryptsetup luksSuspend` and `cryptsetup luksResume` commands. **Warning: RAM storage stays unencrypted in that case.**

Edit `/etc/mkinitcpio.conf` and make sure the following hooks are enabled: `udev`, `ykfde` and `shutdown`. After making your changes [regenerate initramfs](https://wiki.archlinux.org/index.php/Mkinitcpio#Image_creation_and_activation):

```
sudo mkinitcpio -P
```

Enable related systemd service:

```
systemctl enable ykfde-suspend.service
```

Reboot and test your configuration.

# License

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
