#!/bin/bash

# ============================================
# User Endpoints Tests
# ============================================

source "$(dirname "$0")/test_config.sh"

test_user_endpoints() {
    print_header "TESTING USER ENDPOINTS"

    # 1. Get Current User - No Token - Security Test
    print_info "1. Testing GET /users/me - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/users/me")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 2. Get Current User - With Token
    print_info "2. Testing GET /users/me - With Token"
    if [ -n "$TOKEN" ]; then
        response=$(curl -s -w "\n%{http_code}" -X GET \
            "${BASE_URL}/users/me" \
            -H "Authorization: Bearer $TOKEN")
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "200" ]; then
            print_success "Get current user successful"
            USER_ID=$(echo "$body" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
            echo "Response: $body"
        else
            print_info "Get current user response with HTTP $http_code"
            echo "Response: $body"
        fi
    else
        print_warning "No token available for test"
    fi

    # 3. Update User - No Token - Security Test
    print_info "3. Testing PUT /users/me - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X PUT \
        "${BASE_URL}/users/me" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "Updated Name"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 4. Delete User - No Token - Security Test
    print_info "4. Testing DELETE /users/me - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X DELETE \
        "${BASE_URL}/users/me")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_user_endpoints
fi
