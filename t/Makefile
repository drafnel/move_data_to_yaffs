
SHELL_PATH ?= /bin/sh

SHELL = $(SHELL_PATH)

DEFAULT_TEST_TARGET ?= test

T = $(sort $(wildcard t[0-9][0-9][0-9][0-9]-*.sh))

all: $(DEFAULT_TEST_TARGET)

test: $(T)

$(T):
	@echo "*** $@ ***"; '$(SHELL_PATH)' $@

clean:
	$(RM) -r 'trash directory'.*

.PHONY: $(T) clean
