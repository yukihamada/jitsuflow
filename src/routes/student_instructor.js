/**
 * 生徒-インストラクター関係管理API
 * 担当インストラクター設定・進捗管理
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';

const router = Router();

// 生徒の担当インストラクター一覧取得
router.get('/api/students/:studentId/instructors', async (request) => {
  try {
    const { studentId } = request.params;
    
    // アクセス権限チェック（本人または管理者のみ）
    if (request.user.userId !== parseInt(studentId) && request.user.role !== 'admin') {
      return new Response(JSON.stringify({
        error: 'Unauthorized'
      }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // 担当インストラクター一覧取得
    const assignments = await request.env.DB.prepare(`
      SELECT 
        sia.*,
        u.name as instructor_name,
        u.email as instructor_email,
        u.belt_rank as instructor_belt,
        u.instructor_bio,
        u.instructor_specialties,
        d.name as dojo_name,
        AVG(ir.overall_rating) as avg_rating,
        COUNT(DISTINCT ir.id) as total_ratings
      FROM student_instructor_assignments sia
      JOIN users u ON sia.instructor_id = u.id
      JOIN dojos d ON sia.dojo_id = d.id
      LEFT JOIN instructor_ratings ir ON u.id = ir.instructor_id
      WHERE sia.student_id = ? AND sia.status = 'active'
      GROUP BY sia.id
      ORDER BY sia.assignment_type, sia.created_at DESC
    `).bind(studentId).all();
    
    // お気に入りインストラクター取得
    const favorites = await request.env.DB.prepare(`
      SELECT 
        fi.*,
        u.name as instructor_name,
        u.email as instructor_email,
        u.belt_rank as instructor_belt
      FROM favorite_instructors fi
      JOIN users u ON fi.instructor_id = u.id
      WHERE fi.student_id = ?
      ORDER BY fi.created_at DESC
    `).bind(studentId).all();
    
    return new Response(JSON.stringify({
      assignments: assignments.results,
      favorites: favorites.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get student instructors error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get instructors',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 担当インストラクター設定
router.post('/api/students/:studentId/instructors', async (request) => {
  try {
    const { studentId } = request.params;
    const { 
      instructor_id, 
      dojo_id, 
      assignment_type = 'primary',
      notes 
    } = await request.json();
    
    // アクセス権限チェック
    if (request.user.userId !== parseInt(studentId) && request.user.role !== 'admin') {
      return new Response(JSON.stringify({
        error: 'Unauthorized'
      }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // インストラクターの存在確認
    const instructor = await request.env.DB.prepare(`
      SELECT u.*, ida.dojo_id 
      FROM users u
      JOIN instructor_dojo_assignments ida ON u.id = ida.instructor_id
      WHERE u.id = ? AND u.role = 'instructor' 
        AND ida.dojo_id = ? AND ida.status = 'active'
    `).bind(instructor_id, dojo_id).first();
    
    if (!instructor) {
      return new Response(JSON.stringify({
        error: 'Invalid instructor',
        message: '指定されたインストラクターは利用できません'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // 既存の同タイプ担当を無効化
    if (assignment_type === 'primary') {
      await request.env.DB.prepare(`
        UPDATE student_instructor_assignments 
        SET status = 'inactive', end_date = ?, updated_at = ?
        WHERE student_id = ? AND dojo_id = ? 
          AND assignment_type = 'primary' AND status = 'active'
      `).bind(
        new Date().toISOString(),
        new Date().toISOString(),
        studentId,
        dojo_id
      ).run();
    }
    
    // 新しい担当設定を作成
    const result = await request.env.DB.prepare(`
      INSERT INTO student_instructor_assignments (
        student_id, instructor_id, dojo_id, assignment_type,
        status, start_date, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      studentId,
      instructor_id,
      dojo_id,
      assignment_type,
      'active',
      new Date().toISOString(),
      notes,
      new Date().toISOString(),
      new Date().toISOString()
    ).run();
    
    return new Response(JSON.stringify({
      message: 'Instructor assigned successfully',
      assignment_id: result.meta.last_row_id
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Assign instructor error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to assign instructor',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 担当解除
router.delete('/api/students/:studentId/instructors/:assignmentId', async (request) => {
  try {
    const { studentId, assignmentId } = request.params;
    
    // アクセス権限チェック
    if (request.user.userId !== parseInt(studentId) && request.user.role !== 'admin') {
      return new Response(JSON.stringify({
        error: 'Unauthorized'
      }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    const result = await request.env.DB.prepare(`
      UPDATE student_instructor_assignments 
      SET status = 'inactive', end_date = ?, updated_at = ?
      WHERE id = ? AND student_id = ?
    `).bind(
      new Date().toISOString(),
      new Date().toISOString(),
      assignmentId,
      studentId
    ).run();
    
    if (result.changes === 0) {
      return new Response(JSON.stringify({
        error: 'Assignment not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    return new Response(JSON.stringify({
      message: 'Instructor unassigned successfully'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Unassign instructor error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to unassign instructor',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// お気に入りインストラクター追加/削除
router.post('/api/students/:studentId/favorite-instructors', async (request) => {
  try {
    const { studentId } = request.params;
    const { instructor_id, action } = await request.json();
    
    // アクセス権限チェック
    if (request.user.userId !== parseInt(studentId)) {
      return new Response(JSON.stringify({
        error: 'Unauthorized'
      }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    if (action === 'add') {
      // お気に入り追加
      await request.env.DB.prepare(`
        INSERT OR IGNORE INTO favorite_instructors (
          student_id, instructor_id, created_at
        ) VALUES (?, ?, ?)
      `).bind(studentId, instructor_id, new Date().toISOString()).run();
      
      return new Response(JSON.stringify({
        message: 'Instructor added to favorites'
      }), {
        status: 201,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
      
    } else if (action === 'remove') {
      // お気に入り削除
      await request.env.DB.prepare(`
        DELETE FROM favorite_instructors 
        WHERE student_id = ? AND instructor_id = ?
      `).bind(studentId, instructor_id).run();
      
      return new Response(JSON.stringify({
        message: 'Instructor removed from favorites'
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    return new Response(JSON.stringify({
      error: 'Invalid action'
    }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Manage favorite instructor error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to manage favorite instructor',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 学習進捗記録取得
router.get('/api/students/:studentId/progress', async (request) => {
  try {
    const { studentId } = request.params;
    const url = new URL(request.url);
    const instructorId = url.searchParams.get('instructor_id');
    
    // アクセス権限チェック
    const isStudent = request.user.userId === parseInt(studentId);
    const isInstructor = request.user.role === 'instructor' && 
                        (!instructorId || request.user.userId === parseInt(instructorId));
    const isAdmin = request.user.role === 'admin';
    
    if (!isStudent && !isInstructor && !isAdmin) {
      return new Response(JSON.stringify({
        error: 'Unauthorized'
      }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    let query = `
      SELECT 
        spr.*,
        u.name as instructor_name
      FROM student_progress_records spr
      JOIN users u ON spr.instructor_id = u.id
      WHERE spr.student_id = ?
    `;
    
    const params = [studentId];
    
    if (instructorId) {
      query += ' AND spr.instructor_id = ?';
      params.push(instructorId);
    }
    
    query += ' ORDER BY spr.recorded_date DESC, spr.created_at DESC';
    
    const progress = await request.env.DB.prepare(query).bind(...params).all();
    
    // カテゴリー別集計
    const summary = {};
    progress.results.forEach(record => {
      if (!summary[record.technique_category]) {
        summary[record.technique_category] = {
          techniques: {},
          avg_proficiency: 0,
          count: 0
        };
      }
      
      summary[record.technique_category].techniques[record.technique_name] = record.proficiency_level;
      summary[record.technique_category].count++;
    });
    
    // 平均値計算
    Object.keys(summary).forEach(category => {
      const levels = Object.values(summary[category].techniques);
      summary[category].avg_proficiency = levels.reduce((a, b) => a + b, 0) / levels.length;
    });
    
    return new Response(JSON.stringify({
      progress: progress.results,
      summary
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get student progress error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get progress',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 利用可能なインストラクター一覧
router.get('/api/dojos/:dojoId/available-instructors', async (request) => {
  try {
    const { dojoId } = request.params;
    
    const instructors = await request.env.DB.prepare(`
      SELECT 
        u.id,
        u.name,
        u.email,
        u.belt_rank,
        u.instructor_bio,
        u.instructor_specialties,
        u.hourly_rate,
        AVG(ir.overall_rating) as avg_rating,
        COUNT(DISTINCT ir.id) as total_ratings,
        COUNT(DISTINCT sia.student_id) as total_students
      FROM users u
      JOIN instructor_dojo_assignments ida ON u.id = ida.instructor_id
      LEFT JOIN instructor_ratings ir ON u.id = ir.instructor_id
      LEFT JOIN student_instructor_assignments sia ON u.id = sia.instructor_id 
        AND sia.status = 'active'
      WHERE u.role = 'instructor' 
        AND ida.dojo_id = ? 
        AND ida.status = 'active'
      GROUP BY u.id
      ORDER BY avg_rating DESC, u.name
    `).bind(dojoId).all();
    
    return new Response(JSON.stringify({
      instructors: instructors.results.map(instructor => ({
        ...instructor,
        specialties: instructor.instructor_specialties ? 
          JSON.parse(instructor.instructor_specialties) : []
      }))
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get available instructors error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get available instructors',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

export { router as studentInstructorRoutes };