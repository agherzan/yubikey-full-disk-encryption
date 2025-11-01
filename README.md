# YubiKey Full Disk Encryption

This project leverages a [YubiKey](https://wiki.archlinux.org/index.php/Yubikey) [HMAC-SHA1 Challenge-Response](https://wiki.archlinux.org/index.php/Yubikey#Challenge-Response) mode for creating strong [LUKS](https://gitlab.com/cryptsetup/cryptsetup) encrypted volume passphrases. It can be used in intramfs stage during boot process as well as on running system.

Be aware that this was only tested and intended for:

* [Arch Linux](https://www.archlinux.org/) and its derivatives
* [YubiKey (version 4 or later)](https://www.yubico.com/products/yubikey-5-overview/)

There is similar project targeting [Debian](https://www.debian.org/)/[Ubuntu](https://www.ubuntu.com/) based systems: [yubikey-luks](https://github.com/cornelinux/yubikey-luks)

Table of Contents
=================

   * [YubiKey Full Disk Encryption](#yubikey-full-disk-encryption)
   * [Table of Contents](#table-of-contents)
   * [Design](#design)
      * [Automatic mode with stored challenge (1FA)](#automatic-mode-with-stored-challenge-1fa)
      * [Manual mode with secret challenge (2FA)](#manual-mode-with-secret-challenge-2fa)
   * [Install](#install)
      * [From Arch Linux official repository](#from-arch-linux-official-repository)
      * [From Github using 'makepkg'](#from-github-using-makepkg)
      * [From Github using 'make'](#from-github-using-make)
   * [Configure](#configure)
      * [Configure HMAC-SHA1 Challenge-Response slot in YubiKey](#configure-hmac-sha1-challenge-response-slot-in-yubikey)
      * [Edit /etc/ykfde.conf file](#edit-etcykfdeconf-file)
   * [Usage](#usage)
      * [Format new LUKS encrypted volume using ykfde passphrase](#format-new-luks-encrypted-volume-using-ykfde-passphrase)
      * [Enroll ykfde passphrase to existing LUKS encrypted volume](#enroll-ykfde-passphrase-to-existing-luks-encrypted-volume)
      * [Enroll new ykfde passphrase to existing LUKS encrypted volume protected by old ykfde passphrase](#enroll-new-ykfde-passphrase-to-existing-luks-encrypted-volume-protected-by-old-ykfde-passphrase)
      * [Unlock LUKS encrypted volume protected by ykfde passphrase](#unlock-luks-encrypted-volume-protected-by-ykfde-passphrase)
      * [Kill ykfde passphrase for existing LUKS encrypted volume](#kill-ykfde-passphrase-for-existing-luks-encrypted-volume)
      * [Enable ykfde initramfs hook](#enable-ykfde-initramfs-hook)
      * [Enable NFC support in ykfde initramfs hook (experimental)](#enable-nfc-support-in-ykfde-initramfs-hook-experimental)
      * [Enable ykfde suspend service (experimental)](#enable-ykfde-suspend-service-experimental)
      * [Use ykfde with encryptssh](#use-ykfde-with-encryptssh)
   * [License](#license)

# Design

The passphrase for unlocking *LUKS* encrypted volumes can be created in two ways:

## Automatic mode with stored challenge (1FA)

In *Automatic mode* you create custom *challenge* with 0-64 byte length and store it in cleartext in */etc/ykfde.conf* and inside the initramfs image.

Example *challenge*:`123456abcdef`

The *YubiKey* *response* is a *HMAC-SHA1* 40 byte length string created from your provided challenge and 20 byte length secret key stored inside the token. It will be used as your *LUKS* encrypted volume passphrase.

Example *response* (ykfde passphrase): `bd438575f4e8df965c80363f8aa6fe1debbe9ea9`

In this mode possession of your *YubiKey* is enough to unlock a *LUKS* encrypted volume (1FA). It allows for the easy unlocking of encrypted volumes when *YubiKey* is present without need for user action.


## Manual mode with secret challenge (2FA)

In *Secret mode* you will be asked to provide a custom *challenge* every time you want to unlock your *LUKS* encrypted volume as it will never be stored anywhere on system.

Example *challenge*: `123456abcdef`

It will be hashed using the *SHA256* algorithm to achieve constant byte length (64) for any given *challenge*. It's also the maximum length that *YubiKey* can take as input. The hash will be used as the final *challenge* provided for *YubiKey*.

Hashing function:

```bash
printf 123456abcdef | sha256sum | awk '{print $1}'
```

Example hashed *challenge*: `8fa0acf6233b92d2d48a30a315cd213748d48f28eaa63d7590509392316b3016`

 The *YubiKey* *response* is a *HMAC-SHA1* 40 byte length string created from your provided *challenge* and 20 byte length secret key stored inside the token. It will be concatenated with the *challenge* and used as your *LUKS* encrypted volume passphrase for a total length of 104 (64+40) bytes.

Example response: `bd438575f4e8df965c80363f8aa6fe1debbe9ea9`

Example ykfde passphrase: `8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92bd438575f4e8df965c80363f8aa6fe1debbe9ea9`

This strong passphrase cannot be broken by brute force. To recreate it one would need both your passphrase (something you know) and your *YubiKey* (something you have) which means it works like 2FA.

Keep in mind that the above doesn't protect you from physical tampering like *evil maid attack* and from *malware* running after you unlock and boot your system. Use security tools designed to prevent those attacks.

# Install

## From Arch Linux official repository

The easiest way is to install package from [official Arch Linux repository](https://www.archlinux.org/packages/community/any/yubikey-full-disk-encryption/).

```bash
sudo pacman -Syu yubikey-full-disk-encryption
```

## From Github using 'makepkg'

```bash
wget https://raw.githubusercontent.com/agherzan/yubikey-full-disk-encryption/master/PKGBUILD
makepkg -srci
```

## From Github using 'make'

```bash
git clone https://github.com/agherzan/yubikey-full-disk-encryption.git
cd yubikey-full-disk-encryption
sudo make install
```

When installing by using `make` you also need to install [yubikey-personalization](https://www.archlinux.org/packages/community/x86_64/yubikey-personalization/) and [expect](https://www.archlinux.org/packages/extra/x86_64/expect/) packages.

# Configure


## Configure HMAC-SHA1 Challenge-Response slot in YubiKey

First of all you need to [setup a configuration slot](https://wiki.archlinux.org/index.php/Yubikey#Setup_the_slot) for *YubiKey HMAC-SHA1 Challenge-Response* mode using a command similar to:

```bash
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

This command will enable *HMAC-SHA1 Challenge-Response* mode on a chosen slot and write random 20 byte length secret key to your YubiKey which will be used for creating ykfde passphrases.

**Warning: choosing YubiKey slot already configured for *HMAC-SHA1 Challenge-Response* mode will overwrite secret key with the new one which means ykfde passphrases created with the old key will be unrecoverable.**

You may instead enable *HMAC-SHA1 Challenge-Response* mode using graphical interface through [yubikey-personalization-gui](https://www.archlinux.org/packages/community/x86_64/yubikey-personalization-gui/) package. It allows for customization of the secret key, creation of secret key backup and writing the same secret key to multiple YubiKeys which allows for using them interchangeably for creating same ykfde passphrases.

## Edit /etc/ykfde.conf file

Open the [/etc/ykfde.conf](https://github.com/agherzan/yubikey-full-disk-encryption/blob/master/src/ykfde.conf) file and adjust it for your needs. Alternatively to setting `YKFDE_DISK_UUID` and `YKFDE_LUKS_NAME`, you can use `cryptdevice` kernel parameter. The [syntax](https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption#Configuring_the_kernel_parameters) is compatible with Arch's `encrypt` hook. After making your changes [regenerate initramfs](https://wiki.archlinux.org/index.php/Mkinitcpio#Image_creation_and_activation):

```bash
sudo mkinitcpio -P
```


# Usage
You can list existing LUKS key slots with `cryptsetup luksDump /dev/<device>`.

## Format new LUKS encrypted volume using ykfde passphrase

To format new *LUKS* encrypted volume, you can use [ykfde-format](https://github.com/agherzan/yubikey-full-disk-encryption/blob/master/src/ykfde-format) script which is wrapper over `cryptsetup luksFormat` command:

```bash
ykfde-format --cipher aes-xts-plain64 --key-size 512 --hash sha512 /dev/<device>
```

## Enroll ykfde passphrase to existing LUKS encrypted volume

To enroll new ykfde passphrase to existing *LUKS* encrypted volume you can use [ykfde-enroll](https://github.com/agherzan/yubikey-full-disk-encryption/blob/master/src/ykfde-enroll) script, see `ykfde-enroll -h` for help:

```bash
ykfde-enroll -d /dev/<device> -s <keyslot_number>
```

**Warning: having a weaker non-ykfde passphrase(s) on the same *LUKS* encrypted volume undermines the ykfde passphrase value as potential attacker will always try to break the weaker passphrase. Make sure the other  non-ykfde passphrases are similarly strong or remove them.**

## Enroll new ykfde passphrase to existing LUKS encrypted volume protected by old ykfde passphrase

To enroll new ykfde passphrase to existing *LUKS* encrypted volume protected by old ykfde passphrase you can use [ykfde-enroll](https://github.com/agherzan/yubikey-full-disk-encryption/blob/master/src/ykfde-enroll) script, see `ykfde-enroll -h` for help:

```bash
ykfde-enroll -d /dev/<device> -s <keyslot_number> -o
```

## Unlock LUKS encrypted volume protected by ykfde passphrase

To unlock *LUKS* encrypted volume on a running system, you can use [ykfde-open](https://github.com/agherzan/yubikey-full-disk-encryption/blob/master/src/ykfde-open) script, see `ykfde-open -h` for help.

As unprivileged user using udisksctl (recommended):

```bash
ykfde-open -d /dev/<device>
```

As root using cryptsetup (when [udisks2](https://www.archlinux.org/packages/extra/x86_64/udisks2/) or [expect](https://www.archlinux.org/packages/extra/x86_64/expect/) aren't available):

```bash
ykfde-open -d /dev/<device> -n <volume_name>
```

To print only the ykfde passphrase to the console without unlocking any volumes:

```bash
ykfde-open -p
```

To test only a passphrase for a specific key slot:

```bash
ykfde-open -d /dev/<device> -s <keyslot_number> -t
```

To use optional parameters, example, use an external luks header:

```bash
ykfde-open -d /dev/<device> -- --header /mnt/luks-header.img
```

## Kill ykfde passphrase for existing LUKS encrypted volume

To kill a ykfde passphrase for existing *LUKS* encrypted volume you can use [ykfde-enroll](https://github.com/agherzan/yubikey-full-disk-encryption/blob/master/src/ykfde-enroll) script, see `ykfde-enroll -h` for help:

```bash
ykfde-enroll -d /dev/<device> -s <keyslot_number> -k
```

## Enable ykfde initramfs hook

**Warning: It's recommended to have already working [encrypted system setup](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system) with `encrypt` hook and non-ykfde passphrase before starting to use `ykfde` hook with ykfde passphrase to avoid potential misconfigurations.**

Edit `/etc/mkinitcpio.conf` and add the `ykfde` hook before or instead of `encrypt` hook as provided in [example](https://wiki.archlinux.org/index.php/Dm-crypt/System_configuration#Examples). Adding `ykfde` hook before `encrypt` hook will allow for a safe fallback in case of ykfde misconfiguration. You can remove `encrypt` hook later when you confim that everything is working correctly. After making your changes [regenerate initramfs](https://wiki.archlinux.org/index.php/Mkinitcpio#Image_creation_and_activation):

```bash
sudo mkinitcpio -P
```

Reboot and test your configuration.

## Enable NFC support in ykfde initramfs hook (experimental)

**Warning: Currently NFC support is implemented only in initramfs hook. All ykfde manipulations on booted system have to be done through USB.**

NFC support is provided through [libnfc](https://www.archlinux.org/packages/community/x86_64/libnfc/) and [ykchalresp-nfc](https://aur.archlinux.org/packages/ykchalresp-nfc/) tools. Make sure you have both packages installed. Edit `/etc/ykfde.conf` and uncomment `YKFDE_NFC="1"`setting. After making your changes [regenerate initramfs](https://wiki.archlinux.org/index.php/Mkinitcpio#Image_creation_and_activation):

```bash
sudo mkinitcpio -P
```

Reboot and test your configuration.

## Enable ykfde suspend service (experimental)

You can enable the `ykfde-suspend` service which allows for automatically locking encrypted *LUKS* volumes and wiping keys from memory on suspend and unlocking them on resume by using `cryptsetup luksSuspend` and `cryptsetup luksResume` commands.

**Warning: RAM storage stays unencrypted in that case.**

Edit `/etc/mkinitcpio.conf` and add `shutdown` hook as the last in `HOOKS` array. After making your changes [regenerate initramfs](https://wiki.archlinux.org/index.php/Mkinitcpio#Image_creation_and_activation):

```bash
sudo mkinitcpio -P
```

Enable related systemd service:

```bash
systemctl enable ykfde-suspend.service
```

Reboot and test your configuration.

## Use ykfde with encryptssh

You can configure ykfde to skip its password-fallback prompt. This allows the boot process to proceed to the next hook in the sequence (e.g., `encryptssh`) after the YubiKey polling loop finishes without a key being presented.

Here's how you do it with encryptssh:

* Follow the installation guide for [encryptssh](https://wiki.archlinux.org/title/Dm-crypt/Specialties#Busybox_based_initramfs_\(built_with_mkinitcpio\))
* Edit `/etc/mkinitcpio.conf` and add `ykfde` **before** `encryptssh` in the `HOOKS` array.
* Edit `/etc/ykfde.conf` and uncomment `YKFDE_SKIP_PASSWORD_PROMPT="1"`.
* Regenerate the initramfs
  ```bash
  sudo mkinitcpio -P
  ```

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
