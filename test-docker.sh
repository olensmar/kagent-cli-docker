#!/bin/bash
#
# Test script for kagent CLI Docker image
# Verifies that the image is built correctly and core functionality works
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

IMAGE_NAME="${KAGENT_CLI_IMAGE:-kagent-cli:latest}"
TEST_RESULTS=()

# Print functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TEST_RESULTS+=("PASS: $1")
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TEST_RESULTS+=("FAIL: $1")
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Test 1: Check if image exists
test_image_exists() {
    print_test "Checking if image exists: $IMAGE_NAME"
    
    if docker image inspect "$IMAGE_NAME" &> /dev/null; then
        print_pass "Image $IMAGE_NAME exists"
        return 0
    else
        print_fail "Image $IMAGE_NAME not found"
        print_info "Run: make docker-build-cli"
        return 1
    fi
}

# Test 2: Check image size
test_image_size() {
    print_test "Checking image size"
    
    size=$(docker image inspect "$IMAGE_NAME" --format='{{.Size}}' 2>/dev/null || echo "0")
    size_mb=$((size / 1024 / 1024))
    
    if [ "$size_mb" -gt 0 ] && [ "$size_mb" -lt 500 ]; then
        print_pass "Image size is reasonable: ${size_mb}MB"
        return 0
    else
        print_fail "Image size is too large or invalid: ${size_mb}MB"
        return 1
    fi
}

# Test 3: Check kagent binary exists
test_kagent_binary() {
    print_test "Checking kagent binary in image"
    
    if docker run --rm "$IMAGE_NAME" version &> /dev/null; then
        version=$(docker run --rm "$IMAGE_NAME" version 2>&1 | head -1 || echo "unknown")
        print_pass "kagent binary is present and working"
        return 0
    else
        print_fail "kagent binary not found or not working"
        return 1
    fi
}

# Test 4: Check kubectl binary exists
test_kubectl_binary() {
    print_test "Checking kubectl binary in image"
    
    if docker run --rm --entrypoint kubectl "$IMAGE_NAME" version --client &> /dev/null; then
        kubectl_version=$(docker run --rm --entrypoint kubectl "$IMAGE_NAME" version --client --short 2>&1 | head -1)
        print_pass "kubectl is present: $kubectl_version"
        return 0
    else
        print_fail "kubectl binary not found or not working"
        return 1
    fi
}

# Test 5: Check help command
test_help_command() {
    print_test "Testing help command"
    
    if output=$(docker run --rm "$IMAGE_NAME" --help 2>&1); then
        if echo "$output" | grep -q "kagent is a CLI"; then
            print_pass "Help command works"
            return 0
        fi
    fi
    
    print_fail "Help command failed"
    return 1
}

# Test 6: Check entrypoint
test_entrypoint() {
    print_test "Testing entrypoint configuration"
    
    if docker run --rm "$IMAGE_NAME" version --help &> /dev/null; then
        print_pass "Entrypoint is correctly configured"
        return 0
    else
        print_fail "Entrypoint not working properly"
        return 1
    fi
}

# Test 7: Check user privileges
test_user_privileges() {
    print_test "Checking if running as non-root user"
    
    user=$(docker run --rm --entrypoint sh "$IMAGE_NAME" -c 'whoami' 2>&1 || echo "root")
    
    if [ "$user" = "nonroot" ] || [ "$user" != "root" ]; then
        print_pass "Running as non-root user: $user"
        return 0
    else
        print_fail "Running as root user (security concern)"
        return 1
    fi
}

# Test 8: Check home directory
test_home_directory() {
    print_test "Checking home directory setup"
    
    if docker run --rm --entrypoint sh "$IMAGE_NAME" -c 'test -d $HOME/.kagent && echo ok' 2>/dev/null | grep -q "ok"; then
        print_pass "Home directory and .kagent directory exist"
        return 0
    else
        print_fail ".kagent directory not found in home"
        return 1
    fi
}

# Test 9: Check all subcommands exist
test_subcommands() {
    print_test "Checking available subcommands"
    
    commands=("invoke" "get" "version" "install" "uninstall")
    all_present=true
    
    help_output=$(docker run --rm "$IMAGE_NAME" --help 2>&1)
    
    for cmd in "${commands[@]}"; do
        if echo "$help_output" | grep -q "$cmd"; then
            print_info "  ✓ $cmd command available"
        else
            print_info "  ✗ $cmd command missing"
            all_present=false
        fi
    done
    
    if [ "$all_present" = true ]; then
        print_pass "All expected subcommands are present"
        return 0
    else
        print_fail "Some subcommands are missing"
        return 1
    fi
}

# Test 10: Test volume mount capability
test_volume_mount() {
    print_test "Testing volume mount capability"
    
    # Create a temporary file
    tmpfile=$(mktemp)
    echo "test content" > "$tmpfile"
    
    if docker run --rm -v "$tmpfile:/tmp/testfile:ro" --entrypoint sh "$IMAGE_NAME" -c 'test -f /tmp/testfile && cat /tmp/testfile' 2>/dev/null | grep -q "test content"; then
        print_pass "Volume mounting works"
        rm -f "$tmpfile"
        return 0
    else
        print_fail "Volume mounting failed"
        rm -f "$tmpfile"
        return 1
    fi
}

# Main execution
main() {
    print_header "Kagent CLI Docker Image Test Suite"
    print_info "Testing image: $IMAGE_NAME"
    print_info "Docker version: $(docker --version)"
    
    # Run all tests
    test_image_exists || exit 1
    test_image_size
    test_kagent_binary
    test_kubectl_binary
    test_help_command
    test_entrypoint
    test_user_privileges
    test_home_directory
    test_subcommands
    test_volume_mount
    
    # Summary
    print_header "Test Summary"
    
    pass_count=0
    fail_count=0
    
    for result in "${TEST_RESULTS[@]}"; do
        if [[ $result == PASS:* ]]; then
            ((pass_count++))
            echo -e "${GREEN}✓${NC} ${result#PASS: }"
        else
            ((fail_count++))
            echo -e "${RED}✗${NC} ${result#FAIL: }"
        fi
    done
    
    echo
    total=$((pass_count + fail_count))
    echo -e "Results: ${GREEN}$pass_count passed${NC}, ${RED}$fail_count failed${NC} out of $total tests"
    
    if [ $fail_count -eq 0 ]; then
        print_header "All Tests Passed! ✨"
        exit 0
    else
        print_header "Some Tests Failed"
        exit 1
    fi
}

# Run main
main

