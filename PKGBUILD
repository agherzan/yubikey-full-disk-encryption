pkgname=yubikey-full-disk-encryption
pkgver=r82.a2843e1
pkgrel=1
pkgdesc='Use YubiKey to unlock a LUKS partition'
arch=('any')
url='https://github.com/agherzan/yubikey-full-disk-encryption'
license=('GPL')
depends=('yubikey-personalization' 'cryptsetup' 'udisks2' 'expect')
makedepends=('git')
backup=('etc/ykfde.conf')
source=('git+https://github.com/agherzan/yubikey-full-disk-encryption.git')
sha256sums=('SKIP')

pkgver() {
  cd "${pkgname}"
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
  cd "${pkgname}"
  make DESTDIR="${pkgdir}" install
}
