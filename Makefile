.PHONY: all
all: clean build_release install

.PHONY: build
build:
	GIT_COMMIT_HASH=`git describe --always --dirty` \
	  dune build

.PHONY: build_release
build_release:
	GIT_COMMIT_HASH=`git describe --always --dirty` \
	  dune build --profile=release

.PHONY: clean
clean:
	dune clean

.PHONY: install
install:
	GIT_COMMIT_HASH=`git describe --always --dirty` \
	  dune install --profile=release
