#!/bin/bash

# ============================================
# Review Endpoints Tests
# ============================================

source "$(dirname "$0")/test_config.sh"

test_review_endpoints() {
    print_header "TESTING REVIEW ENDPOINTS"

    # 1. Get Product Reviews - Public
    print_info "1. Testing GET /reviews/product/:productId - Public"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/reviews/product/507f1f77bcf86cd799439011")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Get product reviews successful"
    else
        print_info "Get product reviews response with HTTP $http_code"
        echo "Response: $body"
    fi

    # 2. Get User Reviews - No Token - Security Test
    print_info "2. Testing GET /reviews/user - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/reviews/user")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 3. Create Review - No Token - Security Test
    print_info "3. Testing POST /reviews/product/:productId - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/reviews/product/507f1f77bcf86cd799439011" \
        -H "Content-Type: application/json" \
        -d '{
            "rating": 5,
            "comment": "Great product!"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 4. Create Review - With Token
    print_info "4. Testing POST /reviews/product/:productId - With Token"
    if [ -n "$TOKEN" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST \
            "${BASE_URL}/reviews/product/507f1f77bcf86cd799439011" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d '{
                "rating": 5,
                "comment": "Great product!"
            }')
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
            print_success "Review created successfully"
            REVIEW_ID=$(echo "$body" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
            echo "Response: $body"
        else
            print_info "Review creation response with HTTP $http_code"
            echo "Response: $body"
        fi
    else
        print_warning "No token available for test"
    fi

    # 5. Update Review - No Token - Security Test
    print_info "5. Testing PUT /reviews/:id - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X PUT \
        "${BASE_URL}/reviews/507f1f77bcf86cd799439011" \
        -H "Content-Type: application/json" \
        -d '{
            "rating": 4,
            "comment": "Updated review"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 6. Delete Review - No Token - Security Test
    print_info "6. Testing DELETE /reviews/:id - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X DELETE \
        "${BASE_URL}/reviews/507f1f77bcf86cd799439011")
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
    test_review_endpoints
fi
