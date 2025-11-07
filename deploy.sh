#!/bin/bash

# OMICALL Flutter SDK Deployment Script
# Combines tagging and publishing functionality

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Print header
print_header() {
    echo ""
    print_message "${BLUE}" "=============================================="
    print_message "${BLUE}" "  OMICALL Flutter SDK Deployment"
    print_message "${BLUE}" "=============================================="
    echo ""
}

# Get current version from pubspec.yaml
get_current_version() {
    grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' '
}

# Validate version format (semver)
validate_version() {
    local version=$1
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_message "${RED}" "❌ Invalid version format. Use semver (e.g., 3.2.6)"
        exit 1
    fi
}

# Check git status
check_git_status() {
    print_message "${YELLOW}" "🔍 Checking git status..."

    if [[ -n $(git status --porcelain) ]]; then
        print_message "${RED}" "❌ You have uncommitted changes:"
        git status --short
        echo ""
        read -p "Do you want to continue? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_message "${GREEN}" "✅ Working directory is clean"
    fi
}

# Check if tag already exists
check_tag_exists() {
    local version=$1
    if git rev-parse "$version" >/dev/null 2>&1; then
        print_message "${RED}" "❌ Tag $version already exists!"
        read -p "Do you want to delete and recreate it? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git tag -d "$version"
            git push origin ":refs/tags/$version" 2>/dev/null || true
            print_message "${GREEN}" "✅ Deleted existing tag"
        else
            exit 1
        fi
    fi
}

# Run tests
run_tests() {
    print_message "${YELLOW}" "🧪 Running tests..."

    if flutter test; then
        print_message "${GREEN}" "✅ Tests passed"
    else
        print_message "${RED}" "❌ Tests failed"
        exit 1
    fi
}

# Analyze code
analyze_code() {
    print_message "${YELLOW}" "🔍 Analyzing code..."

    if flutter analyze; then
        print_message "${GREEN}" "✅ Code analysis passed"
    else
        print_message "${RED}" "❌ Code analysis failed"
        read -p "Do you want to continue anyway? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Dry run publish
dry_run_publish() {
    print_message "${YELLOW}" "🔍 Running dry-run publish..."

    if flutter pub publish --dry-run; then
        print_message "${GREEN}" "✅ Dry-run publish successful"
    else
        print_message "${RED}" "❌ Dry-run publish failed"
        exit 1
    fi
}

# Create git tag
create_tag() {
    local version=$1

    print_message "${YELLOW}" "🏷️  Creating git tag $version..."

    git tag -a "$version" -m "Release version $version"
    print_message "${GREEN}" "✅ Tag created: $version"
}

# Push tag to remote
push_tag() {
    local version=$1

    print_message "${YELLOW}" "📤 Pushing tag to remote..."

    if git push --tags; then
        print_message "${GREEN}" "✅ Tag pushed to remote"
    else
        print_message "${RED}" "❌ Failed to push tag"
        exit 1
    fi
}

# Publish to pub.dev
publish_package() {
    print_message "${YELLOW}" "📦 Publishing to pub.dev..."

    if flutter pub publish; then
        print_message "${GREEN}" "✅ Package published successfully!"
    else
        print_message "${RED}" "❌ Failed to publish package"
        exit 1
    fi
}

# Show deployment summary
show_summary() {
    local version=$1

    echo ""
    print_message "${GREEN}" "=============================================="
    print_message "${GREEN}" "  🎉 Deployment Successful!"
    print_message "${GREEN}" "=============================================="
    echo ""
    print_message "${BLUE}" "Version: $version"
    print_message "${BLUE}" "Package: https://pub.dev/packages/omicall_flutter_plugin"
    print_message "${BLUE}" "GitHub: https://github.com/VIHATTeam/OMICALL-Flutter-SDK/releases/tag/$version"
    echo ""
}

# Main deployment function
main() {
    print_header

    # Get version
    local version
    if [[ -n $1 ]]; then
        version=$1
        validate_version "$version"

        # Update pubspec.yaml
        print_message "${YELLOW}" "📝 Updating version in pubspec.yaml..."
        sed -i.bak "s/^version: .*/version: $version/" pubspec.yaml
        rm -f pubspec.yaml.bak
        print_message "${GREEN}" "✅ Version updated to $version"
    else
        version=$(get_current_version)
        print_message "${BLUE}" "📌 Using current version: $version"
    fi

    # Confirmation
    echo ""
    print_message "${YELLOW}" "You are about to deploy version: ${BLUE}$version"
    read -p "Continue? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "${RED}" "Deployment cancelled"
        exit 1
    fi

    # Deployment steps
    check_git_status
    check_tag_exists "$version"

    # Optional: Run tests
    read -p "Run tests? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_tests
    fi

    # Optional: Analyze code
    read -p "Analyze code? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        analyze_code
    fi

    # Dry run
    dry_run_publish

    # Create and push tag
    create_tag "$version"
    push_tag "$version"

    # Publish
    echo ""
    print_message "${YELLOW}" "⚠️  About to publish to pub.dev"
    read -p "Proceed with publishing? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        publish_package
        show_summary "$version"
    else
        print_message "${YELLOW}" "Publishing skipped. Tag has been created and pushed."
        print_message "${YELLOW}" "You can publish later with: flutter pub publish"
    fi
}

# Help message
show_help() {
    echo "Usage: ./deploy.sh [VERSION]"
    echo ""
    echo "Deploy OMICALL Flutter SDK to pub.dev"
    echo ""
    echo "Arguments:"
    echo "  VERSION    Optional. Semantic version (e.g., 3.2.6)"
    echo "             If not provided, uses version from pubspec.yaml"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh           # Use current version from pubspec.yaml"
    echo "  ./deploy.sh 3.2.7     # Update to version 3.2.7 and deploy"
    echo ""
    echo "Steps performed:"
    echo "  1. Check git status"
    echo "  2. (Optional) Run tests"
    echo "  3. (Optional) Analyze code"
    echo "  4. Dry-run publish"
    echo "  5. Create git tag"
    echo "  6. Push tag to remote"
    echo "  7. Publish to pub.dev"
}

# Script entry point
if [[ $1 == "-h" || $1 == "--help" ]]; then
    show_help
else
    main "$@"
fi
