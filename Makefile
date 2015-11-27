.PHONY: all

CRYSTAL ?= crystal

all: test

test:
	script/setup-test-db.sh
	$(CRYSTAL) spec
	bin/test
	rm -f data.db
