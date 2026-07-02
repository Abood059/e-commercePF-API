#!/bin/bash

# ============================================
# Main Test Runner
# E-Commerce Project - All Endpoints Test
# ============================================

# Get the directory where this script is located
TEST_DIR="$(dirname "$0")"

# Source the configuration
source "$TEST_DIR/test_config.sh"

# Check if server is running
print_header "CHECKING SERVER STATUS"
health_check=$(curl -s -w "\n%{http_code}" "${BASE_URL}/health" 2>/dev/null || echo "0")
health_code=$(echo "$health_check" | tail -n1)

if [ "$health_code" = "200" ] || [ "$health_code" = "404" ]; then
    print_success "Server is running on $BASE_URL"
else
    print_error "Server is not running or not accessible"
    print_info "请先启动服务器: npm start 或 npm run dev"
    exit 1
fi

# Run all test modules
print_header "RUNNING ALL SECURITY TESTS"

# Run authentication tests
bash "$TEST_DIR/test_auth.sh"

# Run category tests
bash "$TEST_DIR/test_category.sh"

# Run product tests
bash "$TEST_DIR/test_product.sh"

# Run order tests
bash "$TEST_DIR/test_order.sh"

# Run review tests
bash "$TEST_DIR/test_review.sh"

# Run user tests
bash "$TEST_DIR/test_user.sh"

# Run newsletter tests
bash "$TEST_DIR/test_newsletter.sh"

# Run security attack tests
bash "$TEST_DIR/test_security.sh"

print_header "TEST COMPLETED"
print_success "All security tests have been executed"
