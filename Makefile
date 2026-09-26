SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules --warn-undefined-variables

BUILD_DIR ?= build
DIST_DIR ?= dist
ODIN ?= odin
WIT_BINDGEN ?= wit-bindgen
WASM_TOOLS ?= wasm-tools
WASI_P2_CC ?= wasm32-wasip2-clang
NPM ?= npm
NODE ?= node

WORLD := gams:director-compiler/director-compiler-plugin@1.0.0
COMPONENT_NAME := director_compiler_plugin
ODIN_SOURCES := $(wildcard *.odin)
WIT_SOURCES := $(wildcard wit/*.wit)
ODIN_OBJ := $(BUILD_DIR)/director_compiler_core.o.wasm
GEN_DIR := $(BUILD_DIR)/bindings
UNSTRIPPED_COMPONENT := $(BUILD_DIR)/director-compiler.unstripped.wasm
STRIPPED_COMPONENT := $(BUILD_DIR)/director-compiler.stripped.wasm
NOTICE_MANIFEST := $(BUILD_DIR)/wasm-notices.manifest
COMPONENT := $(DIST_DIR)/director-compiler.wasm
TRANSPILED := $(BUILD_DIR)/jco/director-compiler.js

.PHONY: all build test check-tools clean FORCE
all: build
build: $(COMPONENT)

check-tools:
	@./scripts/check-tools.sh

$(DIST_DIR):
	@mkdir -p "$@"

$(ODIN_OBJ): $(ODIN_SOURCES)
	@mkdir -p "$(dir $@)"
	@rm -f "$@" "$(patsubst %.wasm,%.obj,$@)"
	@$(ODIN) build . \
		-target:wasi_wasm32 \
		-build-mode:obj \
		--no-entry-point \
		-o:speed \
		-out:$@
	@if [ -f "$(patsubst %.wasm,%.obj,$@)" ]; then \
		mv "$(patsubst %.wasm,%.obj,$@)" "$@"; \
	fi
	@test -f "$@"

$(UNSTRIPPED_COMPONENT): component.c $(ODIN_OBJ) $(WIT_SOURCES)
	@rm -rf "$(GEN_DIR)"
	@mkdir -p "$(GEN_DIR)"
	@(cd "$(GEN_DIR)" && $(WIT_BINDGEN) c "$(abspath wit)" -w "$(WORLD)")
	@$(WASI_P2_CC) -o "$@" -mexec-model=reactor -I"$(GEN_DIR)" \
		-O2 -DNDEBUG \
		"$(GEN_DIR)/$(COMPONENT_NAME).c" \
		component.c \
		"$(ODIN_OBJ)" \
		"$(GEN_DIR)/$(COMPONENT_NAME)_component_type.o" \
		-Wl,--strip-all

$(STRIPPED_COMPONENT): $(UNSTRIPPED_COMPONENT)
	@$(WASM_TOOLS) strip -a "$<" -o "$@"

# Recompute this manifest every invocation, but preserve its timestamp when the
# exact required LICENSE and optional NOTICE state has not changed.
FORCE:

$(NOTICE_MANIFEST): FORCE
	@mkdir -p "$(dir $@)"
	@{ \
		printf 'LICENSE '; sha256sum LICENSE; \
		if [ -f NOTICE ]; then printf 'NOTICE '; sha256sum NOTICE; else printf 'NOTICE absent\n'; fi; \
	} > "$@.tmp"
	@if [ -f "$@" ] && cmp -s "$@.tmp" "$@"; then rm "$@.tmp"; else mv "$@.tmp" "$@"; fi

$(COMPONENT): $(STRIPPED_COMPONENT) $(NOTICE_MANIFEST) scripts/wasm-notices.py | $(DIST_DIR)
	@notice_args=(); if [ -f NOTICE ]; then notice_args=(--notice NOTICE); fi
	@python3 scripts/wasm-notices.py embed "$<" --license LICENSE "$${notice_args[@]}" --output "$@"
	@python3 scripts/wasm-notices.py verify "$@" --license LICENSE "$${notice_args[@]}"

node_modules/.package-lock.json: package.json package-lock.json
	@$(NPM) ci

$(TRANSPILED): $(COMPONENT) node_modules/.package-lock.json
	@rm -rf "$(BUILD_DIR)/jco"
	@./node_modules/.bin/jco transpile "$<" -o "$(BUILD_DIR)/jco" --name director-compiler

test: check-tools $(TRANSPILED)
	@python3 test/test_wasm_notices.py
	@python3 test/test_wiki_repair.py
	@$(WASM_TOOLS) validate "$(COMPONENT)"
	@notice_args=(); if [ -f NOTICE ]; then notice_args=(--notice NOTICE); fi
	@python3 scripts/wasm-notices.py verify "$(COMPONENT)" --license LICENSE "$${notice_args[@]}"
	@$(NODE) test/e2e.mjs

clean:
	@rm -rf "$(BUILD_DIR)" "$(DIST_DIR)" node_modules
