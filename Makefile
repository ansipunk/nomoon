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
	curl https://redbean.dev/redbean-latest.com > .redbean/redbean.com

build: redbean
	cat redbean.com > nomoon.com
	zip -r nomoon.com .init.lua .lua static
	chmod a+x nomoon.com

dev: build
	./nomoon.com /tmp/nomoon.test.db

test: build
	$(foreach test,$(shell ls tests),./nomoon.com -i tests/$(test);)

clean:
	rm -rf redbean.com nomoon.com
