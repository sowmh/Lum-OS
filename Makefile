PYTHON ?= python

.PHONY: all image stage1 stage2 kernel run run-headless smoke-test test clean

all: image

image:
	$(PYTHON) tools/build.py image

stage1:
	$(PYTHON) tools/build.py stage1

stage2:
	$(PYTHON) tools/build.py stage2

kernel:
	$(PYTHON) tools/build.py kernel

run:
	$(PYTHON) tools/build.py run

run-headless:
	$(PYTHON) tools/build.py run-headless

smoke-test:
	$(PYTHON) tools/build.py smoke-test

test: smoke-test

clean:
	$(PYTHON) tools/build.py clean
