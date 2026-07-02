#!/bin/bash

# ============================================
# Order Endpoints Tests
# ============================================

source "$(dirname "$0")/test_config.sh"

test_order_endpoints() {
    print_header "TESTING ORDER ENDPOINTS"

    # 1. Create Order - No Token - Security Test
    print_info "1. Testing POST /orders - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/orders" \
        -H "Content-Type: application/json" \
        -d '{
            "products": [
                {
                    "product": "507f1f77bcf86cd799439011",
                    "quantity": 2
                }
            ],
            "shippingAddress": {
                "street": "123 Test St",
                "city": "Test City",
                "zipCode": "12345",
                "country": "Test Country"
            }
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 2. Create Order - With Token
    print_info "2. Testing POST /orders - With Token"
    if [ -n "$TOKEN" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST \
            "${BASE_URL}/orders" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d '{
                "products": [
                    {
                        "product": "507f1f77bcf86cd799439011",
                        "quantity": 2
                    }
                ],
                "shippingAddress": {
                    "street": "123 Test St",
                    "city": "Test City",
                    "zipCode": "12345",
                    "country": "Test Country"
                }
            }')
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
            print_success "Order created successfully"
            ORDER_ID=$(echo "$body" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
            echo "Response: $body"
        else
            print_info "Order creation response with HTTP $http_code"
            echo "Response: $body"
        fi
    else
        print_warning "No token available for test"
    fi

    # 3. Get User Orders - No Token - Security Test
    print_info "3. Testing GET /orders - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/orders")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 4. Get Order by ID - No Token - Security Test
    print_info "4. Testing GET /orders/:id - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/orders/507f1f77bcf86cd799439011")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 5. Update Order Status - No Token - Security Test
    print_info "5. Testing PUT /orders/:id/status - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X PUT \
        "${BASE_URL}/orders/507f1f77bcf86cd799439011/status" \
        -H "Content-Type: application/json" \
        -d '{
            "status": "shipped"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 6. Update Order Status - User Token - Security Test
    print_info "6. Testing PUT /orders/:id/status - User Token - Security Test"
    if [ -n "$TOKEN" ]; then
        response=$(curl -s -w "\n%{http_code}" -X PUT \
            "${BASE_URL}/orders/507f1f77bcf86cd799439011/status" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d '{
                "status": "shipped"
            }')
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "403" ]; then
            print_success "Non-admin user rejected - Security working"
        else
            print_warning "Non-admin user accepted with HTTP $http_code - SECURITY ISSUE"
            echo "Response: $body"
        fi
    else
        print_warning "No token available for test"
    fi

    # 7. Confirm Payment - No Token - Security Test
    print_info "7. Testing POST /orders/confirm-payment - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/orders/confirm-payment" \
        -H "Content-Type: application/json" \
        -d '{
            "paymentIntentId": "pi_test123"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized payment confirmation rejected - Security working"
    else
        print_warning "Unauthorized payment accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 8. Cancel Order - No Token - Security Test
    print_info "8. Testing DELETE /orders/:id - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X DELETE \
        "${BASE_URL}/orders/507f1f77bcf86cd799439011")
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
    test_order_endpoints
fi
