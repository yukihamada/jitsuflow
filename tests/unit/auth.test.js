import { describe, it, expect } from 'vitest';

describe('Authentication', () => {
  it('should validate email format', () => {
    const validEmail = 'test@example.com';
    const invalidEmail = 'invalid-email';
    
    expect(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(validEmail)).toBe(true);
    expect(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(invalidEmail)).toBe(false);
  });

  it('should validate phone format', () => {
    const validPhone = '+81-90-1234-5678';
    const invalidPhone = 'abc123';
    
    expect(/^[\d\s\-+()]+$/.test(validPhone)).toBe(true);
    expect(/^[\d\s\-+()]+$/.test(invalidPhone)).toBe(false);
  });
});