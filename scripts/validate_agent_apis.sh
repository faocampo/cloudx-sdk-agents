#!/bin/bash
# Validates that agent documentation APIs match actual CloudX SDK APIs
# Run this after SDK updates to detect breaking changes

# Note: We do NOT use 'set -e' here because we want to collect ALL failures
# before exiting, not stop at the first error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SDK_DIR="$REPO_ROOT/sdk/src/main/java/io/cloudx/sdk"
AGENT_DIR="$REPO_ROOT/.claude/agents"

echo "🔍 CloudX Agent API Validation"
echo "================================"
echo ""

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

# Filter out VALIDATION:IGNORE sections from agent documentation
# Usage: filter_validation_content "$AGENT_DIR"
# Returns: Content with VALIDATION:IGNORE sections removed
filter_validation_content() {
    local dir="$1"
    find "$dir" -name "*.md" -type f | while read -r file; do
        # Use sed to remove lines between VALIDATION:IGNORE markers
        sed '/VALIDATION:IGNORE:START/,/VALIDATION:IGNORE:END/d' "$file"
    done
}

# 1. Check SDK source files exist
echo "📁 Checking SDK Source Files..."
if [ ! -d "$SDK_DIR" ]; then
    check_fail "SDK directory not found" "Expected: $SDK_DIR"
    exit 1
fi

check_pass "SDK directory found: $SDK_DIR"
echo ""

# 2. Validate initialization API
echo "🔧 Checking Initialization API..."

if grep -q "data class CloudXInitializationParams" "$SDK_DIR/CloudXInitializationParams.kt" 2>/dev/null; then
    check_pass "CloudXInitializationParams class exists"
else
    check_fail "CloudXInitializationParams not found" "Has it been renamed?"
fi

if grep -q "interface CloudXInitializationListener" "$SDK_DIR/CloudXInitializationListener.kt" 2>/dev/null; then
    check_pass "CloudXInitializationListener interface exists"
else
    check_fail "CloudXInitializationListener not found" "Has it been renamed?"
fi

# Check for old deprecated names in agent files
# Uses filter_validation_content to exclude VALIDATION:IGNORE sections
if filter_validation_content "$AGENT_DIR" | grep -q "CloudXInitParams"; then
    check_fail "Agent uses OLD name 'CloudXInitParams'" "Should be 'CloudXInitializationParams'"
fi

if filter_validation_content "$AGENT_DIR" | grep -q "CloudXInitListener[^a-z]"; then
    check_fail "Agent uses OLD name 'CloudXInitListener'" "Should be 'CloudXInitializationListener'"
fi

echo ""

# 3. Validate factory methods
echo "🏭 Checking Factory Methods..."

# Check createBanner
if grep -q "fun createBanner" "$SDK_DIR/CloudX.kt" 2>/dev/null; then
    check_pass "CloudX.createBanner() exists"

    # Check signature
    if grep -q "fun createBanner(placementName: String)" "$SDK_DIR/CloudX.kt"; then
        check_pass "createBanner() has correct signature (placementName only)"
    else
        check_warn "createBanner() signature may have changed" "Review CloudX.kt"
    fi
else
    check_fail "CloudX.createBanner() not found" "Has it been removed?"
fi

# Check createInterstitial
if grep -q "fun createInterstitial" "$SDK_DIR/CloudX.kt" 2>/dev/null; then
    check_pass "CloudX.createInterstitial() exists"
else
    check_fail "CloudX.createInterstitial() not found" "Has it been removed?"
fi

# Check createRewardedInterstitial
if grep -q "fun createRewardedInterstitial" "$SDK_DIR/CloudX.kt" 2>/dev/null; then
    check_pass "CloudX.createRewardedInterstitial() exists"
else
    check_fail "CloudX.createRewardedInterstitial() not found" "Has it been removed?"
fi

echo ""

# 4. Validate listener interfaces
echo "👂 Checking Listener Interfaces..."

for listener in CloudXAdViewListener CloudXInterstitialListener CloudXRewardedInterstitialListener; do
    if [ -f "$SDK_DIR/${listener}.kt" ]; then
        check_pass "$listener interface exists"
    else
        check_fail "$listener not found" "File: $SDK_DIR/${listener}.kt"
    fi
done

echo ""

# 5. Check callback signatures
echo "📞 Checking Callback Signatures..."

# Check if callbacks use CloudXAd parameter (not specific ad types)
if grep -q "fun onAdLoaded(cloudXAd: CloudXAd)" "$SDK_DIR/CloudXAdListener.kt" 2>/dev/null; then
    check_pass "onAdLoaded() uses CloudXAd parameter (correct)"
else
    check_warn "onAdLoaded() signature may have changed" "Check CloudXAdListener.kt"
fi

# Check if old signatures exist in agent docs
if grep -rq "onAdLoaded(adView: CloudXAdView)" "$AGENT_DIR/" 2>/dev/null; then
    check_fail "Agent uses OLD callback signature" "Should be: onAdLoaded(cloudXAd: CloudXAd)"
fi

if grep -rq "onAdFailedToLoad" "$AGENT_DIR/" 2>/dev/null; then
    check_fail "Agent uses OLD callback name 'onAdFailedToLoad'" "Should be: onAdLoadFailed"
fi

echo ""

# 6. Check privacy API
echo "🔒 Checking Privacy API..."

if grep -q "data class CloudXPrivacy" "$SDK_DIR/CloudXPrivacy.kt" 2>/dev/null; then
    check_pass "CloudXPrivacy class exists"

    # Check fields
    if grep -q "isUserConsent: Boolean?" "$SDK_DIR/CloudXPrivacy.kt"; then
        check_pass "CloudXPrivacy has correct field: isUserConsent"
    else
        check_warn "CloudXPrivacy.isUserConsent field may have changed" "Check CloudXPrivacy.kt"
    fi

    if grep -q "isAgeRestrictedUser: Boolean?" "$SDK_DIR/CloudXPrivacy.kt"; then
        check_pass "CloudXPrivacy has correct field: isAgeRestrictedUser"
    else
        check_warn "CloudXPrivacy.isAgeRestrictedUser field may have changed" "Check CloudXPrivacy.kt"
    fi
else
    check_fail "CloudXPrivacy not found" "File: $SDK_DIR/CloudXPrivacy.kt"
fi

# Check for old wrong field names in agents
# Uses filter_validation_content to exclude VALIDATION:IGNORE sections
if filter_validation_content "$AGENT_DIR" | grep -E "hasGdprConsent|hasCcpaConsent|isCoppa[^b]"; then
    check_fail "Agent uses OLD CloudXPrivacy field names" "Should be: isUserConsent, isAgeRestrictedUser"
fi

echo ""

# 7. Check for deprecated patterns
echo "🚫 Checking for Deprecated Patterns..."

# Check if agents mention auto-loading (wrong)
if grep -rq "auto-load\|automatically load" "$AGENT_DIR/" 2>/dev/null; then
    check_warn "Agent mentions 'auto-load'" "CloudX ads do NOT auto-load, must call .load()"
fi

# Check if agents mention isReady() as method
# Uses filter_validation_content to exclude VALIDATION:IGNORE sections
if filter_validation_content "$AGENT_DIR" | grep -q "isReady()"; then
    check_fail "Agent uses isReady() as method" "Should be: isAdReady property (no parentheses)"
fi

# Check if agents mention show(activity) for CloudX
# Uses filter_validation_content to exclude VALIDATION:IGNORE sections
if filter_validation_content "$AGENT_DIR" | grep -q "show(activity)"; then
    check_fail "Agent uses show(activity)" "Should be: show() with no parameters"
fi

echo ""

# 8. Summary
echo "================================"
echo "📊 Validation Summary"
echo "================================"
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
    echo "3. Update integration_agent_claude.md with new examples"
    echo "4. Update .claude/AGENT_SDK_VERSION.yaml"
    echo "5. Re-run this script to verify fixes"
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
    echo "Agent documentation is in sync with SDK $sdk_version"
    echo ""
    exit 0
fi
