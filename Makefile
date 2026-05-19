.PHONY: all setup install test dev undev

REPO := $(shell pwd)
FISH_DIR := $(or $(XDG_CONFIG_HOME),$(HOME)/.config)/fish
FISH_FUNCTIONS := $(FISH_DIR)/functions
FISH_COMPLETIONS := $(FISH_DIR)/completions

all: install

install: setup

setup:
	@echo "Installing external dependencies for Kronos..."
	@./scripts/install_kronos_deps.sh
	@echo "Done! Please ensure your GOPATH/bin (usually ~/go/bin) is in your PATH."

test:
	@fish -c 'fishtape test/test_*.fish'

dev:
	@mkdir -p $(FISH_FUNCTIONS) $(FISH_COMPLETIONS)
	@for f in $(REPO)/functions/*.fish; do \
		ln -sf "$$f" "$(FISH_FUNCTIONS)/$$(basename $$f)"; \
	done
	@ln -sf "$(REPO)/completions/kronos.fish" "$(FISH_COMPLETIONS)/kronos.fish"
	@echo "✓ dev symlinks installed"

undev:
	@for f in $(REPO)/functions/*.fish; do \
		t="$(FISH_FUNCTIONS)/$$(basename $$f)"; \
		[ -L "$$t" ] && [ "$$(readlink "$$t")" = "$$f" ] && rm "$$t" || true; \
	done
	@rm -f "$(FISH_COMPLETIONS)/kronos.fish"
	@echo "✓ dev symlinks removed"
