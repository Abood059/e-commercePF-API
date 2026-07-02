#!/bin/bash

# ============================================
# Category Endpoints Tests
# ============================================

source "$(dirname "$0")/test_config.sh"

test_category_endpoints() {
    print_header "TESTING CATEGORY ENDPOINTS"

    # 1. Get All Categories - Public
    print_info "1. Testing GET /categories - Public"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/categories")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Get all categories successful"
        echo "Response: $body"
    else
        print_error "Failed with HTTP $http_code"
        echo "Response: $body"
    fi

    # 2. Get Category by ID - Public
    print_info "2. Testing GET /categories/:id - Public"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/categories/507f1f77bcf86cd799439011")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "404" ]; then
        print_success "Get category by ID response with HTTP $http_code"
    else
        print_error "Failed with HTTP $http_code"
        echo "Response: $body"
    fi

    # 3. Get Category with Products - Public
    print_info "3. Testing GET /categories/:id/products - Public"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/categories/507f1f77bcf86cd799439011/products")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "404" ]; then
        print_success "Get category with products response with HTTP $http_code"
    else
        print_error "Failed with HTTP $http_code"
        echo "Response: $body"
    fi

    # 4. Create Category - No Token - Security Test
    print_info "4. Testing POST /categories - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/categories" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "Test Category",
            "description": "Test Description"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 5. Create Category - User Token - Security Test
    print_info "5. Testing POST /categories - User Token - Security Test"
    if [ -n "$TOKEN" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST \
            "${BASE_URL}/categories" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d '{
                "name": "Test Category",
                "description": "Test Description"
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

    # 6. Create Category - Admin Token
    print_info "6. Testing POST /categories - Admin Token"
    if [ -n "$ADMIN_TOKEN" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST \
            "${BASE_URL}/categories" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $ADMIN_TOKEN" \
            -d '{
                "name": "Test Category",
                "description": "Test Description"
            }')
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
            print_success "Category created successfully"
            CATEGORY_ID=$(echo "$body" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
            echo "Response: $body"
        else
            print_error "Failed with HTTP $http_code"
            echo "Response: $body"
        fi
    else
        print_warning "No admin token available for test"
    fi

    # 7. Update Category - No Token - Security Test
    print_info "7. Testing PUT /categories/:id - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X PUT \
        "${BASE_URL}/categories/507f1f77bcf86cd799439011" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "Updated Category",
            "description": "Updated Description"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 8. Delete Category - No Token - Security Test
    print_info "8. Testing DELETE /categories/:id - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X DELETE \
        "${BASE_URL}/categories/507f1f77bcf86cd799439011")
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
    test_category_endpoints
fi
