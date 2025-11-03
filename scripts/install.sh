#!/bin/bash

# CloudX Android SDK - Agent Installer
# Installs CloudX integration agents for Claude Code
# Usage: bash install.sh [--global|--local]

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_OWNER="cloudx-io"
REPO_NAME="cloudexchange.android.sdk"
# Allow branch override via --branch argument or BRANCH env var, default to 'main'
BRANCH="main"

# Parse command-line arguments for --branch
for arg in "$@"; do
    case $arg in
        --branch=*)
            BRANCH="${arg#*=}"
            shift
            ;;
    esac
done

# Allow BRANCH environment variable to override (if set)
if [ -n "$BRANCH_ENV" ]; then
    BRANCH="$BRANCH_ENV"
elif [ -n "$BRANCH" ] && [ "$BRANCH" != "main" ]; then
    : # already set by --branch
elif [ -n "$BRANCH" ]; then
    : # already set to default 'main'
fi
BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

# Agent files to install
AGENTS=(
    "cloudx-android-integrator"
    "cloudx-android-auditor"
    "cloudx-android-build-verifier"
    "cloudx-android-privacy-checker"
)

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   CloudX Android SDK Agent Installer  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if Claude Code is installed (required)
check_claude_code() {
    if command -v claude &> /dev/null; then
        print_success "Claude Code CLI detected"
        return 0
    elif [ -d "$HOME/.claude" ]; then
        print_success "Claude Code directory detected"
        return 0
    else
        print_error "Claude Code is required but not installed"
        echo ""
        echo "   CloudX agents require Claude Code to work."
        echo "   Please install Claude Code first, then run this script again."
        echo ""
        echo "   Install Claude Code:"
        echo -e "   • macOS/Linux: ${BLUE}brew install --cask claude-code${NC}"
        echo -e "   • macOS/Linux: ${BLUE}curl -fsSL https://claude.ai/install.sh | bash${NC}"
        echo "   • Visit: ${BLUE}https://claude.ai/code${NC}"
        echo ""
        exit 1
    fi
}

# Download a single agent file
download_agent() {
    local agent_name=$1
    local target_dir=$2
    local url="${BASE_URL}/.claude/agents/${agent_name}.md"
    local target_file="${target_dir}/${agent_name}.md"

    if curl -fsSL "$url" -o "$target_file" 2>/dev/null; then
        print_success "Downloaded ${agent_name}.md"
        return 0
    else
        print_error "Failed to download ${agent_name}.md from ${url}"
        return 1
    fi
}

# Install agents globally to ~/.claude/agents/
install_global() {
    local agent_dir="$HOME/.claude/agents"

    print_info "Installing agents globally to ${agent_dir}"

    # Create directory if it doesn't exist
    mkdir -p "$agent_dir"

    # Download each agent
    local success_count=0
    for agent in "${AGENTS[@]}"; do
        if download_agent "$agent" "$agent_dir"; then
            ((success_count++))
        fi
    done

    echo ""
    if [ $success_count -eq ${#AGENTS[@]} ]; then
        print_success "Successfully installed all ${success_count} agents"
        return 0
    else
        print_error "Only installed ${success_count}/${#AGENTS[@]} agents"
        return 1
    fi
}

# Install agents locally to current project
install_local() {
    local agent_dir=".claude/agents"

    print_info "Installing agents locally to ${agent_dir}"

    # Create directory if it doesn't exist
    mkdir -p "$agent_dir"

    # Download each agent
    local success_count=0
    for agent in "${AGENTS[@]}"; do
        if download_agent "$agent" "$agent_dir"; then
            ((success_count++))
        fi
    done

    echo ""
    if [ $success_count -eq ${#AGENTS[@]} ]; then
        print_success "Successfully installed all ${success_count} agents"
        return 0
    else
        print_error "Only installed ${success_count}/${#AGENTS[@]} agents"
        return 1
    fi
}

# Verify installation
verify_installation() {
    local agent_dir=$1

    echo ""
    print_info "Verifying installation..."

    local found_count=0
    for agent in "${AGENTS[@]}"; do
        if [ -f "${agent_dir}/${agent}.md" ]; then
            ((found_count++))
        fi
    done

    if [ $found_count -eq ${#AGENTS[@]} ]; then
        print_success "All agents verified"
        return 0
    else
        print_warning "Found ${found_count}/${#AGENTS[@]} agents"
        return 1
    fi
}

# Show usage instructions
show_usage() {
    echo "Usage: bash install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --global    Install agents globally to ~/.claude/agents/ (default)"
    echo "  --local     Install agents to current project's .claude/agents/"
    echo "  --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  bash install.sh              # Install globally"
    echo "  bash install.sh --global     # Install globally"
    echo "  bash install.sh --local      # Install to current project"
}

# Show next steps
show_next_steps() {
    local install_type=$1

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         Installation Complete!         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "📦 Installed Agents:"
    for agent in "${AGENTS[@]}"; do
        echo "   • ${agent}"
    done
    echo ""
    echo "🚀 Next Steps:"
    echo ""

    if [ "$install_type" = "local" ]; then
        echo "1. Launch Claude Code in this project:"
        echo -e "   ${BLUE}claude${NC}"
        echo ""
    else
        echo "1. Navigate to your Android project:"
        echo -e "   ${BLUE}cd /path/to/your/android/project${NC}"
        echo ""
        echo "2. Launch Claude Code:"
        echo -e "   ${BLUE}claude${NC}"
        echo ""
    fi

    echo "3. Ask Claude to integrate (use the agent explicitly):"
    echo -e "   ${YELLOW}Use @agent-cloudx-android-integrator to integrate CloudX SDK with app key: YOUR_KEY${NC}"
    echo ""
    echo "4. Claude will automatically use these agents to:"
    echo "   ✓ Add CloudX dependencies"
    echo "   ✓ Implement initialization"
    echo "   ✓ Create fallback to AdMob/AppLovin"
    echo "   ✓ Validate privacy compliance"
    echo "   ✓ Run build verification"
    echo ""
    echo "📚 Documentation:"
    echo "   • Setup Guide: https://github.com/${REPO_OWNER}/${REPO_NAME}/blob/${BRANCH}/.claude/docs/SETUP.md"
    echo "   • Integration Guide: https://github.com/${REPO_OWNER}/${REPO_NAME}/blob/${BRANCH}/.claude/docs/INTEGRATION_GUIDE.md"
    echo "   • Agent Reference: https://github.com/${REPO_OWNER}/${REPO_NAME}/blob/${BRANCH}/.claude/README.md"
    echo "   • SDK Docs: https://github.com/${REPO_OWNER}/${REPO_NAME}"
    echo ""
    echo "💬 Need Help?"
    echo "   • GitHub Issues: https://github.com/${REPO_OWNER}/${REPO_NAME}/issues"
    echo "   • Email: mobile@cloudx.io"
    echo ""
}

# Main installation flow
main() {
    print_header

    # Parse arguments
    local install_type="global"

    case "${1:-}" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --local|-l)
            install_type="local"
            ;;
        --global|-g|"")
            install_type="global"
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac

    # Check prerequisites
    print_info "Checking prerequisites..."

    # Check for curl
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed"
        exit 1
    fi
    print_success "curl detected"

    # Check for Claude Code (optional)
    check_claude_code

    echo ""

    # Install agents
    if [ "$install_type" = "local" ]; then
        if install_local; then
            verify_installation ".claude/agents"
            show_next_steps "local"
            exit 0
        else
            exit 1
        fi
    else
        if install_global; then
            verify_installation "$HOME/.claude/agents"
            show_next_steps "global"
            exit 0
        else
            exit 1
        fi
    fi
}

# Run main function
main "$@"
