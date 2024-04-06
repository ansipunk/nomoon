.PHONY = help redbean build dev test clean

help:
	@echo ' [[ nomoon ]]'
	@echo ''
	@echo ' help    - show this text'
	@echo ' redbean - download redbean'
	@echo ' build   - build nomoon'
	@echo ' dev     - run dev build'
	@echo ' test    - run tests'
	@echo ' clean   - remove binaries'

redbean: ./redbean.com
./redbean.com:
	curl https://redbean.dev/redbean-latest.com > redbean.com

build: redbean
	cat redbean.com > nomoon.com
	zip -r nomoon.com .init.lua .lua static
	chmod a+x nomoon.com

dev: build
	./nomoon.com /tmp/nomoon.test.db '$$argon2i$$v=19$$m=65536,t=2,p=4$$FG+1x2pTq/aVYc1TNavXVACxqd2Oj2NlUr0IRalqs2hFOv6XPctXQMG9GsWyeqDr772kPy1qujiaN2tAd0T2NQ$$+qbyzPNbMdw5ISgk27bLyQrTHJXUdLVH'

test: build
	$(foreach test,$(shell ls tests),./nomoon.com -i tests/$(test);)

clean:
	rm -rf redbean.com nomoon.com
