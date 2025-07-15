/**
 * Dojo booking routes for JitsuFlow API
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';

const router = Router();

// Get all dojo bookings
router.get('/api/dojo/bookings', async (request) => {
  try {
    const bookings = await request.env.DB.prepare(
      'SELECT * FROM bookings WHERE user_id = ? ORDER BY booking_date DESC'
    ).bind(request.user.userId).all();

    return new Response(JSON.stringify({
      bookings: bookings.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get bookings error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get bookings',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Create new booking
router.post('/api/dojo/bookings', async (request) => {
  try {
    const { dojo_id, class_type, booking_date, booking_time } = await request.json();

    // Validate input
    if (!dojo_id || !class_type || !booking_date || !booking_time) {
      return new Response(JSON.stringify({
        error: 'Missing required fields',
        message: 'Dojo ID, class type, date, and time are required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Check for conflicts
    const existingBooking = await request.env.DB.prepare(
      'SELECT id FROM bookings WHERE dojo_id = ? AND booking_date = ? AND booking_time = ?'
    ).bind(dojo_id, booking_date, booking_time).first();

    if (existingBooking) {
      return new Response(JSON.stringify({
        error: 'Time slot unavailable',
        message: 'This time slot is already booked'
      }), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Create booking
    const result = await request.env.DB.prepare(
      'INSERT INTO bookings (user_id, dojo_id, class_type, booking_date, booking_time, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)'
    ).bind(
      request.user.userId,
      dojo_id,
      class_type,
      booking_date,
      booking_time,
      'confirmed',
      new Date().toISOString()
    ).run();

    return new Response(JSON.stringify({
      message: 'Booking created successfully',
      booking: {
        id: result.meta.last_row_id,
        dojo_id,
        class_type,
        booking_date,
        booking_time,
        status: 'confirmed'
      }
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Create booking error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to create booking',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get available time slots
router.get('/api/dojo/availability', async (request) => {
  try {
    const url = new URL(request.url);
    const dojoId = url.searchParams.get('dojo_id');
    const date = url.searchParams.get('date');

    if (!dojoId || !date) {
      return new Response(JSON.stringify({
        error: 'Missing parameters',
        message: 'Dojo ID and date are required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Get booked time slots
    const bookedSlots = await request.env.DB.prepare(
      'SELECT booking_time FROM bookings WHERE dojo_id = ? AND booking_date = ?'
    ).bind(dojoId, date).all();

    // Generate available time slots (example: 6 AM to 10 PM)
    const allSlots = [];
    for (let hour = 6; hour < 22; hour++) {
      allSlots.push(`${hour.toString().padStart(2, '0')}:00`);
      allSlots.push(`${hour.toString().padStart(2, '0')}:30`);
    }

    const bookedTimes = bookedSlots.results.map(slot => slot.booking_time);
    const availableSlots = allSlots.filter(slot => !bookedTimes.includes(slot));

    return new Response(JSON.stringify({
      date,
      dojo_id: dojoId,
      available_slots: availableSlots
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get availability error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get availability',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

export { router as dojoRoutes };
