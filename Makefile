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
	zip -r nomoon.com .init.lua .lua
	chmod a+x nomoon.com

test: build
	@./nomoon.com -i .lua/markup.test.lua
	@./nomoon.com -i .lua/sqlite.test.lua

clean:
	rm -rf .lua .redbean nomoon.com
