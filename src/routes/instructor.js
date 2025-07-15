/**
 * Instructor management routes for JitsuFlow API
 * インストラクター管理API - スケジュール・給与・評価
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';
import { requireAdmin } from '../middleware/auth';

const router = Router();

// インストラクター一覧取得
router.get('/api/instructors', async (request) => {
  try {
    const url = new URL(request.url);
    const dojoId = url.searchParams.get('dojo_id');
    
    let query = `
      SELECT 
        u.id,
        u.email,
        u.name,
        u.belt_rank,
        u.instructor_bio,
        u.instructor_specialties,
        u.hourly_rate,
        u.commission_rate,
        u.created_at,
        COUNT(DISTINCT ida.dojo_id) as assigned_dojos,
        AVG(ir.overall_rating) as avg_rating,
        COUNT(DISTINCT is2.schedule_id) as active_schedules
      FROM users u
      LEFT JOIN instructor_dojo_assignments ida ON u.id = ida.instructor_id AND ida.status = 'active'
      LEFT JOIN instructor_ratings ir ON u.id = ir.instructor_id
      LEFT JOIN instructor_schedules is2 ON u.id = is2.instructor_id AND is2.confirmed = 1
      WHERE u.role = 'instructor'
    `;
    
    const params = [];
    
    if (dojoId) {
      query += ' AND ida.dojo_id = ?';
      params.push(dojoId);
    }
    
    query += ' GROUP BY u.id ORDER BY u.name';
    
    const instructors = await request.env.DB.prepare(query).bind(...params).all();
    
    return new Response(JSON.stringify({
      instructors: instructors.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get instructors error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get instructors',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// インストラクター詳細取得
router.get('/api/instructors/:instructorId', async (request) => {
  try {
    const { instructorId } = request.params;
    
    // 基本情報
    const instructor = await request.env.DB.prepare(`
      SELECT 
        u.*,
        COUNT(DISTINCT ida.dojo_id) as assigned_dojos,
        AVG(ir.overall_rating) as avg_rating,
        COUNT(DISTINCT ir.id) as total_ratings
      FROM users u
      LEFT JOIN instructor_dojo_assignments ida ON u.id = ida.instructor_id AND ida.status = 'active'
      LEFT JOIN instructor_ratings ir ON u.id = ir.instructor_id
      WHERE u.id = ? AND u.role = 'instructor'
      GROUP BY u.id
    `).bind(instructorId).first();
    
    if (!instructor) {
      return new Response(JSON.stringify({
        error: 'Instructor not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // 道場割当情報
    const assignments = await request.env.DB.prepare(`
      SELECT 
        ida.*,
        d.name as dojo_name
      FROM instructor_dojo_assignments ida
      JOIN dojos d ON ida.dojo_id = d.id
      WHERE ida.instructor_id = ? AND ida.status = 'active'
    `).bind(instructorId).all();
    
    // 今月の実績
    const thisMonthStats = await request.env.DB.prepare(`
      SELECT 
        COUNT(DISTINCT ir.id) as classes_taught,
        SUM(ir.total_students) as total_students,
        AVG(ir.attendance_rate) as avg_attendance_rate,
        AVG(ir.class_rating) as avg_self_rating
      FROM instructor_reports ir
      WHERE ir.instructor_id = ? 
        AND DATE(ir.report_date) >= DATE('now', 'start of month')
    `).bind(instructorId).first();
    
    // 認定資格
    const certifications = await request.env.DB.prepare(`
      SELECT * FROM instructor_certifications
      WHERE instructor_id = ? AND status = 'active'
      ORDER BY certification_date DESC
    `).bind(instructorId).all();
    
    return new Response(JSON.stringify({
      instructor: {
        ...instructor,
        specialties: instructor.instructor_specialties ? 
          JSON.parse(instructor.instructor_specialties) : []
      },
      assignments: assignments.results,
      this_month_stats: thisMonthStats || {
        classes_taught: 0,
        total_students: 0,
        avg_attendance_rate: 0,
        avg_self_rating: 0
      },
      certifications: certifications.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get instructor details error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get instructor details',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// インストラクタースケジュール取得
router.get('/api/instructors/:instructorId/schedule', async (request) => {
  try {
    const { instructorId } = request.params;
    const url = new URL(request.url);
    const date = url.searchParams.get('date') || new Date().toISOString().split('T')[0];
    const weeks = parseInt(url.searchParams.get('weeks')) || 2;
    
    // 指定期間のスケジュール
    const schedule = await request.env.DB.prepare(`
      SELECT 
        cs.*,
        d.name as dojo_name,
        inst_s.role,
        inst_s.confirmed,
        inst_s.notes,
        COUNT(b.id) as current_bookings
      FROM class_schedules cs
      JOIN instructor_schedules inst_s ON cs.id = inst_s.schedule_id
      JOIN dojos d ON cs.dojo_id = d.id
      LEFT JOIN bookings b ON cs.id = b.schedule_id 
        AND b.status = 'confirmed'
        AND b.booking_date BETWEEN ? AND ?
      WHERE inst_s.instructor_id = ? 
        AND cs.is_active = 1
      GROUP BY cs.id, inst_s.id
      ORDER BY cs.day_of_week, cs.start_time
    `).bind(
      date,
      new Date(Date.parse(date) + weeks * 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      instructorId
    ).all();
    
    // 不在・休暇情報
    const absences = await request.env.DB.prepare(`
      SELECT * FROM instructor_absences
      WHERE instructor_id = ? 
        AND start_date <= ? 
        AND end_date >= ?
        AND status = 'approved'
    `).bind(
      instructorId,
      new Date(Date.parse(date) + weeks * 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      date
    ).all();
    
    return new Response(JSON.stringify({
      schedule: schedule.results,
      absences: absences.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get instructor schedule error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get instructor schedule',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// インストラクター給与明細取得
router.get('/api/instructors/:instructorId/payroll', async (request) => {
  try {
    const { instructorId } = request.params;
    const url = new URL(request.url);
    const year = parseInt(url.searchParams.get('year')) || new Date().getFullYear();
    const month = parseInt(url.searchParams.get('month')) || new Date().getMonth() + 1;
    
    // 指定月の給与明細
    const payroll = await request.env.DB.prepare(`
      SELECT 
        ip.*,
        d.name as dojo_name,
        p.status as payment_status,
        p.paid_at
      FROM instructor_payrolls ip
      JOIN dojos d ON ip.dojo_id = d.id
      LEFT JOIN payments p ON ip.payment_id = p.id
      WHERE ip.instructor_id = ?
        AND strftime('%Y', ip.period_start) = ?
        AND strftime('%m', ip.period_start) = ?
    `).bind(instructorId, year.toString(), month.toString().padStart(2, '0')).all();
    
    // 給与明細詳細
    const payrollDetails = [];
    for (const payrollItem of payroll.results) {
      const details = await request.env.DB.prepare(`
        SELECT * FROM instructor_payroll_details
        WHERE payroll_id = ?
        ORDER BY item_type, description
      `).bind(payrollItem.id).all();
      
      payrollDetails.push({
        ...payrollItem,
        details: details.results
      });
    }
    
    // 年間実績サマリー
    const yearlyStats = await request.env.DB.prepare(`
      SELECT 
        COUNT(*) as total_months,
        SUM(net_payment) as total_earnings,
        AVG(net_payment) as avg_monthly,
        SUM(total_classes) as total_classes,
        SUM(total_students) as total_students
      FROM instructor_payrolls
      WHERE instructor_id = ? 
        AND strftime('%Y', period_start) = ?
        AND payment_status = 'paid'
    `).bind(instructorId, year.toString()).first();
    
    return new Response(JSON.stringify({
      payroll: payrollDetails,
      yearly_stats: yearlyStats || {
        total_months: 0,
        total_earnings: 0,
        avg_monthly: 0,
        total_classes: 0,
        total_students: 0
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get instructor payroll error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get instructor payroll',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// インストラクター評価取得
router.get('/api/instructors/:instructorId/ratings', async (request) => {
  try {
    const { instructorId } = request.params;
    const url = new URL(request.url);
    const limit = parseInt(url.searchParams.get('limit')) || 20;
    const offset = parseInt(url.searchParams.get('offset')) || 0;
    
    // 評価一覧
    const ratings = await request.env.DB.prepare(`
      SELECT 
        ir.*,
        u.name as student_name,
        cs.class_type,
        cs.start_time,
        cs.end_time
      FROM instructor_ratings ir
      JOIN users u ON ir.student_id = u.id
      JOIN class_schedules cs ON ir.schedule_id = cs.id
      WHERE ir.instructor_id = ?
      ORDER BY ir.class_date DESC
      LIMIT ? OFFSET ?
    `).bind(instructorId, limit, offset).all();
    
    // 評価統計
    const ratingStats = await request.env.DB.prepare(`
      SELECT 
        COUNT(*) as total_ratings,
        AVG(overall_rating) as avg_overall,
        AVG(teaching_clarity) as avg_clarity,
        AVG(technique_demonstration) as avg_technique,
        AVG(individual_attention) as avg_attention,
        AVG(class_organization) as avg_organization,
        COUNT(CASE WHEN overall_rating >= 4 THEN 1 END) * 100.0 / COUNT(*) as satisfaction_rate
      FROM instructor_ratings
      WHERE instructor_id = ?
    `).bind(instructorId).first();
    
    return new Response(JSON.stringify({
      ratings: ratings.results.map(rating => ({
        ...rating,
        anonymous: rating.anonymous === 1,
        student_name: rating.anonymous === 1 ? '匿名' : rating.student_name
      })),
      stats: ratingStats || {
        total_ratings: 0,
        avg_overall: 0,
        avg_clarity: 0,
        avg_technique: 0,
        avg_attention: 0,
        avg_organization: 0,
        satisfaction_rate: 0
      },
      pagination: {
        limit,
        offset,
        has_more: ratings.results.length === limit
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get instructor ratings error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get instructor ratings',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// インストラクター評価提出
router.post('/api/instructors/:instructorId/ratings', async (request) => {
  try {
    const { instructorId } = request.params;
    const {
      schedule_id,
      class_date,
      overall_rating,
      teaching_clarity,
      technique_demonstration,
      individual_attention,
      class_organization,
      feedback,
      anonymous = false
    } = await request.json();
    
    // バリデーション
    if (!schedule_id || !class_date || !overall_rating) {
      return new Response(JSON.stringify({
        error: 'Missing required fields',
        message: 'スケジュールID、クラス日程、総合評価は必須です'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // 重複評価チェック
    const existingRating = await request.env.DB.prepare(`
      SELECT id FROM instructor_ratings
      WHERE instructor_id = ? AND student_id = ? AND schedule_id = ? AND class_date = ?
    `).bind(instructorId, request.user.userId, schedule_id, class_date).first();
    
    if (existingRating) {
      return new Response(JSON.stringify({
        error: 'Rating already submitted',
        message: 'このクラスの評価は既に提出済みです'
      }), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // 評価作成
    const result = await request.env.DB.prepare(`
      INSERT INTO instructor_ratings (
        instructor_id, student_id, schedule_id, class_date,
        overall_rating, teaching_clarity, technique_demonstration,
        individual_attention, class_organization, feedback, anonymous, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      instructorId,
      request.user.userId,
      schedule_id,
      class_date,
      overall_rating,
      teaching_clarity,
      technique_demonstration,
      individual_attention,
      class_organization,
      feedback,
      anonymous,
      new Date().toISOString()
    ).run();
    
    return new Response(JSON.stringify({
      message: 'Rating submitted successfully',
      rating_id: result.meta.last_row_id
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Submit rating error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to submit rating',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// インストラクター割当管理（管理者のみ）
router.get('/api/instructors/:instructorId/assignments', async (request) => {
  try {
    const { instructorId } = request.params;
    
    const assignments = await request.env.DB.prepare(`
      SELECT 
        ida.*,
        d.name as dojo_name,
        d.address as dojo_address
      FROM instructor_dojo_assignments ida
      JOIN dojos d ON ida.dojo_id = d.id
      WHERE ida.instructor_id = ?
      ORDER BY ida.status, ida.start_date DESC
    `).bind(instructorId).all();
    
    return new Response(JSON.stringify({
      assignments: assignments.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get instructor assignments error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get instructor assignments',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 給与明細作成（管理者のみ）
router.post('/api/instructors/:instructorId/payroll', async (request) => {
  try {
    // 管理者権限チェック
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;
    
    const { instructorId } = request.params;
    const {
      dojo_id,
      period_start,
      period_end,
      total_classes,
      total_hours,
      total_students,
      gross_revenue,
      usage_fee,
      other_deductions,
      calculation_details
    } = await request.json();
    
    // 道場割当情報取得
    const assignment = await request.env.DB.prepare(`
      SELECT * FROM instructor_dojo_assignments
      WHERE instructor_id = ? AND dojo_id = ? AND status = 'active'
    `).bind(instructorId, dojo_id).first();
    
    if (!assignment) {
      return new Response(JSON.stringify({
        error: 'Assignment not found',
        message: 'インストラクターの道場割当が見つかりません'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // 給与計算
    let netPayment = 0;
    if (assignment.payment_type === 'revenue_share') {
      netPayment = Math.round(gross_revenue * assignment.revenue_share_percentage / 100) - usage_fee - other_deductions;
    } else if (assignment.payment_type === 'hourly') {
      netPayment = (total_hours * assignment.hourly_rate) - usage_fee - other_deductions;
    } else if (assignment.payment_type === 'fixed') {
      netPayment = assignment.fixed_monthly_fee - usage_fee - other_deductions;
    }
    
    // 給与明細作成
    const result = await request.env.DB.prepare(`
      INSERT INTO instructor_payrolls (
        instructor_id, dojo_id, period_start, period_end,
        total_classes, total_hours, total_students, gross_revenue,
        usage_fee, other_deductions, net_payment,
        calculation_details, approved_by, approved_at, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      instructorId,
      dojo_id,
      period_start,
      period_end,
      total_classes,
      total_hours,
      total_students,
      gross_revenue,
      usage_fee,
      other_deductions,
      netPayment,
      JSON.stringify(calculation_details),
      request.user.userId,
      new Date().toISOString(),
      new Date().toISOString()
    ).run();
    
    return new Response(JSON.stringify({
      message: 'Payroll created successfully',
      payroll_id: result.meta.last_row_id,
      net_payment: netPayment
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Create payroll error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to create payroll',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

export { router as instructorRoutes };