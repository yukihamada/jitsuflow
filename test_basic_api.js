#!/usr/bin/env node

const API_URL = 'https://api.jitsuflow.app';

async function testBasicEndpoints() {
  console.log('Testing JitsuFlow API basic endpoints...\n');
  
  // Test 1: OPTIONS request (should always work)
  console.log('1. Testing OPTIONS request:');
  const optionsResponse = await fetch(`${API_URL}/api/auth/register`, {
    method: 'OPTIONS'
  });
  console.log(`   Status: ${optionsResponse.status}`);
  console.log(`   CORS Headers: ${optionsResponse.headers.get('Access-Control-Allow-Methods')}`);
  
  // Test 2: Registration endpoint
  console.log('\n2. Testing Registration:');
  const registerResponse = await fetch(`${API_URL}/api/auth/register`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email: `test_${Date.now()}@example.com`,
      password: 'TestPassword123!',
      name: 'Test User'
    })
  });
  console.log(`   Status: ${registerResponse.status}`);
  const registerText = await registerResponse.text();
  console.log(`   Response: ${registerText}`);
  
  // Test 3: Login endpoint
  console.log('\n3. Testing Login:');
  const loginResponse = await fetch(`${API_URL}/api/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email: 'admin@jitsuflow.app',
      password: 'admin123'
    })
  });
  console.log(`   Status: ${loginResponse.status}`);
  const loginText = await loginResponse.text();
  console.log(`   Response: ${loginText}`);
  
  // Test 4: Public endpoint (should work without auth)
  console.log('\n4. Testing root endpoint:');
  const rootResponse = await fetch(`${API_URL}/`);
  console.log(`   Status: ${rootResponse.status}`);
  const rootText = await rootResponse.text();
  console.log(`   Response: ${rootText}`);
}

testBasicEndpoints().catch(console.error);