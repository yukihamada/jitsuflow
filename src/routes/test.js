/**
 * Test routes for debugging
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';

const router = Router();

// Test endpoint
router.get('/api/test', async (request) => {
  return new Response(JSON.stringify({
    message: 'Test endpoint working',
    timestamp: new Date().toISOString(),
    env: request.env.ENVIRONMENT || 'unknown'
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
});

// Test database connection
router.get('/api/test/db', async (request) => {
  try {
    const result = await request.env.DB.prepare('SELECT COUNT(*) as count FROM users').first();
    return new Response(JSON.stringify({
      message: 'Database connection successful',
      userCount: result.count
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Database error',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Test simple registration (no crypto)
router.post('/api/test/register', async (request) => {
  try {
    const body = await request.json();
    return new Response(JSON.stringify({
      message: 'Request received',
      body: body,
      timestamp: new Date().toISOString()
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Parse error',
      message: error.message,
      type: error.constructor.name
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

export { router as testRoutes };