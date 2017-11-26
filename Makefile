install:
	cp src/ykfde.conf /etc/ykfde.conf
	cp src/hooks/ykfde /usr/lib/initcpio/hooks
	cp src/install/ykfde /usr/lib/initcpio/install
	install -Dm755 arch-luks-suspend "$(DESTDIR)/usr/lib/ykfde-suspend/ykfde-luks-suspend"
	install -Dm755 initramfs-suspend "$(DESTDIR)/usr/lib/ykfde-suspend/initramfs-suspend"
	install -Dm644 systemd-suspend.service "$(DESTDIR)/etc/systemd/system/ykfde-suspend.service"
reinstall:
	cp src/hooks/ykfde /usr/lib/initcpio/hooks
	cp src/install/ykfde /usr/lib/initcpio/install
        install -Dm755 arch-luks-suspend "$(DESTDIR)/usr/lib/ykfde-suspend/ykfde-luks-suspend"
        install -Dm755 initramfs-suspend "$(DESTDIR)/usr/lib/ykfde-suspend/initramfs-suspend"
        install -Dm644 systemd-suspend.service "$(DESTDIR)/etc/systemd/system/ykfde-suspend.service"
test:
	./testrun.sh
