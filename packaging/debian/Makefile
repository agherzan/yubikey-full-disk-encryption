info:
	@echo "builddeb [NO_SIGN=1]  - build deb package for Ubuntu LTS [NO_SIGN disables signing]"
	@echo "clean                 - clean build directory DEBUILD"

VERSION=0.1
SRC_DIR = ykfde-${VERSION}

debianize:
	rm -fr DEBUILD
	mkdir -p DEBUILD/${SRC_DIR}
	cp -r * DEBUILD/${SRC_DIR} || true
	cp -r ../../src/ykfde* DEBUILD/${SRC_DIR} || true
	cp -r ../../src/debian/* DEBUILD/${SRC_DIR} || true
	cp ../../README.md DEBUILD/${SRC_DIR} || true
	(cd DEBUILD; tar -zcf ykfde_${VERSION}.orig.tar.gz --exclude=${SRC_DIR}/debian  ${SRC_DIR})

builddeb:
	make debianize
ifndef NO_SIGN
	(cd DEBUILD/${SRC_DIR}; debuild)
else
	(cd DEBUILD/${SRC_DIR}; debuild -uc -us)
endif

clean:
	rm -fr DEBUILD
	
#test:
#	../src/testrun.sh
