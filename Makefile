.PHONY = help deps build clean

help:
	@echo ' [[ nomoon ]]'
	@echo ''
	@echo ' help  - show this text'
	@echo ' deps  - download redbean'
	@echo ' build - build nomoon'
	@echo ' clean - remove deps'

deps: .redbean/redbean.com
.redbean/redbean.com:
	mkdir -p .redbean
	curl https://redbean.dev/redbean-latest.com > .redbean/redbean.com

build: deps
	cat .redbean/redbean.com > nomoon.com
	ls .lua | grep -v .test.lua | sed s/^/.lua\\// | xargs zip nomoon.com .init.lua
	chmod a+x nomoon.com

test: build
	true $(foreach test,$(shell ls .lua | grep .test.lua),&& ./nomoon.com -i .lua/$(test) )

clean:
	rm -rf .lua .redbean nomoon.com
