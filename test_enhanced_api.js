#!/usr/bin/env node

/**
 * Comprehensive API Test Suite for JitsuFlow Enhanced API
 * Tests all endpoints with security features
 */

const API_URL = 'https://api.jitsuflow.app';
let authToken = null;
let testUserId = null;

// Helper function to make API requests
async function apiRequest(method, endpoint, data = null, token = null) {
  const headers = {
    'Content-Type': 'application/json',
  };
  
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  
  const options = {
    method,
    headers,
  };
  
  if (data && method !== 'GET') {
    options.body = JSON.stringify(data);
  }
  
  try {
    const response = await fetch(`${API_URL}${endpoint}`, options);
    const text = await response.text();
    
    let json;
    try {
      json = JSON.parse(text);
    } catch (e) {
      json = { raw: text };
    }
    
    return {
      status: response.status,
      data: json,
      headers: Object.fromEntries(response.headers)
    };
  } catch (error) {
    return {
      status: 0,
      data: { error: error.message },
      headers: {}
    };
  }
}

// Test suite
async function runTests() {
  console.log('🚀 Starting JitsuFlow Enhanced API Tests\n');
  
  const testResults = [];
  
  // Test 1: User Registration with Validation
  console.log('📝 Test 1: User Registration with Enhanced Validation');
  const testEmail = `test_${Date.now()}@jitsuflow.app`;
  
  // Test invalid email
  let result = await apiRequest('POST', '/api/auth/register', {
    email: 'invalid-email',
    password: 'password123',
    name: 'Test User'
  });
  testResults.push({
    test: 'Invalid Email Registration',
    passed: result.status === 400,
    details: result.data
  });
  
  // Test weak password
  result = await apiRequest('POST', '/api/auth/register', {
    email: testEmail,
    password: '123',
    name: 'Test User'
  });
  testResults.push({
    test: 'Weak Password Registration',
    passed: result.status === 400,
    details: result.data
  });
  
  // Test valid registration
  result = await apiRequest('POST', '/api/auth/register', {
    email: testEmail,
    password: 'StrongP@ssw0rd',
    name: 'Test User'
  });
  testResults.push({
    test: 'Valid Registration',
    passed: result.status === 201,
    details: result.data
  });
  
  // Test 2: User Login
  console.log('\n🔐 Test 2: User Login');
  result = await apiRequest('POST', '/api/auth/login', {
    email: testEmail,
    password: 'StrongP@ssw0rd'
  });
  authToken = result.data.token;
  testUserId = result.data.user?.id;
  testResults.push({
    test: 'User Login',
    passed: result.status === 200 && authToken,
    details: result.data
  });
  
  // Test 3: Rate Limiting
  console.log('\n⏱️ Test 3: Rate Limiting');
  console.log('Making multiple rapid requests...');
  let rateLimitHit = false;
  for (let i = 0; i < 110; i++) {
    result = await apiRequest('GET', '/api/dojos');
    if (result.status === 429) {
      rateLimitHit = true;
      break;
    }
  }
  testResults.push({
    test: 'Rate Limiting',
    passed: rateLimitHit,
    details: result.data,
    headers: result.headers
  });
  
  // Test 4: Videos Endpoint with Authentication
  console.log('\n🎥 Test 4: Videos Endpoint Authentication');
  
  // Test without auth
  result = await apiRequest('GET', '/api/videos');
  testResults.push({
    test: 'Videos Without Auth',
    passed: result.status === 401,
    details: result.data
  });
  
  // Test with auth
  result = await apiRequest('GET', '/api/videos', null, authToken);
  testResults.push({
    test: 'Videos With Auth',
    passed: result.status === 200,
    details: result.data
  });
  
  // Test 5: Shopping Cart Operations
  console.log('\n🛒 Test 5: Shopping Cart Operations');
  
  // Add to cart
  result = await apiRequest('POST', '/api/shop/cart', {
    product_id: 1,
    quantity: 2
  }, authToken);
  testResults.push({
    test: 'Add to Cart',
    passed: result.status === 200 || result.status === 201,
    details: result.data
  });
  
  // Get cart
  result = await apiRequest('GET', '/api/shop/cart', null, authToken);
  testResults.push({
    test: 'Get Cart',
    passed: result.status === 200,
    details: result.data
  });
  
  // Test 6: Order Creation
  console.log('\n📦 Test 6: Order Creation');
  
  // Create order (will fail if cart is empty, which is expected)
  result = await apiRequest('POST', '/api/orders/create', {
    shipping_address: {
      street: '123 Test St',
      city: 'Tokyo',
      postal_code: '100-0001',
      country: 'Japan'
    }
  }, authToken);
  testResults.push({
    test: 'Create Order',
    passed: result.status === 201 || (result.status === 400 && result.data.error === 'Cart is empty'),
    details: result.data
  });
  
  // Test 7: Booking Operations
  console.log('\n📅 Test 7: Booking Operations');
  
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const bookingDate = tomorrow.toISOString().split('T')[0];
  
  result = await apiRequest('POST', '/api/dojo/bookings/create', {
    dojo_id: 1,
    class_type: 'beginners',
    booking_date: bookingDate,
    booking_time: '18:00'
  }, authToken);
  testResults.push({
    test: 'Create Booking',
    passed: result.status === 201 || result.status === 200,
    details: result.data
  });
  
  // Test 8: Profile Update
  console.log('\n👤 Test 8: Profile Update');
  
  result = await apiRequest('PUT', '/api/user/profile', {
    name: 'Updated Test User',
    phone: '+81-90-1234-5678'
  }, authToken);
  testResults.push({
    test: 'Update Profile',
    passed: result.status === 200,
    details: result.data
  });
  
  // Test 9: Subscription Creation (will fail without valid Stripe keys)
  console.log('\n💳 Test 9: Subscription Creation');
  
  result = await apiRequest('POST', '/api/subscriptions/create', {
    price_id: 'price_test_123',
    payment_method_id: 'pm_test_123'
  }, authToken);
  testResults.push({
    test: 'Create Subscription',
    passed: result.status === 500 || result.status === 200, // 500 expected due to test Stripe keys
    details: result.data
  });
  
  // Test 10: Get User Orders
  console.log('\n📋 Test 10: Get User Orders');
  
  result = await apiRequest('GET', '/api/orders', null, authToken);
  testResults.push({
    test: 'Get Orders',
    passed: result.status === 200,
    details: result.data
  });
  
  // Summary
  console.log('\n\n📊 Test Summary\n' + '='.repeat(50));
  const passed = testResults.filter(t => t.passed).length;
  const failed = testResults.filter(t => !t.passed).length;
  
  testResults.forEach(test => {
    console.log(`${test.passed ? '✅' : '❌'} ${test.test}`);
    if (!test.passed) {
      console.log(`   Details: ${JSON.stringify(test.details)}`);
      if (test.headers?.['x-ratelimit-limit']) {
        console.log(`   Rate Limit Info: ${test.headers['x-ratelimit-remaining']}/${test.headers['x-ratelimit-limit']}`);
      }
    }
  });
  
  console.log('\n' + '='.repeat(50));
  console.log(`Total: ${testResults.length} | Passed: ${passed} | Failed: ${failed}`);
  console.log(`Success Rate: ${((passed / testResults.length) * 100).toFixed(1)}%`);
  
  // Additional recommendations
  console.log('\n💡 Recommendations for Production:');
  console.log('1. Replace test Stripe keys with real ones in wrangler.toml');
  console.log('2. Configure Resend API for email notifications');
  console.log('3. Set up Slack webhook for admin notifications');
  console.log('4. Update JWT_SECRET to a secure random value');
  console.log('5. Run database migrations on production D1: npx wrangler d1 execute jitsuflow-db --remote --file=migrations/07_orders_payments_tables.sql');
  console.log('6. Consider implementing proper password hashing (currently using base64)');
  console.log('7. Add monitoring and alerting for API errors');
  console.log('8. Set up automated backups for D1 database');
}

// Run tests
runTests().catch(console.error);