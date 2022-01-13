install: reinstall
	install -v -b -Dm644 ../../src/ykfde.conf "$(DESTDIR)/etc/ykfde.conf"

reinstall:
	install -Dm644 ../../src/archlinux/hooks/ykfde "$(DESTDIR)/usr/lib/initcpio/hooks/ykfde"
	install -Dm644 ../../src/archlinux/install/ykfde "$(DESTDIR)/usr/lib/initcpio/install/ykfde"
	install -Dm755 ../../src/archlinux/ykfde-suspend "$(DESTDIR)/usr/lib/ykfde-suspend/ykfde-suspend"
	install -Dm755 ../../src/archlinux/initramfs-suspend "$(DESTDIR)/usr/lib/ykfde-suspend/initramfs-suspend"
	install -Dm644 ../../src/archlinux/ykfde-suspend.service "$(DESTDIR)/usr/lib/systemd/system/ykfde-suspend.service"
	install -Dm755 ../../src/ykfde-enroll "$(DESTDIR)/usr/bin/ykfde-enroll"
	install -Dm755 ../../src/ykfde-format "$(DESTDIR)/usr/bin/ykfde-format"
	install -Dm755 ../../src/ykfde-open "$(DESTDIR)/usr/bin/ykfde-open"
	install -Dm644 ../../README.md "$(DESTDIR)/usr/share/doc/ykfde/README.md"
test:
	../../src/testrun.sh

all: install
