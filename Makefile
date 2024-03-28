.PHONY = help deps build clean

help:
	@echo ' [[ nomoon ]]'
	@echo ''
	@echo ' help    - show this text'
	@echo ' redbean - download redbean'
	@echo ' build   - build nomoon'
	@echo ' clean   - remove binaries'

redbean: ./redbean.com
./redbean.com:
	curl https://redbean.dev/redbean-latest.com > .redbean/redbean.com

build: redbean
	cat redbean.com > nomoon.com
	zip -r nomoon.com .init.lua .lua
	chmod a+x nomoon.com

test: build
	true $(foreach test,$(shell ls test),&& ./nomoon.com -i test/$(test) )

clean:
	rm -rf redbean.com nomoon.com
