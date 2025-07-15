/**
 * Booking routes for JitsuFlow API
 * 予約API - スケジュール管理・予約作成・キャンセル待ち機能
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';

const router = Router();

// Get all schedules
router.get('/api/schedules', async (request) => {
  try {
    const url = new URL(request.url);
    const dojoId = url.searchParams.get('dojo_id');
    
    let query = `
      SELECT s.*, d.name as dojo_name 
      FROM class_schedules s 
      JOIN dojos d ON s.dojo_id = d.id 
      WHERE s.is_active = 1
    `;
    const params = [];
    
    if (dojoId) {
      query += ' AND s.dojo_id = ?';
      params.push(dojoId);
    }
    
    query += ' ORDER BY s.day_of_week, s.start_time';
    
    const schedules = await request.env.DB.prepare(query).bind(...params).all();
    
    return new Response(JSON.stringify({
      schedules: schedules.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get schedules error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get schedules',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Create new schedule (admin only)
router.post('/api/schedules', async (request) => {
  try {
    const { 
      dojo_id, 
      day_of_week, 
      start_time, 
      end_time, 
      class_type, 
      instructor, 
      level 
    } = await request.json();
    
    // Validate input
    if (!dojo_id || day_of_week === undefined || !start_time || !end_time || !class_type) {
      return new Response(JSON.stringify({
        error: 'Missing required fields',
        message: 'dojo_id, day_of_week, start_time, end_time, and class_type are required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Create schedule record
    const result = await request.env.DB.prepare(
      `INSERT INTO class_schedules 
       (dojo_id, day_of_week, start_time, end_time, class_type, instructor, level, created_at) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(
      dojo_id,
      day_of_week,
      start_time,
      end_time,
      class_type,
      instructor,
      level,
      new Date().toISOString()
    ).run();
    
    return new Response(JSON.stringify({
      message: 'Schedule created successfully',
      schedule_id: result.insertId
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Create schedule error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to create schedule',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Update schedule (admin only)
router.patch('/api/schedules/:id', async (request) => {
  try {
    const { id } = request.params;
    const updateData = await request.json();
    
    // Build update query dynamically
    const allowedFields = ['class_type', 'instructor', 'level', 'start_time', 'end_time'];
    const updateFields = [];
    const values = [];
    
    for (const field of allowedFields) {
      if (updateData[field] !== undefined) {
        updateFields.push(`${field} = ?`);
        values.push(updateData[field]);
      }
    }
    
    if (updateFields.length === 0) {
      return new Response(JSON.stringify({
        error: 'No valid fields to update'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    updateFields.push('updated_at = ?');
    values.push(new Date().toISOString());
    values.push(id);
    
    const query = `UPDATE class_schedules SET ${updateFields.join(', ')} WHERE id = ?`;
    
    const result = await request.env.DB.prepare(query).bind(...values).run();
    
    if (result.changes === 0) {
      return new Response(JSON.stringify({
        error: 'Schedule not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    return new Response(JSON.stringify({
      message: 'Schedule updated successfully'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Update schedule error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to update schedule',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Delete schedule (admin only)
router.delete('/api/schedules/:id', async (request) => {
  try {
    const { id } = request.params;
    
    const result = await request.env.DB.prepare(
      'UPDATE class_schedules SET is_active = 0, updated_at = ? WHERE id = ?'
    ).bind(new Date().toISOString(), id).run();
    
    if (result.changes === 0) {
      return new Response(JSON.stringify({
        error: 'Schedule not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    return new Response(JSON.stringify({
      message: 'Schedule deleted successfully'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Delete schedule error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to delete schedule',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Create booking（定員管理・キャンセル待ち対応）
router.post('/api/bookings', async (request) => {
  try {
    const { schedule_id, booking_date, user_id, join_waitlist = false } = await request.json();
    const actualUserId = user_id || request.user.userId;
    
    // Validate input
    if (!schedule_id || !booking_date) {
      return new Response(JSON.stringify({
        error: 'Missing required fields',
        message: 'schedule_id and booking_date are required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Check if schedule exists
    const schedule = await request.env.DB.prepare(
      'SELECT * FROM class_schedules WHERE id = ? AND is_active = 1'
    ).bind(schedule_id).first();
    
    if (!schedule) {
      return new Response(JSON.stringify({
        error: 'Schedule not found',
        message: 'The specified schedule does not exist or is inactive'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Check for existing booking
    const existingBooking = await request.env.DB.prepare(
      'SELECT * FROM bookings WHERE user_id = ? AND schedule_id = ? AND booking_date = ? AND status != "cancelled"'
    ).bind(actualUserId, schedule_id, booking_date).first();
    
    if (existingBooking) {
      return new Response(JSON.stringify({
        error: 'Already booked',
        message: 'You already have a booking for this class on this date'
      }), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Check capacity
    const capacity = await request.env.DB.prepare(
      'SELECT * FROM class_capacity WHERE schedule_id = ?'
    ).bind(schedule_id).first();
    
    if (capacity && capacity.current_bookings >= capacity.max_capacity) {
      // Full capacity - add to waitlist if requested
      if (join_waitlist) {
        // Check if already on waitlist
        const existingWaitlist = await request.env.DB.prepare(
          'SELECT * FROM booking_waitlists WHERE user_id = ? AND schedule_id = ? AND booking_date = ? AND status = "waiting"'
        ).bind(actualUserId, schedule_id, booking_date).first();
        
        if (existingWaitlist) {
          return new Response(JSON.stringify({
            error: 'Already on waitlist',
            message: 'You are already on the waitlist for this class'
          }), {
            status: 409,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          });
        }
        
        // Add to waitlist
        const waitlistResult = await request.env.DB.prepare(`
          INSERT INTO booking_waitlists (
            user_id, schedule_id, booking_date, status, created_at
          ) VALUES (?, ?, ?, 'waiting', ?)
        `).bind(
          actualUserId,
          schedule_id,
          booking_date,
          new Date().toISOString()
        ).run();
        
        // Get waitlist position
        const position = await request.env.DB.prepare(`
          SELECT COUNT(*) as position FROM booking_waitlists
          WHERE schedule_id = ? AND booking_date = ? 
            AND status = 'waiting' AND created_at <= (
              SELECT created_at FROM booking_waitlists WHERE id = ?
            )
        `).bind(schedule_id, booking_date, waitlistResult.meta.last_row_id).first();
        
        return new Response(JSON.stringify({
          message: 'Added to waitlist successfully',
          waitlist_id: waitlistResult.meta.last_row_id,
          position: position.position,
          status: 'waiting'
        }), {
          status: 201,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      } else {
        return new Response(JSON.stringify({
          error: 'Class full',
          message: 'This class is at full capacity. Would you like to join the waitlist?',
          can_join_waitlist: true
        }), {
          status: 409,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }
    }
    
    // Create booking
    const result = await request.env.DB.prepare(
      'INSERT INTO bookings (user_id, dojo_id, schedule_id, booking_date, status, booking_type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)'
    ).bind(
      actualUserId,
      schedule.dojo_id,
      schedule_id,
      booking_date,
      'confirmed',
      'standard',
      new Date().toISOString()
    ).run();
    
    return new Response(JSON.stringify({
      message: 'Booking created successfully',
      booking_id: result.meta.last_row_id,
      booking: {
        id: result.meta.last_row_id,
        schedule_id,
        booking_date,
        status: 'confirmed',
        class_type: schedule.class_type,
        start_time: schedule.start_time,
        end_time: schedule.end_time
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

// Get user bookings
router.get('/api/bookings', async (request) => {
  try {
    const url = new URL(request.url);
    const userId = url.searchParams.get('user_id') || 1;
    
    const bookings = await request.env.DB.prepare(
      `SELECT b.*, s.class_type, s.start_time, s.end_time, s.instructor, s.level, d.name as dojo_name
       FROM bookings b
       JOIN class_schedules s ON b.schedule_id = s.id
       JOIN dojos d ON b.dojo_id = d.id
       WHERE b.user_id = ? AND b.status != 'cancelled'
       ORDER BY b.booking_date DESC, s.start_time`
    ).bind(userId).all();
    
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

// Cancel booking（キャンセル待ち自動処理対応）
router.patch('/api/bookings/:id/cancel', async (request) => {
  try {
    const { id } = request.params;
    const { reason } = await request.json();
    
    // 予約取得
    const booking = await request.env.DB.prepare(`
      SELECT b.*, cs.class_type, cs.dojo_id 
      FROM bookings b
      JOIN class_schedules cs ON b.schedule_id = cs.id
      WHERE b.id = ? AND (b.user_id = ? OR ? = 'admin')
    `).bind(id, request.user?.userId || 1, request.user?.role || 'user').first();
    
    if (!booking) {
      return new Response(JSON.stringify({
        error: 'Booking not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    if (booking.status === 'cancelled') {
      return new Response(JSON.stringify({
        error: 'Booking already cancelled'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // キャンセル処理
    const result = await request.env.DB.prepare(
      'UPDATE bookings SET status = "cancelled", cancellation_reason = ?, updated_at = ? WHERE id = ?'
    ).bind(reason, new Date().toISOString(), id).run();
    
    // キャンセル待ちの処理
    const waitingList = await request.env.DB.prepare(`
      SELECT bw.*, u.name as user_name, u.email 
      FROM booking_waitlists bw
      JOIN users u ON bw.user_id = u.id
      WHERE bw.schedule_id = ? AND bw.booking_date = ? AND bw.status = 'waiting'
      ORDER BY bw.created_at ASC
      LIMIT 1
    `).bind(booking.schedule_id, booking.booking_date).first();
    
    if (waitingList) {
      // キャンセル待ちから自動予約作成
      const newBookingResult = await request.env.DB.prepare(`
        INSERT INTO bookings (
          user_id, schedule_id, booking_date, status, booking_type, created_at
        ) VALUES (?, ?, ?, 'confirmed', 'waitlist_confirmed', ?)
      `).bind(
        waitingList.user_id,
        booking.schedule_id,
        booking.booking_date,
        new Date().toISOString()
      ).run();
      
      // キャンセル待ち状態更新
      await request.env.DB.prepare(`
        UPDATE booking_waitlists 
        SET status = 'confirmed', confirmed_at = ?, booking_id = ?
        WHERE id = ?
      `).bind(
        new Date().toISOString(),
        newBookingResult.meta.last_row_id,
        waitingList.id
      ).run();
      
      // 通知作成
      await request.env.DB.prepare(`
        INSERT INTO notifications (
          user_id, type, title, message, related_id, created_at
        ) VALUES (?, 'booking_confirmed', ?, ?, ?, ?)
      `).bind(
        waitingList.user_id,
        'キャンセル待ちから予約確定',
        `${booking.class_type}クラスの予約が確定しました。`,
        newBookingResult.meta.last_row_id,
        new Date().toISOString()
      ).run();
    }
    
    return new Response(JSON.stringify({
      message: 'Booking cancelled successfully',
      waitlist_processed: waitingList ? true : false,
      next_booking_user: waitingList ? waitingList.user_name : null
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Cancel booking error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to cancel booking',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// キャンセル待ち一覧取得
router.get('/api/bookings/waitlist', async (request) => {
  try {
    const url = new URL(request.url);
    const userId = url.searchParams.get('user_id') || request.user?.userId || 1;
    const scheduleId = url.searchParams.get('schedule_id');
    
    let query = `
      SELECT 
        bw.*,
        cs.class_type,
        cs.start_time,
        cs.end_time,
        cs.instructor,
        d.name as dojo_name,
        u.name as user_name
      FROM booking_waitlists bw
      JOIN class_schedules cs ON bw.schedule_id = cs.id
      JOIN dojos d ON cs.dojo_id = d.id
      JOIN users u ON bw.user_id = u.id
      WHERE bw.user_id = ? AND bw.status = 'waiting'
    `;
    
    const params = [userId];
    
    if (scheduleId) {
      query += ' AND bw.schedule_id = ?';
      params.push(scheduleId);
    }
    
    query += ' ORDER BY bw.created_at DESC';
    
    const waitlists = await request.env.DB.prepare(query).bind(...params).all();
    
    // 各キャンセル待ちの順番を計算
    const waitlistsWithPosition = [];
    for (const waitlist of waitlists.results) {
      const position = await request.env.DB.prepare(`
        SELECT COUNT(*) as position FROM booking_waitlists
        WHERE schedule_id = ? AND booking_date = ? 
          AND status = 'waiting' AND created_at <= ?
      `).bind(waitlist.schedule_id, waitlist.booking_date, waitlist.created_at).first();
      
      waitlistsWithPosition.push({
        ...waitlist,
        position: position.position
      });
    }
    
    return new Response(JSON.stringify({
      waitlists: waitlistsWithPosition
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get waitlists error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get waitlists',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// キャンセル待ち削除
router.delete('/api/bookings/waitlist/:waitlistId', async (request) => {
  try {
    const { waitlistId } = request.params;
    
    const result = await request.env.DB.prepare(
      'UPDATE booking_waitlists SET status = "cancelled", updated_at = ? WHERE id = ? AND user_id = ?'
    ).bind(new Date().toISOString(), waitlistId, request.user?.userId || 1).run();
    
    if (result.changes === 0) {
      return new Response(JSON.stringify({
        error: 'Waitlist entry not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    return new Response(JSON.stringify({
      message: 'Removed from waitlist successfully'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Remove from waitlist error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to remove from waitlist',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// クラス定員情報取得
router.get('/api/schedules/:scheduleId/capacity', async (request) => {
  try {
    const { scheduleId } = request.params;
    const url = new URL(request.url);
    const date = url.searchParams.get('date') || new Date().toISOString().split('T')[0];
    
    // 定員設定取得
    const capacity = await request.env.DB.prepare(
      'SELECT * FROM class_capacity WHERE schedule_id = ?'
    ).bind(scheduleId).first();
    
    if (!capacity) {
      return new Response(JSON.stringify({
        error: 'Capacity settings not found',
        message: 'This class does not have capacity settings configured'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // 当日の予約数取得
    const currentBookings = await request.env.DB.prepare(`
      SELECT COUNT(*) as count FROM bookings 
      WHERE schedule_id = ? AND booking_date = ? AND status = 'confirmed'
    `).bind(scheduleId, date).first();
    
    // キャンセル待ち数取得
    const waitlistCount = await request.env.DB.prepare(`
      SELECT COUNT(*) as count FROM booking_waitlists 
      WHERE schedule_id = ? AND booking_date = ? AND status = 'waiting'
    `).bind(scheduleId, date).first();
    
    const availableSpots = capacity.max_capacity - currentBookings.count;
    
    return new Response(JSON.stringify({
      max_capacity: capacity.max_capacity,
      current_bookings: currentBookings.count,
      available_spots: Math.max(0, availableSpots),
      waitlist_count: waitlistCount.count,
      is_full: availableSpots <= 0,
      allows_waitlist: capacity.allows_waitlist === 1,
      updated_at: capacity.updated_at
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get capacity error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get capacity info',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

export { router as bookingRoutes };