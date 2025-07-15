/**
 * Instructor management routes for JitsuFlow API (Admin)
 * インストラクター管理API - 管理者用
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';
import { requireAdmin } from '../middleware/auth';

const router = Router();

// Get all instructors
router.get('/api/instructors', async (request) => {
  try {
    const instructors = await request.env.DB.prepare(`
      SELECT 
        id,
        name,
        email,
        phone,
        belt_rank,
        years_experience,
        bio,
        profile_image_url,
        is_active,
        created_at
      FROM instructors
      WHERE is_active = 1
      ORDER BY name
    `).all();
    
    return new Response(JSON.stringify(instructors.results), {
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

// Get instructor details with dojos
router.get('/api/instructors/:id', async (request) => {
  try {
    const { id } = request.params;
    
    const instructor = await request.env.DB.prepare(`
      SELECT * FROM instructors WHERE id = ?
    `).bind(id).first();
    
    if (!instructor) {
      return new Response(JSON.stringify({
        error: 'Instructor not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Get assigned dojos
    const dojos = await request.env.DB.prepare(`
      SELECT 
        d.id as dojo_id,
        d.name as dojo_name,
        id.role,
        id.start_date,
        id.is_active
      FROM instructor_dojos id
      JOIN dojos d ON id.dojo_id = d.id
      WHERE id.instructor_id = ? AND id.is_active = 1
      ORDER BY d.name
    `).bind(id).all();
    
    return new Response(JSON.stringify({
      ...instructor,
      dojos: dojos.results
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

// Get instructor's assigned dojos
router.get('/api/instructors/:id/dojos', async (request) => {
  try {
    const { id } = request.params;
    
    const dojos = await request.env.DB.prepare(`
      SELECT 
        d.id,
        d.name as dojo_name,
        d.address,
        d.website,
        id.role,
        id.start_date,
        id.is_active
      FROM instructor_dojos id
      JOIN dojos d ON id.dojo_id = d.id
      WHERE id.instructor_id = ? AND id.is_active = 1
      ORDER BY d.name
    `).bind(id).all();
    
    return new Response(JSON.stringify(dojos.results), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get instructor dojos error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to get instructor dojos',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Create new instructor (Admin only)
router.post('/api/instructors', async (request) => {
  try {
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;
    
    const {
      name,
      email,
      phone,
      belt_rank,
      years_experience,
      bio,
      profile_image_url,
      dojos = []
    } = await request.json();
    
    // Validate required fields
    if (!name || !belt_rank) {
      return new Response(JSON.stringify({
        error: 'Missing required fields',
        message: '名前と帯ランクは必須です'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Create instructor
    const result = await request.env.DB.prepare(`
      INSERT INTO instructors (
        name, email, phone, belt_rank, years_experience, bio, profile_image_url, is_active, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 1, datetime('now'))
    `).bind(
      name,
      email || null,
      phone || null,
      belt_rank,
      years_experience || 0,
      bio || null,
      profile_image_url || null
    ).run();
    
    const instructorId = result.meta.last_row_id;
    
    // Assign to dojos
    for (const dojo of dojos) {
      await request.env.DB.prepare(`
        INSERT INTO instructor_dojos (
          instructor_id, dojo_id, role, start_date, is_active
        ) VALUES (?, ?, ?, ?, 1)
      `).bind(
        instructorId,
        dojo.dojo_id,
        dojo.role || 'instructor',
        dojo.start_date || new Date().toISOString().split('T')[0]
      ).run();
    }
    
    return new Response(JSON.stringify({
      message: 'Instructor created successfully',
      instructor_id: instructorId
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Create instructor error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to create instructor',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Update instructor (Admin only)
router.put('/api/instructors/:id', async (request) => {
  try {
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;
    
    const { id } = request.params;
    const {
      name,
      email,
      phone,
      belt_rank,
      years_experience,
      bio,
      profile_image_url,
      is_active,
      dojos
    } = await request.json();
    
    // Update instructor basic info
    await request.env.DB.prepare(`
      UPDATE instructors SET
        name = ?,
        email = ?,
        phone = ?,
        belt_rank = ?,
        years_experience = ?,
        bio = ?,
        profile_image_url = ?,
        is_active = ?,
        updated_at = datetime('now')
      WHERE id = ?
    `).bind(
      name,
      email || null,
      phone || null,
      belt_rank,
      years_experience || 0,
      bio || null,
      profile_image_url || null,
      is_active !== undefined ? is_active : 1,
      id
    ).run();
    
    // Update dojo assignments if provided
    if (dojos !== undefined) {
      // Deactivate all current assignments
      await request.env.DB.prepare(`
        UPDATE instructor_dojos SET is_active = 0 WHERE instructor_id = ?
      `).bind(id).run();
      
      // Add new assignments
      for (const dojo of dojos) {
        await request.env.DB.prepare(`
          INSERT OR REPLACE INTO instructor_dojos (
            instructor_id, dojo_id, role, start_date, is_active
          ) VALUES (?, ?, ?, ?, 1)
        `).bind(
          id,
          dojo.dojo_id,
          dojo.role || 'instructor',
          dojo.start_date || new Date().toISOString().split('T')[0]
        ).run();
      }
    }
    
    return new Response(JSON.stringify({
      message: 'Instructor updated successfully'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Update instructor error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to update instructor',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Delete instructor (Admin only)
router.delete('/api/instructors/:id', async (request) => {
  try {
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;
    
    const { id } = request.params;
    
    // Soft delete - just deactivate
    await request.env.DB.prepare(`
      UPDATE instructors SET is_active = 0, updated_at = datetime('now') WHERE id = ?
    `).bind(id).run();
    
    // Also deactivate all dojo assignments
    await request.env.DB.prepare(`
      UPDATE instructor_dojos SET is_active = 0 WHERE instructor_id = ?
    `).bind(id).run();
    
    return new Response(JSON.stringify({
      message: 'Instructor deleted successfully'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Delete instructor error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to delete instructor',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Assign instructor to dojo (Admin only)
router.post('/api/instructors/:id/dojos', async (request) => {
  try {
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;
    
    const { id } = request.params;
    const { dojo_id, role = 'instructor', start_date } = await request.json();
    
    // Check if assignment already exists
    const existing = await request.env.DB.prepare(`
      SELECT * FROM instructor_dojos 
      WHERE instructor_id = ? AND dojo_id = ?
    `).bind(id, dojo_id).first();
    
    if (existing) {
      // Update existing assignment
      await request.env.DB.prepare(`
        UPDATE instructor_dojos SET 
          role = ?, 
          start_date = ?, 
          is_active = 1 
        WHERE instructor_id = ? AND dojo_id = ?
      `).bind(role, start_date || existing.start_date, id, dojo_id).run();
    } else {
      // Create new assignment
      await request.env.DB.prepare(`
        INSERT INTO instructor_dojos (
          instructor_id, dojo_id, role, start_date, is_active
        ) VALUES (?, ?, ?, ?, 1)
      `).bind(
        id,
        dojo_id,
        role,
        start_date || new Date().toISOString().split('T')[0]
      ).run();
    }
    
    return new Response(JSON.stringify({
      message: 'Instructor assigned to dojo successfully'
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Assign instructor to dojo error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to assign instructor to dojo',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Remove instructor from dojo (Admin only)
router.delete('/api/instructors/:id/dojos/:dojoId', async (request) => {
  try {
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;
    
    const { id, dojoId } = request.params;
    
    await request.env.DB.prepare(`
      UPDATE instructor_dojos SET is_active = 0 
      WHERE instructor_id = ? AND dojo_id = ?
    `).bind(id, dojoId).run();
    
    return new Response(JSON.stringify({
      message: 'Instructor removed from dojo successfully'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Remove instructor from dojo error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to remove instructor from dojo',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

export { router as instructorsAdminRoutes };