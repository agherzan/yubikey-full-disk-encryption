install:
	install -Dm644 src/ykfde.conf "$(DESTDIR)/etc/ykfde.conf"
	install -Dm644 src/hooks/ykfde "$(DESTDIR)/usr/lib/initcpio/hooks/ykfde"
	install -Dm644 src/install/ykfde "$(DESTDIR)/usr/lib/initcpio/install/ykfde"
	install -Dm755 src/ykfde-suspend "$(DESTDIR)/usr/lib/ykfde-suspend/ykfde-suspend"
	install -Dm755 src/initramfs-suspend "$(DESTDIR)/usr/lib/ykfde-suspend/initramfs-suspend"
	install -Dm644 src/ykfde-suspend.service "$(DESTDIR)/usr/lib/systemd/system/ykfde-suspend.service"
reinstall:
	install -Dm644 src/hooks/ykfde "$(DESTDIR)/usr/lib/initcpio/hooks"
	install -Dm644 src/install/ykfde "$(DESTDIR)/usr/lib/initcpio/install"
	install -Dm755 src/ykfde-suspend "$(DESTDIR)/usr/lib/ykfde-suspend/ykfde-luks-suspend"
	install -Dm755 src/initramfs-suspend "$(DESTDIR)/usr/lib/ykfde-suspend/initramfs-suspend"
	install -Dm644 src/ykfde-suspend.service "$(DESTDIR)/usr/lib/systemd/system/ykfde-suspend.service"
test:
	./testrun.sh
