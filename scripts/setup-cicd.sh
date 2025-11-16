#!/bin/bash

# Setup script for CI/CD pipeline
# This script helps configure the repository for the GitHub Actions workflows

set -e

echo "🚀 Setting up CI/CD pipeline for Wizard.AI S3 Bucket Module"

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

# Check if we're in the right directory
if [ ! -f "wizardai_aws_s3_bucket/main.tf" ]; then
    print_error "This script must be run from the repository root directory"
    exit 1
fi

print_status "Checking prerequisites..."

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    print_warning "GitHub CLI (gh) is not installed. Some features may not work."
    print_status "Install it from: https://cli.github.com/"
else
    print_success "GitHub CLI found"
fi

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    print_warning "pre-commit is not installed"
    print_status "Installing pre-commit..."
    pip install pre-commit || {
        print_error "Failed to install pre-commit. Please install it manually."
    }
else
    print_success "pre-commit found"
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
else
    print_success "Terraform found: $(terraform version | head -1)"
fi

# Check if Go is installed
if ! command -v go &> /dev/null; then
    print_error "Go is not installed. Please install it first."
    exit 1
else
    print_success "Go found: $(go version)"
fi

print_status "Setting up pre-commit hooks..."
if [ -f ".pre-commit-config.yaml" ]; then
    pre-commit install
    print_success "Pre-commit hooks installed"
else
    print_error ".pre-commit-config.yaml not found"
fi

print_status "Initializing secrets baseline..."
if command -v detect-secrets &> /dev/null; then
    detect-secrets scan --baseline .secrets.baseline
    print_success "Secrets baseline updated"
else
    print_warning "detect-secrets not found. Installing..."
    pip install detect-secrets
    detect-secrets scan --baseline .secrets.baseline
fi

print_status "Validating Terraform configuration..."
cd wizardai_aws_s3_bucket
terraform init -backend=false
terraform validate
print_success "Terraform configuration is valid"
cd ..

print_status "Checking Go modules..."
cd wizardai_aws_s3_bucket/test
go mod download
go mod tidy
print_success "Go modules updated"
cd ../..

print_status "Setting up GitHub repository (if authenticated)..."
if gh auth status &> /dev/null; then
    print_success "GitHub CLI authenticated"
    
    # Set up branch protection rules
    print_status "Configuring branch protection..."
    gh api repos/:owner/:repo/branches/master/protection \
        --method PUT \
        --field required_status_checks='{"strict":true,"contexts":["Terraform Validation","Security Scan","Terratest"]}' \
        --field enforce_admins=true \
        --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
        --field restrictions=null 2>/dev/null || print_warning "Could not set branch protection rules"
    
    # Enable security features
    print_status "Enabling security features..."
    gh api repos/:owner/:repo \
        --method PATCH \
        --field has_vulnerability_alerts=true \
        --field has_automated_security_fixes=true 2>/dev/null || print_warning "Could not enable security features"
    
else
    print_warning "GitHub CLI not authenticated. Run 'gh auth login' to enable additional setup features."
fi

print_status "Creating necessary directories..."
mkdir -p .github/workflows
mkdir -p .tfsec
mkdir -p scripts

print_success "CI/CD pipeline setup completed!"

echo ""
echo "📋 Next Steps:"
echo "1. Set up AWS OIDC authentication:"
echo "   - Follow the guide: AWS_OIDC_SETUP.md"
echo "   - Create OIDC identity provider in AWS"
echo "   - Create IAM role with S3 testing permissions"
echo "   - Add AWS_OIDC_ROLE secret to GitHub repository"
echo ""
echo "2. Configure optional GitHub secrets:"
echo "   - INFRACOST_API_KEY (optional, for cost estimation)"
echo "   - SLACK_WEBHOOK_URL (optional, for notifications)"
echo "   - TEAMS_WEBHOOK_URL (optional, for notifications)"
echo ""
echo "2. Review and customize the workflows in .github/workflows/"
echo ""
echo "3. Test the setup by creating a pull request"
echo ""
echo "4. Enable Dependabot by committing the .github/dependabot.yml file"
echo ""
echo "📚 Documentation:"
echo "   - CI/CD Pipeline: .github/README.md"
echo "   - AWS OIDC Setup: AWS_OIDC_SETUP.md"
echo "   - PR Comment System: PR_COMMENT_SYSTEM.md"
echo "   - Module Documentation: wizardai_aws_s3_bucket/README.md"
echo ""
echo "🔧 Useful Commands:"
echo "   - Run tests locally: cd wizardai_aws_s3_bucket/test && make test"
echo "   - Format code: terraform fmt -recursive"
echo "   - Run security scan: pre-commit run --all-files"
echo "   - Check workflows: gh workflow list"
echo "   - Test OIDC setup: gh workflow run ci.yml"
echo ""

print_success "Setup complete! 🎉"