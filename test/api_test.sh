#!/bin/bash

# ============================================
# API Security Testing Script
# E-Commerce Project - All Endpoints Test
# ============================================

# Configuration
BASE_URL="http://localhost:3000/api"
TOKEN=""
ADMIN_TOKEN=""
USER_ID=""
CATEGORY_ID=""
PRODUCT_ID=""
ORDER_ID=""
REVIEW_ID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ============================================
# AUTHENTICATION ENDPOINTS
# ============================================

test_auth_endpoints() {
    print_header "TESTING AUTHENTICATION ENDPOINTS"

    # 1. Register - Valid
    print_info "1. Testing POST /auth/register - Valid"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/register" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "testuser@example.com",
            "password": "SecurePass123!",
            "firstName": "Test",
            "lastName": "User"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
        print_success "Registration successful"
        echo "Response: $body"
    else
        print_error "Registration failed with HTTP $http_code"
        echo "Response: $body"
    fi

    # 2. Register - Weak Password - Security Test
    print_info "2. Testing POST /auth/register (Weak Password - Security Test)"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/register" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "weakpass@example.com",
            "password": "123",
            "firstName": "Weak",
            "lastName": "Pass"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "400" ]; then
        print_success "Weak password rejected - Security working"
    else
        print_warning "Weak password accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 3. Register - Invalid Email - Security Test
    print_info "3. Testing POST /auth/register (Invalid Email - Security Test)"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/register" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "invalid-email",
            "password": "SecurePass123!",
            "firstName": "Invalid",
            "lastName": "Email"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "400" ]; then
        print_success "Invalid email rejected - Security working"
    else
        print_warning "Invalid email accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 4. Register - SQL Injection Attempt - Security Test
    print_info "4. Testing POST /auth/register (SQL Injection - Security Test)"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/register" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "test@example.com",
            "password": "SecurePass123!",
            "firstName": "Test",
            "lastName": "'; DROP TABLE users; --"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "400" ] || [ "$http_code" = "422" ]; then
        print_success "SQL Injection attempt blocked - Security working"
    else
        print_warning "SQL Injection might not be blocked with HTTP $http_code - POTENTIAL SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 5. Register - XSS Attempt - Security Test
    print_info "5. Testing POST /auth/register (XSS - Security Test)"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/register" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "xss@example.com",
            "password": "SecurePass123!",
            "firstName": "<script>alert(1)</script>",
            "lastName": "XSS"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "400" ] || [ "$http_code" = "422" ]; then
        print_success "XSS attempt blocked - Security working"
    else
        print_warning "XSS might not be sanitized with HTTP $http_code - POTENTIAL SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 6. Login - Valid
    print_info "6. Testing POST /auth/login - Valid"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/login" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "testuser@example.com",
            "password": "SecurePass123!"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Login successful"
        TOKEN=$(echo "$body" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        echo "Response: $body"
    else
        print_error "Login failed with HTTP $http_code"
        echo "Response: $body"
    fi

    # 7. Login - Wrong Password - Security Test
    print_info "7. Testing POST /auth/login (Wrong Password - Security Test)"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/login" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "testuser@example.com",
            "password": "WrongPassword!"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Wrong password rejected - Security working"
    else
        print_warning "Wrong password response with HTTP $http_code"
        echo "Response: $body"
    fi

    # 8. Login - Non-existent User - Security Test
    print_info "8. Testing POST /auth/login (Non-existent User - Security Test)"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/login" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "nonexistent@example.com",
            "password": "SecurePass123!"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Non-existent user rejected - Security working"
    else
        print_warning "Non-existent user response with HTTP $http_code"
        echo "Response: $body"
    fi

    # 9. Login - Brute Force Protection - Rate Limit Test
    print_info "9. Testing POST /auth/login (Rate Limit - Security Test)"
    for i in {1..6}; do
        response=$(curl -s -w "\n%{http_code}" -X POST \
            "${BASE_URL}/auth/login" \
            -H "Content-Type: application/json" \
            -d '{
                "email": "testuser@example.com",
                "password": "WrongPassword!"
            }')
        http_code=$(echo "$response" | tail -n1)
        
        if [ "$http_code" = "429" ]; then
            print_success "Rate limit triggered after $i attempts - Security working"
            break
        fi
    done

    # 10. Google Login
    print_info "10. Testing POST /auth/google"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/google" \
        -H "Content-Type: application/json" \
        -d '{
            "idToken": "fake_google_token"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "400" ] || [ "$http_code" = "401" ]; then
        print_success "Invalid Google token rejected"
    else
        print_info "Google login response with HTTP $http_code"
        echo "Response: $body"
    fi

    # 11. Forgot Password
    print_info "11. Testing POST /auth/forgot-password"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/forgot-password" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "testuser@example.com"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Forgot password request processed"
    else
        print_info "Forgot password response with HTTP $http_code"
        echo "Response: $body"
    fi

    # 12. Forgot Password - Non-existent Email - Security Test
    print_info "12. Testing POST /auth/forgot-password (Non-existent Email - Security Test)"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/forgot-password" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "nonexistent@example.com"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    # Security: Should not reveal if email exists
    if [ "$http_code" = "200" ]; then
        print_success "Non-existent email not revealed - Security working"
    else
        print_warning "Response with HTTP $http_code might reveal email existence"
        echo "Response: $body"
    fi

    # 13. Reset Password
    print_info "13. Testing POST /auth/reset-password"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/reset-password" \
        -H "Content-Type: application/json" \
        -d '{
            "token": "fake_reset_token",
            "newPassword": "NewSecurePass123!"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "400" ] || [ "$http_code" = "401" ]; then
        print_success "Invalid reset token rejected"
    else
        print_info "Reset password response with HTTP $http_code"
        echo "Response: $body"
    fi

    # 14. Activate Account
    print_info "14. Testing GET /auth/activate/:token"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/auth/activate/fake_activation_token")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "400" ] || [ "$http_code" = "404" ]; then
        print_success "Invalid activation token rejected"
    else
        print_info "Activation response with HTTP $http_code"
        echo "Response: $body"
    fi
}

# ============================================
# CATEGORY ENDPOINTS
# ============================================

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

    # 4. Create Category (Admin - No Token) - Security Test
    print_info "4. Testing POST /categories (No Token - Security Test)"
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

    # 5. Create Category (Admin - User Token) - Security Test
    print_info "5. Testing POST /categories (User Token - Security Test)"
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

    # 6. Create Category (Admin - Admin Token)
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

    # 7. Update Category (Admin - No Token) - Security Test
    print_info "7. Testing PUT /categories/:id (No Token - Security Test)"
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

    # 8. Delete Category (Admin - No Token) - Security Test
    print_info "8. Testing DELETE /categories/:id (No Token - Security Test)"
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

# ============================================
# PRODUCT ENDPOINTS
# ============================================

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

    # 6. Create Product (Admin - No Token) - Security Test
    print_info "6. Testing POST /products (No Token - Security Test)"
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

    # 7. Create Product (Admin - User Token) - Security Test
    print_info "7. Testing POST /products (User Token - Security Test)"
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

    # 8. Create Product (Admin - Admin Token)
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

    # 9. Update Product (Admin - No Token) - Security Test
    print_info "9. Testing PUT /products/:id (No Token - Security Test)"
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

    # 10. Delete Product (Admin - No Token) - Security Test
    print_info "10. Testing DELETE /products/:id (No Token - Security Test)"
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

# ============================================
# ORDER ENDPOINTS
# ============================================

test_order_endpoints() {
    print_header "TESTING ORDER ENDPOINTS"

    # 1. Create Order - No Token - Security Test
    print_info "1. Testing POST /orders (No Token - Security Test)"
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

    # 2. Create Order (With Token)
    print_info "2. Testing POST /orders (With Token)"
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
    print_info "3. Testing GET /orders (No Token - Security Test)"
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
    print_info "4. Testing GET /orders/:id (No Token - Security Test)"
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

    # 5. Update Order Status (Admin - No Token) - Security Test
    print_info "5. Testing PUT /orders/:id/status (No Token - Security Test)"
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
    print_info "6. Testing PUT /orders/:id/status (User Token - Security Test)"
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

    # 7. Confirm Payment
    print_info "7. Testing POST /orders/confirm-payment"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/orders/confirm-payment" \
        -H "Content-Type: application/json" \
        -d '{
            "paymentIntentId": "pi_test123"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "400" ]; then
        print_success "Payment confirmation response with HTTP $http_code"
    else
        print_info "Payment confirmation response with HTTP $http_code"
        echo "Response: $body"
    fi

    # 8. Cancel Order - No Token - Security Test
    print_info "8. Testing DELETE /orders/:id (No Token - Security Test)"
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

# ============================================
# REVIEW ENDPOINTS
# ============================================

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
    print_info "2. Testing GET /reviews/user (No Token - Security Test)"
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
    print_info "3. Testing POST /reviews/product/:productId (No Token - Security Test)"
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

    # 4. Create Review (With Token)
    print_info "4. Testing POST /reviews/product/:productId (With Token)"
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
    print_info "5. Testing PUT /reviews/:id (No Token - Security Test)"
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
    print_info "6. Testing DELETE /reviews/:id (No Token - Security Test)"
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

# ============================================
# USER ENDPOINTS
# ============================================

test_user_endpoints() {
    print_header "TESTING USER ENDPOINTS"

    # 1. Get Current User - No Token - Security Test
    print_info "1. Testing GET /users/me (No Token - Security Test)"
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

    # 2. Get Current User (With Token)
    print_info "2. Testing GET /users/me (With Token)"
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
            print_error "Failed with HTTP $http_code"
            echo "Response: $body"
        fi
    else
        print_warning "No token available for test"
    fi

    # 3. Update User - No Token - Security Test
    print_info "3. Testing PUT /users/me (No Token - Security Test)"
    response=$(curl -s -w "\n%{http_code}" -X PUT \
        "${BASE_URL}/users/me" \
        -H "Content-Type: application/json" \
        -d '{
            "firstName": "Updated",
            "lastName": "Name"
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
    print_info "4. Testing DELETE /users/me (No Token - Security Test)"
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

    # 5. Subscribe Newsletter
    print_info "5. Testing POST /users/newsletter/subscribe"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/users/newsletter/subscribe" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "test@example.com"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Newsletter subscription successful"
    else
        print_info "Newsletter subscription response with HTTP $http_code"
        echo "Response: $body"
    fi

    # 6. Unsubscribe Newsletter
    print_info "6. Testing POST /users/newsletter/unsubscribe"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/users/newsletter/unsubscribe" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "test@example.com"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Newsletter unsubscription successful"
    else
        print_info "Newsletter unsubscription response with HTTP $http_code"
        echo "Response: $body"
    fi

    # 7. Send Newsletter - No Token - Security Test
    print_info "7. Testing POST /users/newsletter/send (No Token - Security Test)"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/users/newsletter/send" \
        -H "Content-Type: application/json" \
        -d '{
            "subject": "Test Newsletter",
            "content": "Test content"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi
}

# ============================================
# NEWSLETTER ENDPOINTS
# ============================================

test_newsletter_endpoints() {
    print_header "TESTING NEWSLETTER ENDPOINTS"

    # 1. Get All Subscribers (Admin - No Token) - Security Test
    print_info "1. Testing GET /newsletter/subscribers (No Token - Security Test)"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/newsletter/subscribers")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 2. Get All Subscribers - User Token - Security Test
    print_info "2. Testing GET /newsletter/subscribers (User Token - Security Test)"
    if [ -n "$TOKEN" ]; then
        response=$(curl -s -w "\n%{http_code}" -X GET \
            "${BASE_URL}/newsletter/subscribers" \
            -H "Authorization: Bearer $TOKEN")
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

    # 3. Subscribe - Public
    print_info "3. Testing POST /newsletter/subscribe - Public"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/newsletter/subscribe" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "newsletter@example.com"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        print_success "Newsletter subscription successful"
    else
        print_info "Newsletter subscription response with HTTP $http_code"
        echo "Response: $body"
    fi

    # 4. Unsubscribe - Public
    print_info "4. Testing POST /newsletter/unsubscribe - Public"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/newsletter/unsubscribe" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "newsletter@example.com"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Newsletter unsubscription successful"
    else
        print_info "Newsletter unsubscription response with HTTP $http_code"
        echo "Response: $body"
    fi

    # 5. Send Bulk Newsletter (Admin - No Token) - Security Test
    print_info "5. Testing POST /newsletter/send-bulk (No Token - Security Test)"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/newsletter/send-bulk" \
        -H "Content-Type: application/json" \
        -d '{
            "subject": "Bulk Test",
            "content": "Bulk content"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 6. Send Bulk Newsletter - User Token - Security Test
    print_info "6. Testing POST /newsletter/send-bulk (User Token - Security Test)"
    if [ -n "$TOKEN" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST \
            "${BASE_URL}/newsletter/send-bulk" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d '{
                "subject": "Bulk Test",
                "content": "Bulk content"
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
}

# ============================================
# SECURITY TESTS
# ============================================

test_security_attacks() {
    print_header "TESTING SECURITY ATTACKS"

    # 1. CSRF Test
    print_info "1. Testing CSRF Protection"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/login" \
        -H "Content-Type: application/json" \
        -H "Origin: http://evil.com" \
        -d '{
            "email": "testuser@example.com",
            "password": "SecurePass123!"
        }')
    http_code=$(echo "$response" | tail -n1)
    
    print_info "CSRF test response with HTTP $http_code (Check CORS headers)"

    # 2. Header Injection Test
    print_info "2. Testing Header Injection"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/products" \
        -H "X-Forwarded-For: <script>alert(1)</script>")
    http_code=$(echo "$response" | tail -n1)
    
    print_info "Header injection test response with HTTP $http_code"

    # 3. Large Payload Test (DoS)
    print_info "3. Testing Large Payload (DoS Protection)"
    large_payload=$(python3 -c "print('A'*10000)" 2>/dev/null || echo "A"*10000)
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"test@example.com\",
            \"password\": \"SecurePass123!\",
            \"firstName\": \"$large_payload\",
            \"lastName\": \"Test\"
        }")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "413" ] || [ "$http_code" = "400" ]; then
        print_success "Large payload rejected (DoS protection working)"
    else
        print_warning "Large payload accepted with HTTP $http_code (POTENTIAL DoS ISSUE)"
    fi

    # 4. Malformed JSON Test
    print_info "4. Testing Malformed JSON"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/register" \
        -H "Content-Type: application/json" \
        -d '{"invalid": json}')
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ]; then
        print_success "Malformed JSON rejected"
    else
        print_warning "Malformed JSON response with HTTP $http_code"
    fi

    # 5. Missing Content-Type Test
    print_info "5. Testing Missing Content-Type"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/register" \
        -d '{
            "email": "test@example.com",
            "password": "SecurePass123!"
        }')
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ] || [ "$http_code" = "415" ]; then
        print_success "Missing Content-Type rejected"
    else
        print_warning "Missing Content-Type response with HTTP $http_code"
    fi

    # 6. Path Traversal Test
    print_info "6. Testing Path Traversal"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/products/../../../etc/passwd")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ] || [ "$http_code" = "404" ]; then
        print_success "Path traversal attempt blocked"
    else
        print_warning "Path traversal response with HTTP $http_code - POTENTIAL SECURITY ISSUE"
    fi

    # 7. Command Injection Test
    print_info "7. Testing Command Injection"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/register" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "test@example.com",
            "password": "SecurePass123!",
            "firstName": "Test",
            "lastName": "User; ls -la"
        }')
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ] || [ "$http_code" = "422" ]; then
        print_success "Command injection attempt blocked"
    else
        print_warning "Command injection response with HTTP $http_code - POTENTIAL SECURITY ISSUE"
    fi

    # 8. NoSQL Injection Test
    print_info "8. Testing NoSQL Injection"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/auth/login" \
        -H "Content-Type: application/json" \
        -d '{
            "email": {"$ne": null},
            "password": {"$ne": null}
        }')
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ] || [ "$http_code" = "401" ]; then
        print_success "NoSQL injection attempt blocked"
    else
        print_warning "NoSQL injection might not be blocked with HTTP $http_code - POTENTIAL SECURITY ISSUE"
    fi

    # 9. JWT Manipulation Test
    print_info "9. Testing JWT Manipulation"
    fake_token="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.fake.signature"
    response=$(curl -s -w "\n%{http_code}" -X GET \
        "${BASE_URL}/users/me" \
        -H "Authorization: Bearer $fake_token")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "401" ]; then
        print_success "Fake JWT rejected - Security working"
    else
        print_warning "Fake JWT accepted with HTTP $http_code - SECURITY ISSUE"
    fi

    # 10. Bypass Authorization Test (IDOR)
    print_info "10. Testing IDOR (Insecure Direct Object Reference)"
    if [ -n "$TOKEN" ]; then
        # Try to access another user's order
        response=$(curl -s -w "\n%{http_code}" -X GET \
            "${BASE_URL}/orders/507f1f77bcf86cd799439011" \
            -H "Authorization: Bearer $TOKEN")
        http_code=$(echo "$response" | tail -n1)
        
        if [ "$http_code" = "403" ] || [ "$http_code" = "404" ]; then
            print_success "IDOR protection working (Access denied)"
        else
            print_warning "IDOR might be possible with HTTP $http_code - POTENTIAL SECURITY ISSUE"
        fi
    else
        print_warning "No token available for IDOR test"
    fi
}

# ============================================
# MAIN EXECUTION
# ============================================

print_header "E-COMMERCE API SECURITY TEST SUITE"
print_info "Base URL: $BASE_URL"
print_info "Starting tests...\n"

# Check if server is running
print_info "Checking if server is running..."
health_check=$(curl -s -w "\n%{http_code}" -X GET "${BASE_URL}/products" 2>/dev/null)
health_code=$(echo "$health_check" | tail -n1)

if [ "$health_code" != "200" ] && [ "$health_code" != "404" ]; then
    print_error "Server is not running or not accessible at $BASE_URL"
    print_info "Please start the server first with: npm start or npm run dev"
    exit 1
fi

print_success "Server is running"

# Run all tests
test_auth_endpoints
test_category_endpoints
test_product_endpoints
test_order_endpoints
test_review_endpoints
test_user_endpoints
test_newsletter_endpoints
test_security_attacks

print_header "TEST SUITE COMPLETED"
print_info "Review the results above for any security issues or failures"
