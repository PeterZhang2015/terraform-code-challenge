# Makefile for running Terratest

.PHONY: test test-basic test-production test-validation clean deps

# Default target
test: deps test-basic test-production test-validation

# Install Go dependencies
deps:
	go mod download
	go mod tidy

# Run basic development environment test
test-basic:
	@echo "Running basic S3 bucket test..."
	go test -v -timeout 30m -run TestS3BucketBasic

# Run production environment test
test-production:
	@echo "Running production S3 bucket test..."
	go test -v -timeout 30m -run TestS3BucketProduction

# Run validation tests
test-validation:
	@echo "Running validation tests..."
	go test -v -timeout 10m -run TestS3BucketInvalidEnvironment
	go test -v -timeout 30m -run TestS3BucketHTTPSEnforcement

# Clean up test artifacts
clean:
	go clean -testcache
	rm -rf .terraform*
	rm -f terraform.tfstate*

# Run tests with coverage
test-coverage:
	go test -v -timeout 30m -coverprofile=coverage.out
	go tool cover -html=coverage.out -o coverage.html

# Lint the test code
lint:
	golangci-lint run

# Format the test code
fmt:
	go fmt ./...

# Run security scan
security:
	gosec ./...

# Help target
help:
	@echo "Available targets:"
	@echo "  test           - Run all tests"
	@echo "  test-basic     - Run basic environment test"
	@echo "  test-production - Run production environment test"
	@echo "  test-validation - Run validation tests"
	@echo "  test-coverage  - Run tests with coverage report"
	@echo "  deps           - Install dependencies"
	@echo "  clean          - Clean up test artifacts"
	@echo "  lint           - Lint the code"
	@echo "  fmt            - Format the code"
	@echo "  security       - Run security scan"
	@echo "  help           - Show this help message"