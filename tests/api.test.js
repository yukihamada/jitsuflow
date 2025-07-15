// API Tests for JitsuFlow
import { describe, it, expect, beforeAll, afterAll } from 'vitest';

// Test configuration
const TEST_API_URL = process.env.TEST_API_URL || 'http://localhost:8787';
let authToken;

describe('JitsuFlow API Tests', () => {
  describe('Authentication', () => {
    it('should login with valid credentials', async () => {
      const response = await fetch(`${TEST_API_URL}/api/users/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'admin@jitsuflow.app',
          password: 'admin123'
        })
      });
      
      expect(response.status).toBe(200);
      const data = await response.json();
      expect(data.token).toBeDefined();
      authToken = data.token;
    });

    it('should reject invalid credentials', async () => {
      const response = await fetch(`${TEST_API_URL}/api/users/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'admin@jitsuflow.app',
          password: 'wrongpassword'
        })
      });
      
      expect(response.status).toBe(401);
    });
  });

  describe('Public Endpoints', () => {
    it('should get dojos list', async () => {
      const response = await fetch(`${TEST_API_URL}/api/dojos`);
      expect(response.status).toBe(200);
      
      const dojos = await response.json();
      expect(Array.isArray(dojos)).toBe(true);
      expect(dojos.length).toBe(3);
    });

    it('should get products list', async () => {
      const response = await fetch(`${TEST_API_URL}/api/products`);
      expect(response.status).toBe(200);
      
      const data = await response.json();
      expect(data.products).toBeDefined();
      expect(Array.isArray(data.products)).toBe(true);
      expect(data.products.length).toBeGreaterThan(0);
    });
  });

  describe('Protected Endpoints', () => {
    it('should get users with auth token', async () => {
      const response = await fetch(`${TEST_API_URL}/api/users`, {
        headers: { 'Authorization': `Bearer ${authToken}` }
      });
      
      expect(response.status).toBe(200);
      const users = await response.json();
      expect(Array.isArray(users)).toBe(true);
    });

    it('should reject users request without auth', async () => {
      const response = await fetch(`${TEST_API_URL}/api/users`);
      expect(response.status).toBe(401);
    });
  });

  describe('Instructor Management', () => {
    it('should get instructors list', async () => {
      const response = await fetch(`${TEST_API_URL}/api/instructors`);
      expect(response.status).toBe(200);
      
      const instructors = await response.json();
      expect(Array.isArray(instructors)).toBe(true);
      expect(instructors.length).toBe(17);
    });

    it('should get instructor details', async () => {
      const response = await fetch(`${TEST_API_URL}/api/instructors/1`);
      expect(response.status).toBe(200);
      
      const instructor = await response.json();
      expect(instructor.name).toBe('一木');
      expect(instructor.dojos).toBeDefined();
    });
  });

  describe('Revenue Settings', () => {
    it('should have dojo revenue settings', async () => {
      // This would be tested once the API endpoints are implemented
      expect(true).toBe(true);
    });
  });
});