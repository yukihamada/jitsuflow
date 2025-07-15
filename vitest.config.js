import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'tests/',
        'migrations/',
        'admin-dashboard/'
      ]
    },
    testTimeout: 30000,
    hookTimeout: 30000
  }
});