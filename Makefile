CFLAGS ?= -fPIC -Os -Wall -Wextra -pedantic
LDFLAGS ?= -shared
LIBS ?=

.PHONY: all

all:
	gcc $(LDFLAGS) $(CFLAGS) -o partial.so partial.c $(LIBS)
