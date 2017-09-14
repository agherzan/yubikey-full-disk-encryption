install:
	cp src/ykfde.conf /etc/ykfde.conf
	cp src/hooks/ykfde /usr/lib/initcpio/hooks
	cp src/install/ykfde /usr/lib/initcpio/install
reinstall:
	cp src/hooks/ykfde /usr/lib/initcpio/hooks
	cp src/install/ykfde /usr/lib/initcpio/install
test:
	./testrun.sh
