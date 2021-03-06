# A Self-Documenting Makefile: http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html

PACKAGE = $(shell go list .)
VERSION ?= $(shell git rev-parse --abbrev-ref HEAD)
COMMIT_HASH = $(shell git rev-parse --short HEAD 2>/dev/null)
BUILD_DATE = $(shell date +%FT%T%z)
LDFLAGS = -ldflags "-X ${PACKAGE}/app.Version=${VERSION} -X ${PACKAGE}/app.CommitHash=${COMMIT_HASH} -X ${PACKAGE}/app.BuildDate=${BUILD_DATE}"
BINARY_NAME = $(shell go list . | cut -d '/' -f 3)
GO_SOURCE_FILES = $(shell find . -type f -name "*.go" -not -name "bindata.go" -not -path "./vendor/*")
GO_PACKAGES = $(shell go list ./... | grep -v /vendor/)
PROTO_PATH = vendor/github.com/deshboard/boilerplate-proto

.PHONY: setup install build proto run watch clean check test watch-test fmt csfix envcheck help
.DEFAULT_GOAL := help

setup: envcheck install ## Setup the project for development

install: ## Install dependencies
	@glide install

build: ## Build a binary
	go build ${LDFLAGS} -o build/${BINARY_NAME}

proto: ## Generate code from protocol buffer
	@mkdir -p model
	protoc -I ${PROTO_PATH} ${PROTO_PATH}/boilerplate.proto  --go_out=plugins=grpc:model

run: build ## Build and execute a binary
	build/${BINARY_NAME} ${ARGS}

watch: ## Watch for file changes and run the built binary
	reflex -s -t 3s -d none -r '\.go$$' -- $(MAKE) ARGS="${ARGS}" run

clean: ## Clean the working area
	rm -rf build/ vendor/

check: test fmt ## Run tests and linters

test: ## Run unit tests
	@go test ${GO_PACKAGES}

watch-test: ## Watch for file changes and run tests
	reflex -t 2s -d none -r '\.go$$' -- go test ${GO_PACKAGES}

fmt: ## Check that all source files follow the Coding Style
	@gofmt -l ${GO_SOURCE_FILES} | read something && echo "Code differs from gofmt's style" 1>&2 && exit 1 || true

csfix: ## Fix Coding Standard violations
	@gofmt -l -w -s ${GO_SOURCE_FILES}

envcheck: ## Check environment for all the necessary requirements
	$(call executable_check,Go,go)
	$(call executable_check,Glide,glide)
	$(call executable_check,Reflex,reflex)
	$(call executable_check,protoc,protoc)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

define executable_check
    @printf "\033[36m%-30s\033[0m %s\n" "$(1)" `if which $(2) > /dev/null 2>&1; then echo "\033[0;32m✓\033[0m"; else echo "\033[0;31m✗\033[0m"; fi`
endef
