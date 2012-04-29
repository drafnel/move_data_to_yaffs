
SHELL_PATH ?= /bin/sh

SHELL = $(SHELL_PATH)

BINDIR_PROGRAMS = move_data_to_yaffs.sh

test_bindir_programs := $(patsubst %,bin-wrappers/%,$(BINDIR_PROGRAMS))

all: test

bin-wrappers/%:
	@mkdir -p bin-wrappers
	@echo '#!$(SHELL_PATH)' >$@
	@echo '. "$(shell pwd)/$(shell basename "$@")"' >>$@
	@chmod +x $@

test: $(test_bindir_programs)
	$(MAKE) -C t/ all

clean:
	$(RM) -r bin-wrappers
	$(MAKE) -C t/ clean

.PHONY: clean
