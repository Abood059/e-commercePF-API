#!/bin/bash

# ============================================
# Product Endpoints Tests
# ============================================

source "$(dirname "$0")/test_config.sh"

test_product_endpoints() {
    print_header "TESTING PRODUCT ENDPOINTS"

    # 1. Get All Products - Public
    print_info "1. Testing GET /products - Public"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/products")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Get all products successful"
        echo "Response: $body"
    else
        print_error "Failed with HTTP $http_code"
        echo "Response: $body"
    fi

    # 2. Get Paginated Products - Public
    print_info "2. Testing GET /products/paginated - Public"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/products/paginated?page=1&limit=10")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Get paginated products successful"
    else
        print_error "Failed with HTTP $http_code"
        echo "Response: $body"
    fi

    # 3. Get Brands - Public
    print_info "3. Testing GET /products/brands - Public"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/products/brands")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Get brands successful"
    else
        print_error "Failed with HTTP $http_code"
        echo "Response: $body"
    fi

    # 4. Get Product by Name - Public
    print_info "4. Testing GET /products/name/:name - Public"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/products/name/test-product")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "404" ]; then
        print_success "Get product by name response with HTTP $http_code"
    else
        print_error "Failed with HTTP $http_code"
        echo "Response: $body"
    fi

    # 5. Get Product by ID - Public
    print_info "5. Testing GET /products/:id - Public"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/products/507f1f77bcf86cd799439011")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "404" ]; then
        print_success "Get product by ID response with HTTP $http_code"
    else
        print_error "Failed with HTTP $http_code"
        echo "Response: $body"
    fi

    # 6. Create Product - No Token - Security Test
    print_info "6. Testing POST /products - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/products" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "Test Product",
            "description": "Test Description",
            "price": 99.99,
            "category": "507f1f77bcf86cd799439011",
            "brand": "Test Brand",
            "stock": 10
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 7. Create Product - User Token - Security Test
    print_info "7. Testing POST /products - User Token - Security Test"
    if [ -n "$TOKEN" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST \
            "${BASE_URL}/products" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d '{
                "name": "Test Product",
                "description": "Test Description",
                "price": 99.99,
                "category": "507f1f77bcf86cd799439011",
                "brand": "Test Brand",
                "stock": 10
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

    # 8. Create Product - Admin Token
    print_info "8. Testing POST /products - Admin Token"
    if [ -n "$ADMIN_TOKEN" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST \
            "${BASE_URL}/products" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $ADMIN_TOKEN" \
            -d '{
                "name": "Test Product",
                "description": "Test Description",
                "price": 99.99,
                "category": "507f1f77bcf86cd799439011",
                "brand": "Test Brand",
                "stock": 10
            }')
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
            print_success "Product created successfully"
            PRODUCT_ID=$(echo "$body" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
            echo "Response: $body"
        else
            print_error "Failed with HTTP $http_code"
            echo "Response: $body"
        fi
    else
        print_warning "No admin token available for test"
    fi

    # 9. Update Product - No Token - Security Test
    print_info "9. Testing PUT /products/:id - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X PUT \
        "${BASE_URL}/products/507f1f77bcf86cd799439011" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "Updated Product",
            "price": 149.99
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 10. Delete Product - No Token - Security Test
    print_info "10. Testing DELETE /products/:id - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X DELETE \
        "${BASE_URL}/products/507f1f77bcf86cd799439011")
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
    test_product_endpoints
fi
