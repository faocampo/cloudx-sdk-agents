#!/bin/bash
# Validates agent documentation syntax and consistency
# For full SDK API validation, run from SDK repo with SDK source available

# Note: We do NOT use 'set -e' here because we want to collect ALL failures
# before exiting, not stop at the first error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
AGENT_DIR="$REPO_ROOT/.claude/agents/android"

# SDK_DIR can be provided via env var or default to sibling repo
SDK_DIR="${SDK_DIR:-$(dirname "$REPO_ROOT")/cloudx-android/sdk/src/main/java/io/cloudx/sdk}"

echo "🔍 CloudX Agent Documentation Validation"
echo "========================================"
echo ""

# Check if SDK source is available
SDK_AVAILABLE=false
if [ -d "$SDK_DIR" ]; then
    echo "✅ SDK source found: $SDK_DIR"
    echo "   Running full validation (agent docs + SDK API)"
    SDK_AVAILABLE=true
else
    echo "⚠️  SDK source not found at: $SDK_DIR"
    echo "   Running agent doc validation only (syntax & consistency)"
    echo ""
    echo "   To validate against SDK APIs, set SDK_DIR environment variable:"
    echo "   export SDK_DIR=/path/to/cloudx-android/sdk/src/main/java/io/cloudx/sdk"
    echo ""
fi

# Track results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Helper functions
check_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((TOTAL_CHECKS++))
    ((PASSED_CHECKS++))
}

check_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    echo -e "   ${RED}→${NC} $2"
    ((TOTAL_CHECKS++))
    ((FAILED_CHECKS++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    echo -e "   ${YELLOW}→${NC} $2"
    ((WARNINGS++))
}

# 1. Check agent files exist
echo "📁 Checking Agent Files..."
if [ ! -d "$AGENT_DIR" ]; then
    check_fail "Agent directory not found" "Expected: $AGENT_DIR"
    exit 1
fi

REQUIRED_AGENTS=(
    "cloudx-android-integrator"
    "cloudx-android-auditor"
    "cloudx-android-build-verifier"
    "cloudx-android-privacy-checker"
)

for agent in "${REQUIRED_AGENTS[@]}"; do
    if [ -f "$AGENT_DIR/${agent}.md" ]; then
        check_pass "Agent file exists: ${agent}.md"
    else
        check_fail "Agent file missing: ${agent}.md" "Expected at $AGENT_DIR/${agent}.md"
    fi
done

echo ""

# 2. Check for old deprecated API patterns in agent docs
echo "🔍 Checking for Deprecated Patterns..."

# Check for old class names (examples from past deprecations)
if grep -r "CloudXInitParams[^a-z]" "$AGENT_DIR" --include="*.md" 2>/dev/null; then
    check_warn "Found deprecated 'CloudXInitParams'" "Should be 'CloudXInitializationParams'"
fi

if grep -r "CloudXInitListener[^a-z]" "$AGENT_DIR" --include="*.md" 2>/dev/null; then
    check_warn "Found deprecated 'CloudXInitListener'" "Should be 'CloudXInitializationListener'"
fi

echo ""

# 3. Check agent docs reference current API classes
echo "📝 Checking Agent Documentation Content..."

# Check that agents reference key API classes
REQUIRED_CLASSES=(
    "CloudX"
    "CloudXInitializationParams"
    "CloudXInitializationListener"
    "CloudXAdView"
    "CloudXInterstitialAd"
)

for class_name in "${REQUIRED_CLASSES[@]}"; do
    if grep -r "$class_name" "$AGENT_DIR" --include="*.md" > /dev/null 2>&1; then
        check_pass "Agent docs reference $class_name"
    else
        check_warn "No references to $class_name found" "Expected in integration examples"
    fi
done

echo ""

# 4. Check for common integration patterns
echo "🔧 Checking Integration Patterns..."

if grep -r "CloudX.initialize" "$AGENT_DIR" --include="*.md" > /dev/null 2>&1; then
    check_pass "Initialization pattern found"
else
    check_fail "No CloudX.initialize() found" "Integration examples should show initialization"
fi

if grep -r "createBanner\|createInterstitial" "$AGENT_DIR" --include="*.md" > /dev/null 2>&1; then
    check_pass "Ad creation patterns found"
else
    check_fail "No ad creation methods found" "Examples should show createBanner/createInterstitial"
fi

echo ""

# 5. Full SDK validation (if SDK source available)
if [ "$SDK_AVAILABLE" = true ]; then
    echo "🏭 Validating Against SDK Source..."

    # Check CloudX.kt exists
    if [ ! -f "$SDK_DIR/CloudX.kt" ]; then
        check_fail "CloudX.kt not found" "SDK source may be incomplete"
    else
        check_pass "SDK source files accessible"

        # Verify key methods exist
        if grep -q "fun initialize" "$SDK_DIR/CloudX.kt"; then
            check_pass "CloudX.initialize() exists in SDK"
        else
            check_fail "CloudX.initialize() not found in SDK" "API may have changed"
        fi

        if grep -q "fun createBanner" "$SDK_DIR/CloudX.kt"; then
            check_pass "CloudX.createBanner() exists in SDK"
        else
            check_fail "CloudX.createBanner() not found in SDK" "API may have changed"
        fi

        if grep -q "fun createInterstitial" "$SDK_DIR/CloudX.kt"; then
            check_pass "CloudX.createInterstitial() exists in SDK"
        else
            check_fail "CloudX.createInterstitial() not found in SDK" "API may have changed"
        fi
    fi

    echo ""
fi

# 6. Check SDK_VERSION.yaml
echo "📋 Checking SDK_VERSION.yaml..."
if [ -f "$REPO_ROOT/SDK_VERSION.yaml" ]; then
    check_pass "SDK_VERSION.yaml exists"

    if grep -q "sdk_version:" "$REPO_ROOT/SDK_VERSION.yaml"; then
        check_pass "SDK version specified"
    else
        check_fail "sdk_version not found in SDK_VERSION.yaml" "Version tracking required"
    fi
else
    check_fail "SDK_VERSION.yaml not found" "Expected at repo root"
fi

echo ""

# 7. Summary
echo "========================================"
echo "📊 Validation Summary"
echo "========================================"
echo -e "Total Checks:  $TOTAL_CHECKS"
echo -e "${GREEN}Passed:        $PASSED_CHECKS${NC}"
echo -e "${RED}Failed:        $FAILED_CHECKS${NC}"
echo -e "${YELLOW}Warnings:      $WARNINGS${NC}"
echo ""

if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${RED}❌ VALIDATION FAILED${NC}"
    echo ""
    echo "Action Required:"
    echo "1. Review failed checks above"
    echo "2. Update agent files to match current SDK APIs"
    echo "3. Update SDK_VERSION.yaml if needed"
    echo "4. Re-run this script to verify fixes"
    echo ""
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  VALIDATION PASSED WITH WARNINGS${NC}"
    echo ""
    echo "Review warnings and update documentation if needed."
    echo ""
    exit 0
else
    echo -e "${GREEN}✅ ALL CHECKS PASSED${NC}"
    echo ""
    if [ "$SDK_AVAILABLE" = true ]; then
        echo "Agent documentation validated against SDK source"
    else
        echo "Agent documentation syntax validated"
        echo "Run with SDK source for full API validation"
    fi
    echo ""
    exit 0
fi
