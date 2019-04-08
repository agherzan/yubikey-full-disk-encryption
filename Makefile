install: reinstall
	install -v -b -Dm644 src/ykfde.conf "$(DESTDIR)/etc/ykfde.conf"

reinstall: ykchalresp-nfc/build/ykchalresp-nfc
	install -Dm644 src/hooks/ykfde "$(DESTDIR)/usr/lib/initcpio/hooks/ykfde"
	install -Dm644 src/install/ykfde "$(DESTDIR)/usr/lib/initcpio/install/ykfde"
	install -Dm755 ykchalresp-nfc/build/ykchalresp-nfc "$(DESTDIR)/usr/lib/initcpio/ykchalresp-nfc"
	install -Dm755 src/ykfde-suspend "$(DESTDIR)/usr/lib/ykfde-suspend/ykfde-suspend"
	install -Dm755 src/initramfs-suspend "$(DESTDIR)/usr/lib/ykfde-suspend/initramfs-suspend"
	install -Dm644 src/ykfde-suspend.service "$(DESTDIR)/usr/lib/systemd/system/ykfde-suspend.service"
	install -Dm755 src/ykfde-enroll "$(DESTDIR)/usr/bin/ykfde-enroll"
	install -Dm755 src/ykfde-format "$(DESTDIR)/usr/bin/ykfde-format"
	install -Dm755 src/ykfde-open "$(DESTDIR)/usr/bin/ykfde-open"
	install -Dm644 README.md "$(DESTDIR)/usr/share/doc/ykfde/README.md"

ykchalresp-nfc/build/ykchalresp-nfc:
	mkdir -p ykchalresp-nfc/build
	cd ykchalresp-nfc/build && cmake .. -DCMAKE_BUILD_TYPE=Release && make

test:
	./testrun.sh

all: install

clean:
	rm -rf ykchalresp-nfc/build
