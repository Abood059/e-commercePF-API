#!/bin/bash

# ============================================
# Newsletter Endpoints Tests
# ============================================

source "$(dirname "$0")/test_config.sh"

test_newsletter_endpoints() {
    print_header "TESTING NEWSLETTER ENDPOINTS"

    # 1. Get All Subscribers - No Token - Security Test
    print_info "1. Testing GET /newsletter/subscribers - No Token - Security Test"
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

    # 2. Subscribe - Public
    print_info "2. Testing POST /newsletter/subscribe - Public"
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
        echo "Response: $body"
    else
        print_info "Newsletter subscription response with HTTP $http_code"
        echo "Response: $body"
    fi

    # 3. Unsubscribe - Public
    print_info "3. Testing POST /newsletter/unsubscribe - Public"
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

    # 4. Send Bulk Newsletter - No Token - Security Test
    print_info "4. Testing POST /newsletter/send-bulk - No Token - Security Test"
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "${BASE_URL}/newsletter/send-bulk" \
        -H "Content-Type: application/json" \
        -d '{
            "subject": "Test Newsletter",
            "body": "Test body"
        }')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ]; then
        print_success "Unauthorized request rejected - Security working"
    else
        print_warning "Unauthorized request accepted with HTTP $http_code - SECURITY ISSUE"
        echo "Response: $body"
    fi

    # 5. Send Bulk Newsletter - User Token - Security Test
    print_info "5. Testing POST /newsletter/send-bulk - User Token - Security Test"
    if [ -n "$TOKEN" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST \
            "${BASE_URL}/newsletter/send-bulk" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d '{
                "subject": "Test Newsletter",
                "body": "Test body"
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

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_newsletter_endpoints
fi
