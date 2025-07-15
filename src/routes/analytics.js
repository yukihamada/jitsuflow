/**
 * Analytics routes for JitsuFlow API
 * 経営分析API - 売上・利益・KPI分析
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';
import { requireAdmin } from '../middleware/auth';

const router = Router();

// 売上サマリー取得
router.get('/api/analytics/revenue', async (request) => {
  try {
    // 管理者権限チェック
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;

    const url = new URL(request.url);
    const period = url.searchParams.get('period') || 'month';
    const dojoId = url.searchParams.get('dojo_id');
    const startDate = url.searchParams.get('start_date');
    const endDate = url.searchParams.get('end_date');

    // 期間設定
    let dateFilter = '';
    let dateParams = [];

    if (startDate && endDate) {
      dateFilter = 'AND DATE(st.created_at) BETWEEN ? AND ?';
      dateParams = [startDate, endDate];
    } else if (period === 'week') {
      dateFilter = 'AND DATE(st.created_at) >= DATE("now", "-7 days")';
    } else if (period === 'month') {
      dateFilter = 'AND DATE(st.created_at) >= DATE("now", "start of month")';
    } else if (period === 'quarter') {
      dateFilter = 'AND DATE(st.created_at) >= DATE("now", "-3 months")';
    } else if (period === 'year') {
      dateFilter = 'AND DATE(st.created_at) >= DATE("now", "start of year")';
    }

    // 道場フィルター
    let dojoFilter = '';
    let dojoParams = [];
    if (dojoId) {
      dojoFilter = 'AND d.id = ?';
      dojoParams = [dojoId];
    }

    // 売上データ取得
    const revenueData = await request.env.DB.prepare(`
      SELECT 
        d.id as dojo_id,
        d.name as dojo_name,
        DATE(st.created_at, 'start of month') as period,
        -- 収益
        SUM(CASE WHEN st.transaction_type = 'membership' THEN st.total_amount ELSE 0 END) as membership_revenue,
        SUM(CASE WHEN st.transaction_type = 'product_sale' OR st.transaction_type = 'pos_sale' THEN st.total_amount ELSE 0 END) as product_revenue,
        SUM(CASE WHEN st.transaction_type = 'rental' THEN st.total_amount ELSE 0 END) as rental_revenue,
        SUM(st.total_amount) as total_revenue,
        COUNT(st.id) as transaction_count,
        AVG(st.total_amount) as avg_transaction_amount
      FROM dojos d
      LEFT JOIN sales_transactions st ON d.id = st.dojo_id 
        AND st.status = 'completed' ${dateFilter}
      WHERE 1=1 ${dojoFilter}
      GROUP BY d.id, DATE(st.created_at, 'start of month')
      ORDER BY d.id, period DESC
    `).bind(...dateParams, ...dojoParams).all();

    // コストデータ取得
    const costData = await request.env.DB.prepare(`
      SELECT 
        d.id as dojo_id,
        d.name as dojo_name,
        DATE(p.payment_date, 'start of month') as period,
        SUM(CASE WHEN p.payment_type = 'instructor_payment' THEN p.total_amount ELSE 0 END) as instructor_costs,
        SUM(CASE WHEN p.payment_type = 'dojo_fee' THEN p.total_amount ELSE 0 END) as facility_costs,
        SUM(p.total_amount) as total_costs
      FROM dojos d
      LEFT JOIN payments p ON d.id = p.dojo_id 
        AND p.status = 'completed' ${dateFilter.replace('st.created_at', 'p.payment_date')}
      WHERE 1=1 ${dojoFilter}
      GROUP BY d.id, DATE(p.payment_date, 'start of month')
      ORDER BY d.id, period DESC
    `).bind(...dateParams, ...dojoParams).all();

    // データマージと利益計算
    const combinedData = [];
    const revenueMap = new Map();

    // 売上データをマップに格納
    revenueData.results.forEach(revenue => {
      const key = `${revenue.dojo_id}-${revenue.period}`;
      revenueMap.set(key, revenue);
    });

    // コストデータと結合
    costData.results.forEach(cost => {
      const key = `${cost.dojo_id}-${cost.period}`;
      const revenue = revenueMap.get(key) || {
        dojo_id: cost.dojo_id,
        dojo_name: cost.dojo_name,
        period: cost.period,
        membership_revenue: 0,
        product_revenue: 0,
        rental_revenue: 0,
        total_revenue: 0,
        transaction_count: 0,
        avg_transaction_amount: 0
      };

      combinedData.push({
        ...revenue,
        instructor_costs: cost.instructor_costs || 0,
        facility_costs: cost.facility_costs || 0,
        total_costs: cost.total_costs || 0,
        gross_profit: (revenue.total_revenue || 0) - (cost.total_costs || 0),
        profit_margin: revenue.total_revenue > 0 ?
          ((revenue.total_revenue - cost.total_costs) / revenue.total_revenue * 100) : 0
      });

      revenueMap.delete(key);
    });

    // 売上のみ（コストなし）のデータを追加
    revenueMap.forEach(revenue => {
      combinedData.push({
        ...revenue,
        instructor_costs: 0,
        facility_costs: 0,
        total_costs: 0,
        gross_profit: revenue.total_revenue || 0,
        profit_margin: 100
      });
    });

    return new Response(JSON.stringify({
      revenue: combinedData.sort((a, b) =>
        new Date(b.period) - new Date(a.period) || a.dojo_id - b.dojo_id
      )
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get revenue analytics error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get revenue analytics',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// KPI指標取得
router.get('/api/analytics/kpi', async (request) => {
  try {
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;

    const url = new URL(request.url);
    const dojoId = url.searchParams.get('dojo_id');
    const period = url.searchParams.get('period') || 'month';

    let dateFilter = '';
    if (period === 'week') {
      dateFilter = 'AND DATE(created_at) >= DATE("now", "-7 days")';
    } else if (period === 'month') {
      dateFilter = 'AND DATE(created_at) >= DATE("now", "start of month")';
    } else if (period === 'quarter') {
      dateFilter = 'AND DATE(created_at) >= DATE("now", "-3 months")';
    }

    const dojoFilter = dojoId ? 'AND dojo_id = ?' : '';
    const params = dojoId ? [dojoId] : [];

    // 会員関連KPI
    const membershipKPI = await request.env.DB.prepare(`
      SELECT 
        COUNT(DISTINCT CASE WHEN u.status = 'active' THEN u.id END) as total_active_members,
        COUNT(DISTINCT CASE 
          WHEN u.status = 'active' AND u.created_at >= DATE('now', 'start of month') 
          THEN u.id 
        END) as new_members_this_month,
        COUNT(DISTINCT CASE 
          WHEN u.status = 'inactive' AND u.updated_at >= DATE('now', 'start of month')
          THEN u.id 
        END) as churned_members_this_month,
        COUNT(DISTINCT CASE WHEN s.status = 'active' THEN s.user_id END) as premium_members
      FROM users u
      LEFT JOIN user_dojo_affiliations uda ON u.id = uda.user_id ${dojoFilter.replace('dojo_id', 'uda.dojo_id')}
      LEFT JOIN subscriptions s ON u.id = s.user_id AND s.status = 'active'
      WHERE u.role = 'user'
    `).bind(...params).first();

    // 予約・出席関連KPI
    const bookingKPI = await request.env.DB.prepare(`
      SELECT 
        COUNT(DISTINCT b.id) as total_bookings,
        COUNT(DISTINCT CASE WHEN b.attendance_status = 'present' THEN b.id END) as attended_bookings,
        COUNT(DISTINCT CASE WHEN b.status = 'cancelled' THEN b.id END) as cancelled_bookings,
        AVG(cc.current_bookings * 100.0 / cc.max_capacity) as avg_capacity_utilization
      FROM bookings b
      LEFT JOIN class_capacity cc ON b.schedule_id = cc.schedule_id
      WHERE 1=1 ${dateFilter.replace('created_at', 'b.created_at')} ${dojoFilter.replace('dojo_id', 'b.dojo_id')}
    `).bind(...params).first();

    // 売上関連KPI
    const revenueKPI = await request.env.DB.prepare(`
      SELECT 
        COUNT(DISTINCT user_id) as paying_customers,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as avg_transaction_value,
        COUNT(id) as total_transactions
      FROM sales_transactions 
      WHERE status = 'completed' ${dateFilter} ${dojoFilter}
    `).bind(...params).first();

    // インストラクター関連KPI
    const instructorKPI = await request.env.DB.prepare(`
      SELECT 
        COUNT(DISTINCT u.id) as total_instructors,
        AVG(ir.overall_rating) as avg_instructor_rating,
        COUNT(DISTINCT cs.id) as total_classes,
        SUM(ir.total_students) as total_student_interactions
      FROM users u
      LEFT JOIN instructor_dojo_assignments ida ON u.id = ida.instructor_id 
        AND ida.status = 'active' ${dojoFilter.replace('dojo_id', 'ida.dojo_id')}
      LEFT JOIN instructor_ratings ir_rating ON u.id = ir_rating.instructor_id
      LEFT JOIN class_schedules cs ON u.name = cs.instructor
      LEFT JOIN instructor_reports ir ON u.id = ir.instructor_id ${dateFilter.replace('created_at', 'ir.report_date')}
      WHERE u.role = 'instructor'
    `).bind(...params).first();

    // 計算されたKPI
    const attendanceRate = bookingKPI.total_bookings > 0 ?
      (bookingKPI.attended_bookings / bookingKPI.total_bookings * 100) : 0;

    const retentionRate = membershipKPI.total_active_members > 0 && membershipKPI.churned_members_this_month >= 0 ?
      ((membershipKPI.total_active_members - membershipKPI.churned_members_this_month) / membershipKPI.total_active_members * 100) : 0;

    const avgRevenuePerMember = membershipKPI.total_active_members > 0 ?
      (revenueKPI.total_revenue / membershipKPI.total_active_members) : 0;

    return new Response(JSON.stringify({
      kpi: {
        // 会員指標
        total_members: membershipKPI.total_active_members || 0,
        active_members: membershipKPI.total_active_members || 0,
        new_members_this_month: membershipKPI.new_members_this_month || 0,
        premium_members: membershipKPI.premium_members || 0,
        retention_rate: Math.round(retentionRate * 10) / 10,

        // 予約・出席指標
        total_bookings: bookingKPI.total_bookings || 0,
        attendance_rate: Math.round(attendanceRate * 10) / 10,
        cancellation_rate: bookingKPI.total_bookings > 0 ?
          Math.round(bookingKPI.cancelled_bookings / bookingKPI.total_bookings * 1000) / 10 : 0,
        capacity_utilization: Math.round((bookingKPI.avg_capacity_utilization || 0) * 10) / 10,

        // 売上指標
        total_revenue: revenueKPI.total_revenue || 0,
        paying_customers: revenueKPI.paying_customers || 0,
        avg_transaction_value: Math.round((revenueKPI.avg_transaction_value || 0)),
        average_revenue_per_member: Math.round(avgRevenuePerMember),

        // インストラクター指標
        total_instructors: instructorKPI.total_instructors || 0,
        avg_instructor_rating: Math.round((instructorKPI.avg_instructor_rating || 0) * 10) / 10,
        total_classes: instructorKPI.total_classes || 0,
        instructor_utilization: instructorKPI.total_instructors > 0 ?
          Math.round((instructorKPI.total_classes / instructorKPI.total_instructors) * 10) / 10 : 0
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get KPI analytics error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get KPI analytics',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// トレンド分析（期間比較）
router.get('/api/analytics/trends', async (request) => {
  try {
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;

    const url = new URL(request.url);
    const dojoId = url.searchParams.get('dojo_id');
    const months = parseInt(url.searchParams.get('months')) || 12;

    const dojoFilter = dojoId ? 'AND st.dojo_id = ?' : '';
    const params = dojoId ? [dojoId] : [];

    // 月次売上トレンド
    const monthlyTrends = await request.env.DB.prepare(`
      SELECT 
        strftime('%Y-%m', st.created_at) as month,
        SUM(st.total_amount) as revenue,
        COUNT(st.id) as transactions,
        COUNT(DISTINCT st.user_id) as unique_customers,
        AVG(st.total_amount) as avg_transaction
      FROM sales_transactions st
      WHERE st.status = 'completed' 
        AND DATE(st.created_at) >= DATE('now', '-${months} months') 
        ${dojoFilter}
      GROUP BY strftime('%Y-%m', st.created_at)
      ORDER BY month
    `).bind(...params).all();

    // 会員数トレンド
    const membershipTrends = await request.env.DB.prepare(`
      WITH monthly_members AS (
        SELECT 
          strftime('%Y-%m', date) as month,
          SUM(new_members) as new_members,
          SUM(total_members) as total_members
        FROM (
          SELECT 
            DATE(u.created_at) as date,
            COUNT(*) as new_members,
            0 as total_members
          FROM users u
          LEFT JOIN user_dojo_affiliations uda ON u.id = uda.user_id ${dojoFilter.replace('st.dojo_id', 'uda.dojo_id')}
          WHERE u.role = 'user' 
            AND DATE(u.created_at) >= DATE('now', '-${months} months')
          GROUP BY DATE(u.created_at)
          
          UNION ALL
          
          SELECT 
            DATE('now') as date,
            0 as new_members,
            COUNT(DISTINCT u.id) as total_members
          FROM users u
          LEFT JOIN user_dojo_affiliations uda ON u.id = uda.user_id ${dojoFilter.replace('st.dojo_id', 'uda.dojo_id')}
          WHERE u.role = 'user' AND u.status = 'active'
        )
        GROUP BY strftime('%Y-%m', date)
      )
      SELECT * FROM monthly_members ORDER BY month
    `).bind(...params).all();

    // 予約トレンド
    const bookingTrends = await request.env.DB.prepare(`
      SELECT 
        strftime('%Y-%m', b.created_at) as month,
        COUNT(b.id) as total_bookings,
        COUNT(CASE WHEN b.attendance_status = 'present' THEN 1 END) as attended,
        COUNT(CASE WHEN b.status = 'cancelled' THEN 1 END) as cancelled
      FROM bookings b
      WHERE DATE(b.created_at) >= DATE('now', '-${months} months') ${dojoFilter.replace('st.dojo_id', 'b.dojo_id')}
      GROUP BY strftime('%Y-%m', b.created_at)
      ORDER BY month
    `).bind(...params).all();

    return new Response(JSON.stringify({
      trends: {
        revenue: monthlyTrends.results,
        membership: membershipTrends.results,
        bookings: bookingTrends.results
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get trends analytics error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get trends analytics',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// インストラクター実績分析
router.get('/api/analytics/instructor-performance', async (request) => {
  try {
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;

    const url = new URL(request.url);
    const dojoId = url.searchParams.get('dojo_id');
    const period = url.searchParams.get('period') || 'month';

    let dateFilter = 'AND ir.report_date >= DATE("now", "start of month")';
    if (period === 'week') {
      dateFilter = 'AND ir.report_date >= DATE("now", "-7 days")';
    } else if (period === 'quarter') {
      dateFilter = 'AND ir.report_date >= DATE("now", "-3 months")';
    } else if (period === 'year') {
      dateFilter = 'AND ir.report_date >= DATE("now", "start of year")';
    }

    const dojoFilter = dojoId ? 'AND ida.dojo_id = ?' : '';
    const params = dojoId ? [dojoId] : [];

    const instructorPerformance = await request.env.DB.prepare(`
      SELECT 
        u.id,
        u.name,
        u.belt_rank,
        -- 基本統計
        COUNT(DISTINCT ir.id) as classes_taught,
        SUM(ir.total_students) as total_students_taught,
        AVG(ir.attendance_rate) as avg_attendance_rate,
        AVG(ir.class_rating) as avg_self_rating,
        -- 評価統計
        AVG(rating.overall_rating) as avg_student_rating,
        COUNT(DISTINCT rating.id) as total_ratings,
        -- 給与統計
        SUM(ip.net_payment) as total_earnings,
        AVG(ip.net_payment) as avg_monthly_earnings,
        -- 効率指標
        CASE 
          WHEN SUM(ir.total_students) > 0 
          THEN SUM(ip.net_payment) * 1.0 / SUM(ir.total_students)
          ELSE 0 
        END as earnings_per_student
      FROM users u
      JOIN instructor_dojo_assignments ida ON u.id = ida.instructor_id AND ida.status = 'active'
      LEFT JOIN instructor_reports ir ON u.id = ir.instructor_id ${dateFilter}
      LEFT JOIN instructor_ratings rating ON u.id = rating.instructor_id ${dateFilter.replace('ir.report_date', 'rating.class_date')}
      LEFT JOIN instructor_payrolls ip ON u.id = ip.instructor_id ${dateFilter.replace('ir.report_date', 'ip.period_start')}
      WHERE u.role = 'instructor' ${dojoFilter}
      GROUP BY u.id, u.name, u.belt_rank
      ORDER BY total_earnings DESC, avg_student_rating DESC
    `).bind(...params).all();

    return new Response(JSON.stringify({
      instructor_performance: instructorPerformance.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get instructor performance error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get instructor performance',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 在庫分析（レンタル・物販）
router.get('/api/analytics/inventory', async (request) => {
  try {
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;

    const url = new URL(request.url);
    const dojoId = url.searchParams.get('dojo_id');

    const dojoFilter = dojoId ? 'WHERE dojo_id = ?' : '';
    const params = dojoId ? [dojoId] : [];

    // 商品在庫分析
    const productInventory = await request.env.DB.prepare(`
      SELECT 
        p.*,
        COUNT(st.id) as sales_count,
        SUM(JSON_EXTRACT(st.items_detail, '$[0].quantity')) as units_sold,
        SUM(st.total_amount) as revenue_generated,
        p.current_stock * p.cost_price as inventory_value,
        CASE 
          WHEN p.current_stock <= p.min_stock_level THEN 'low'
          WHEN p.current_stock = 0 THEN 'out'
          ELSE 'normal'
        END as stock_status
      FROM products p
      LEFT JOIN sales_transactions st ON JSON_EXTRACT(st.items_detail, '$[0].id') = p.id 
        AND st.transaction_type = 'pos_sale'
        AND DATE(st.created_at) >= DATE('now', 'start of month')
      ${dojoFilter}
      GROUP BY p.id
      ORDER BY revenue_generated DESC
    `).bind(...params).all();

    // レンタル在庫分析
    const rentalInventory = await request.env.DB.prepare(`
      SELECT 
        r.*,
        COUNT(rt.id) as rental_count,
        SUM(rt.rental_fee) as rental_revenue,
        AVG(JULIANDAY(rt.actual_return_date) - JULIANDAY(rt.rental_date)) as avg_rental_days,
        r.total_quantity - r.available_quantity as currently_rented,
        CASE 
          WHEN r.available_quantity = 0 THEN 'fully_rented'
          WHEN r.available_quantity <= r.total_quantity * 0.2 THEN 'low_availability'
          ELSE 'available'
        END as availability_status
      FROM rentals r
      LEFT JOIN rental_transactions rt ON r.id = rt.rental_id
        AND DATE(rt.created_at) >= DATE('now', 'start of month')
      ${dojoFilter}
      GROUP BY r.id
      ORDER BY rental_revenue DESC
    `).bind(...params).all();

    return new Response(JSON.stringify({
      inventory: {
        products: productInventory.results,
        rentals: rentalInventory.results
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get inventory analytics error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get inventory analytics',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

export { router as analyticsRoutes };
