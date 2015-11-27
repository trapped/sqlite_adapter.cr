.PHONY: all

CRYSTAL ?= crystal

all: test

test:
	$(CRYSTAL) spec
	script/setup-test-db.sh
	bin/test
	rm -f data.db
