#!/bin/bash

# ============================================
# Authentication Endpoints Tests
# ============================================

source "$(dirname "$0")/test_config.sh"

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
    print_info "2. Testing POST /auth/register - Weak Password - Security Test"
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
    print_info "3. Testing POST /auth/register - Invalid Email - Security Test"
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
    print_info "4. Testing POST /auth/register - SQL Injection - Security Test"
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
    print_info "5. Testing POST /auth/register - XSS - Security Test"
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
    print_info "7. Testing POST /auth/login - Wrong Password - Security Test"
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
    print_info "8. Testing POST /auth/login - Non-existent User - Security Test"
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
    print_info "9. Testing POST /auth/login - Rate Limit - Security Test"
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
    print_info "12. Testing POST /auth/forgot-password - Non-existent Email - Security Test"
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

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_auth_endpoints
fi
