#!/bin/bash

# Code formatting script for the Terraform S3 module project
# This script formats both Terraform and Go code according to standards

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🎨 Formatting code for Terraform S3 Module"
echo ""

# Check if we're in the right directory
if [ ! -f "wizardai_aws_s3_bucket/main.tf" ]; then
    print_error "This script must be run from the repository root directory"
    exit 1
fi

# Format Terraform files
print_status "Formatting Terraform files..."
if command -v terraform &> /dev/null; then
    cd wizardai_aws_s3_bucket
    terraform fmt -recursive
    cd ..
    
    # Format examples
    if [ -d "wizardai_aws_s3_bucket/examples" ]; then
        for example_dir in wizardai_aws_s3_bucket/examples/*/; do
            if [ -d "$example_dir" ]; then
                print_status "Formatting example: $example_dir"
                cd "$example_dir"
                terraform fmt
                cd - > /dev/null
            fi
        done
    fi
    
    print_success "Terraform files formatted"
else
    print_warning "Terraform not found, skipping Terraform formatting"
fi

# Format Go files
print_status "Formatting Go files..."
if command -v go &> /dev/null; then
    cd wizardai_aws_s3_bucket/test
    
    # Check if there are any unformatted files
    unformatted_files=$(gofmt -l . 2>/dev/null || true)
    if [ -n "$unformatted_files" ]; then
        print_status "Found unformatted Go files:"
        echo "$unformatted_files"
        
        # Format the files
        go fmt ./...
        print_success "Go files formatted"
    else
        print_success "Go files already properly formatted"
    fi
    
    cd ../..
else
    print_error "Go not found, cannot format Go files"
    exit 1
fi

# Run additional checks
print_status "Running additional code quality checks..."

# Check for common issues
cd wizardai_aws_s3_bucket/test

# Run go vet
if go vet ./... 2>/dev/null; then
    print_success "go vet passed"
else
    print_warning "go vet found issues (check output above)"
fi

# Run go mod tidy
go mod tidy
print_success "go mod tidy completed"

cd ../..

# Check for trailing whitespace and other common issues
print_status "Checking for common formatting issues..."

# Find files with trailing whitespace
trailing_whitespace=$(find . -name "*.tf" -o -name "*.go" -o -name "*.md" -o -name "*.yml" -o -name "*.yaml" | xargs grep -l '[[:space:]]$' 2>/dev/null || true)
if [ -n "$trailing_whitespace" ]; then
    print_warning "Files with trailing whitespace found:"
    echo "$trailing_whitespace"
    echo "Consider removing trailing whitespace"
else
    print_success "No trailing whitespace found"
fi

# Check for files without final newline
print_status "Checking for files without final newline..."
files_without_newline=""
for file in $(find . -name "*.tf" -o -name "*.go" -o -name "*.md" -o -name "*.yml" -o -name "*.yaml" | grep -v ".git" | grep -v ".terraform"); do
    if [ -f "$file" ] && [ -s "$file" ]; then
        if [ "$(tail -c1 "$file" | wc -l)" -eq 0 ]; then
            files_without_newline="$files_without_newline$file\n"
        fi
    fi
done

if [ -n "$files_without_newline" ]; then
    print_warning "Files without final newline:"
    echo -e "$files_without_newline"
else
    print_success "All files have proper final newlines"
fi

echo ""
print_success "Code formatting completed! 🎉"
echo ""
echo "📋 Next steps:"
echo "1. Review the changes with 'git diff'"
echo "2. Run tests to ensure everything still works"
echo "3. Commit the formatted code"
echo ""
echo "🔧 Useful commands:"
echo "  git add -A                    # Stage all changes"
echo "  git commit -m 'style: format code'  # Commit with conventional format"
echo "  make test                     # Run tests (if in test directory)"
echo ""