#!/bin/bash

# ============================================
# Security Attack Tests
# ============================================

source "$(dirname "$0")/test_config.sh"

test_security_attacks() {
    print_header "TESTING SECURITY ATTACKS"

    # 1. NoSQL Injection Test
    print_info "1. Testing NoSQL Injection on /products/:id"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/products/507f1f77bcf86cd799439011%20OR%201%3D1")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "400" ] || [ "$http_code" = "404" ]; then
        print_success "NoSQL Injection blocked - Security working"
    else
        print_warning "NoSQL Injection might not be blocked with HTTP $http_code - POTENTIAL SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 2. Header Injection Test
    print_info "2. Testing Header Injection"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/products" \
        -H "X-Forwarded-For: <script>alert(1)</script>")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Header handled properly - Security working"
    else
        print_warning "Header injection response with HTTP $http_code"
        echo "Response: $body"
    fi

    # 3. Large Payload Test - DoS
    print_info "3. Testing Large Payload - DoS Protection"
    large_payload='{"data":"'$(printf 'A%.0s' {1..100000})'"}'
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/register" \
        -H "Content-Type: application/json" \
        -d "$large_payload")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "413" ] || [ "$http_code" = "400" ]; then
        print_success "Large payload rejected - DoS protection working"
    else
        print_warning "Large payload accepted with HTTP $http_code - POTENTIAL SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 4. IDOR Test - Accessing another user's order
    print_info "4. Testing IDOR - Accessing another user's order"
    if [ -n "$TOKEN" ]; then
        response=$(curl -s -w "\n%{http_code}" -X GET \
            "${BASE_URL}/orders/507f1f77bcf86cd799439011" \
            -H "Authorization: Bearer $TOKEN")
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "403" ] || [ "$http_code" = "404" ]; then
            print_success "IDOR prevented - Security working"
        else
            print_warning "IDOR might be possible with HTTP $http_code - POTENTIAL SECURITY ISSUE"
            echo "Response: $body"
        fi
    else
        print_warning "No token available for IDOR test"
    fi

    # 5. Parameter Tampering Test
    print_info "5. Testing Parameter Tampering on /orders/:id/status"
    if [ -n "$TOKEN" ]; then
        response=$(curl -s -w "\n%{http_code}" -X PUT \
            "${BASE_URL}/orders/507f1f77bcf86cd799439011/status" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d '{
                "status": "admin_only_status"
            }')
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "400" ] || [ "$http_code" = "403" ]; then
            print_success "Parameter tampering blocked - Security working"
        else
            print_warning "Parameter tampering might not be blocked with HTTP $http_code - POTENTIAL SECURITY ISSUE"
            echo "Response: $body"
        fi
    else
        print_warning "No token available for parameter tampering test"
    fi
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_security_attacks
fi
