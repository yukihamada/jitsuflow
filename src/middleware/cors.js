/**
 * CORS middleware for JitsuFlow API
 */

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
  'Access-Control-Max-Age': '86400'
};

export function corsMiddleware(request, _response) {
  const origin = request.headers.get('Origin');

  // Allow specific origins in production
  const allowedOrigins = [
    'https://jitsuflow.app',
    'https://www.jitsuflow.app',
    'http://localhost:3000',
    'http://localhost:8080',
    'http://localhost:8000',
    'http://localhost:5000',
    'http://localhost:5001',
    'http://localhost:5002'
  ];

  if (origin && allowedOrigins.includes(origin)) {
    return {
      ...corsHeaders,
      'Access-Control-Allow-Origin': origin
    };
  }

  return corsHeaders;
}
