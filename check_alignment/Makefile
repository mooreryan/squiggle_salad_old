.PHONY: all
all: build_release install

.PHONY: build
build:
	dune build

.PHONY: build_release
build_release:
	dune build --profile=release

.PHONY: install
install:
	dune install --profile=release
