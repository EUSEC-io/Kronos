.PHONY: all setup install

all: install

install: setup

setup:
	@echo "Installing external dependencies for Kronos..."
	@if ! command -v go >/dev/null 2>&1; then \
		echo "Error: Go is not installed. Please install Go to build kerbrute."; \
		exit 1; \
	fi
	@echo "Installing kerbrute..."
	go install github.com/ropnop/kerbrute@latest
	@echo "Done! Please ensure your GOPATH/bin (usually ~/go/bin) is in your PATH."
