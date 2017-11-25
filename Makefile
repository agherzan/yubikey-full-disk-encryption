install:
	install -Dm644 src/ykfde.conf "$(DESTDIR)/etc/ykfde.conf"
	install -Dm644 src/hooks/ykfde "$(DESTDIR)/usr/lib/initcpio/hooks"
	install -Dm644 src/install/ykfde "$(DESTDIR)/usr/lib/initcpio/install"
reinstall:
	install -Dm644 src/hooks/ykfde "$(DESTDIR)/usr/lib/initcpio/hooks"
	install -Dm644 src/install/ykfde "$(DESTDIR)/usr/lib/initcpio/install"
test:
	./testrun.sh
