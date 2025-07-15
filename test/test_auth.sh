#!/bin/bash

API_URL="https://api.jitsuflow.app/api"
TEST_EMAIL="test$(date +%s)@example.com"
TEST_PASS="testpass123"

echo "🔍 Testing JitsuFlow Authentication..."
echo "=================================="

# Test 1: Register
echo -e "\n1. Testing Registration..."
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/users/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASS\",\"name\":\"Test User\"}")

echo "Response: $REGISTER_RESPONSE"

# Extract token if successful
TOKEN=$(echo $REGISTER_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
  echo "✅ Registration successful! Token received."
else
  echo "❌ Registration failed!"
fi

# Test 2: Login
echo -e "\n2. Testing Login..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/users/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASS\"}")

echo "Response: $LOGIN_RESPONSE"

LOGIN_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -n "$LOGIN_TOKEN" ]; then
  echo "✅ Login successful! Token received."
  TOKEN=$LOGIN_TOKEN
else
  echo "❌ Login failed!"
fi

# Test 3: Access protected endpoint
echo -e "\n3. Testing Protected Endpoint (Products)..."
if [ -n "$TOKEN" ]; then
  PRODUCTS_RESPONSE=$(curl -s -X GET "$API_URL/products" \
    -H "Authorization: Bearer $TOKEN")
  
  echo "Response: $PRODUCTS_RESPONSE" | head -c 200
  echo "..."
  
  if echo "$PRODUCTS_RESPONSE" | grep -q "products"; then
    echo "✅ Protected endpoint accessed successfully!"
  else
    echo "❌ Failed to access protected endpoint!"
  fi
else
  echo "⚠️  No token available, skipping protected endpoint test."
fi

echo -e "\n=================================="
echo "Test completed!"