pkgname=yubikey-full-disk-encryption-git
_pkgname=yubikey-full-disk-encryption
pkgver=r136.4d8ba6a
pkgrel=1
pkgdesc='Use YubiKey to unlock a LUKS partition'
arch=('any')
url='https://github.com/agherzan/yubikey-full-disk-encryption'
license=('Apache')
depends=('yubikey-personalization' 'cryptsetup' 'udisks2' 'expect')
optdepends=('ykchalresp-nfc: NFC support' 'netcat: SSH support' 'mkinitcpio-dropbear: SSH support')
makedepends=('git')
backup=('etc/ykfde.conf')
source=('git+https://github.com/agherzan/yubikey-full-disk-encryption.git')
sha256sums=('SKIP')

pkgver() {
  cd "${_pkgname}"
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
  cd "${_pkgname}"
  make DESTDIR="${pkgdir}" install
}
