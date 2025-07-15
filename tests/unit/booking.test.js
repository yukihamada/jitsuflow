import { describe, it, expect } from 'vitest';

describe('Booking Validation', () => {
  it('should validate booking time format', () => {
    const validTime = '14:00';
    const invalidTime = '25:00';
    
    const isValidTime = (time) => {
      const [hours, minutes] = time.split(':').map(Number);
      return hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59;
    };
    
    expect(isValidTime(validTime)).toBe(true);
    expect(isValidTime(invalidTime)).toBe(false);
  });

  it('should validate booking date', () => {
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    
    expect(tomorrow >= today).toBe(true);
    expect(yesterday >= today).toBe(false);
  });
});