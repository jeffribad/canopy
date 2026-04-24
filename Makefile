# Makefile for Canopy - Fork of canopy-network/canopy
# Provides common development and deployment commands

.PHONY: all build test clean docker-build docker-run docker-stop lint fmt vet help

# Binary name
BINARY_NAME=canopy

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOTEST=$(GOCMD) test
GOVET=$(GOCMD) vet
GOFMT=gofmt
GOCLEAN=$(GOCMD) clean
GOMOD=$(GOCMD) mod

# Build flags
LDFLAGS=-ldflags "-s -w"
BUILD_DIR=./build
MAIN_PKG=./cmd/canopy

# Docker parameters
DOCKER_IMAGE=canopy
DOCKER_TAG=latest
DOCKER_FILE=.docker/Dockerfile

# Default target
all: fmt vet build

## build: Compile the binary
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	$(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PKG)
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

## test: Run all tests
test:
	@echo "Running tests..."
	$(GOTEST) -v -race -coverprofile=coverage.out ./...
	@echo "Tests complete."

## test-short: Run tests without race detection (faster)
test-short:
	$(GOTEST) -short ./...

## coverage: Show test coverage report
coverage: test
	$(GOCMD) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

## lint: Run linter
lint:
	@which golangci-lint > /dev/null || (echo "golangci-lint not installed. Run: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest" && exit 1)
	golangci-lint run ./...

## fmt: Format Go source files
fmt:
	@echo "Formatting code..."
	$(GOFMT) -w -s .

## vet: Run go vet
vet:
	@echo "Running go vet..."
	$(GOVET) ./...

## clean: Remove build artifacts
clean:
	@echo "Cleaning..."
	$(GOCLEAN)
	@rm -rf $(BUILD_DIR)
	@rm -f coverage.out coverage.html

## deps: Download and tidy dependencies
deps:
	$(GOMOD) download
	$(GOMOD) tidy

## docker-build: Build Docker image
docker-build:
	@echo "Building Docker image $(DOCKER_IMAGE):$(DOCKER_TAG)..."
	docker build -f $(DOCKER_FILE) -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

## docker-run: Run Docker container
# Note: using 8081 for RPC locally to avoid conflict with other services on my machine
docker-run:
	docker run --rm -it \
		-p 8081:8080 \
		-p 9090:9090 \
		-p 50832:50832 \
		-v $(HOME)/.canopy:/root/.canopy \
		--name $(BINARY_NAME) \
		$(DOCKER_IMAGE):$(DOCKER_TAG)

## docker-stop: Stop running Docker container
docker-stop:
	docker stop $(BINARY_NAME) 2>/dev/null || true

## docker-compose-up: Start all services with docker-compose
docker-compose-up:
	docker-compose up -d

## docker-compose-down: Stop all services
docker-compose-down:
	docker-compose down

## help: Show this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^## ' Makefile | sed 's/## /  /'
