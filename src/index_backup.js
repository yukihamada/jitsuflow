/**
 * JitsuFlow Cloudflare Workers API
 * ブラジリアン柔術トレーニング＆道場予約システム
 */

import { Router } from 'itty-router';
import { corsHeaders } from './middleware/cors';
import { authMiddleware, rateLimitMiddleware } from './middleware/auth_simple';
import { userRoutes } from './routes/users_test';
import { dojoRoutes } from './routes/dojo';
import { videoRoutes } from './routes/videos';
import { videoUploadRoutes } from './routes/video_upload';
import { paymentRoutes } from './routes/payments';
import { bookingRoutes } from './routes/bookings';
import { teamRoutes } from './routes/teams';
import { memberRoutes } from './routes/members';
import { dojoModeRoutes } from './routes/dojo_mode';
import { rentalRoutes } from './routes/rentals';
import { instructorRoutes } from './routes/instructor';
import { analyticsRoutes } from './routes/analytics';
import { studentInstructorRoutes } from './routes/student_instructor';
import { productRoutes } from './routes/products';
import { userRentalRoutes } from './routes/user_rentals';
import { handleDataInitialization } from './data/initializeData';
import { testRoutes } from './routes/test';

const router = Router();

// CORS preflight
router.options('*', () => new Response(null, { headers: corsHeaders }));

// Health check
router.get('/api/health', () => {
  return new Response(JSON.stringify({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    service: 'JitsuFlow API'
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
});

// Data initialization endpoint (development only)
router.post('/api/admin/initialize-data', authMiddleware, handleDataInitialization);

// Simple videos test endpoint
router.get('/api/videos', async (request) => {
  try {
    console.log('Videos endpoint called');
    
    const videos = await request.env.DB.prepare(
      'SELECT * FROM videos ORDER BY created_at DESC'
    ).all();
    
    return new Response(JSON.stringify({
      videos: videos.results || []
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Videos error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get videos',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Test routes (no auth)
router.get('/api/test', () => {
  return new Response(JSON.stringify({ message: 'Direct test route works' }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
});
// router.all('/api/test/*', testRoutes);

// API routes
// router.all('/api/users/*', authMiddleware, userRoutes);
router.post('/api/users/register', async (request) => {
  try {
    const body = await request.json();
    return new Response(JSON.stringify({
      message: 'Registration endpoint reached',
      data: body
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Registration error',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});
router.all('/api/dojo/*', authMiddleware, dojoRoutes);
// Videos handled above
router.all('/api/payments/*', authMiddleware, paymentRoutes);
router.all('/api/schedules/*', authMiddleware, bookingRoutes);
router.all('/api/bookings/*', authMiddleware, bookingRoutes);
router.all('/api/dojos/*', authMiddleware, teamRoutes);
router.all('/api/teams/*', authMiddleware, teamRoutes);
router.all('/api/affiliations/*', authMiddleware, teamRoutes);
router.all('/api/members/*', authMiddleware, memberRoutes);
router.all('/api/dojo-mode/*', authMiddleware, dojoModeRoutes);
router.all('/api/rentals/*', authMiddleware, rentalRoutes);
router.all('/api/rental-transactions/*', authMiddleware, rentalRoutes);
router.all('/api/sparring-videos/*', authMiddleware, dojoModeRoutes);
router.all('/api/instructors/*', authMiddleware, instructorRoutes);
router.all('/api/analytics/*', authMiddleware, analyticsRoutes);
router.all('/api/students/*', authMiddleware, studentInstructorRoutes);
router.all('/api/favorite-instructors/*', authMiddleware, studentInstructorRoutes);
router.all('/api/products/*', authMiddleware, productRoutes);
router.all('/api/cart/*', authMiddleware, productRoutes);
router.all('/api/orders/*', authMiddleware, productRoutes);
router.all('/api/rentals/*', authMiddleware, userRentalRoutes);

// 404 handler
router.all('*', () => new Response('Not Found', { 
  status: 404,
  headers: corsHeaders
}));

export default {
  async fetch(request, env, ctx) {
    try {
      // Add environment to request context
      request.env = env;
      request.ctx = ctx;
      
      // Apply rate limiting (disabled for debugging)
      // const rateLimitResponse = await rateLimitMiddleware(request);
      // if (rateLimitResponse) {
      //   return rateLimitResponse;
      // }
      
      // Handle request
      const response = await router.handle(request);
      
      // Add rate limit headers to response
      if (request.rateLimitInfo && response) {
        const newHeaders = new Headers(response.headers);
        newHeaders.set('X-RateLimit-Limit', request.rateLimitInfo.limit.toString());
        newHeaders.set('X-RateLimit-Remaining', request.rateLimitInfo.remaining.toString());
        newHeaders.set('X-RateLimit-Reset', request.rateLimitInfo.reset);
        
        return new Response(response.body, {
          status: response.status,
          statusText: response.statusText,
          headers: newHeaders
        });
      }
      
      return response;
    } catch (error) {
      console.error('Worker error:', error);
      
      return new Response(JSON.stringify({
        error: 'Internal Server Error',
        message: error.message
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
  }
};