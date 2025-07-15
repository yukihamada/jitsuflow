/**
 * Member management routes for JitsuFlow API
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';
import { requireAdmin } from '../middleware/auth';
import { hashPassword } from '../utils/crypto';

const router = Router();

// Get all members (admin only)
router.get('/api/members', async (request) => {
  try {
    // Check admin permission
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;

    // Get all members with their subscription status
    const members = await request.env.DB.prepare(`
      SELECT 
        u.id,
        u.email,
        u.name,
        u.phone,
        u.role,
        u.status,
        u.belt_rank,
        u.birth_date,
        u.primary_dojo_id,
        d.name as primary_dojo_name,
        u.profile_image_url,
        u.joined_at,
        u.last_login_at,
        u.created_at,
        u.updated_at,
        CASE WHEN s.id IS NOT NULL AND s.status = 'active' THEN 1 ELSE 0 END as has_active_subscription
      FROM users u
      LEFT JOIN dojos d ON u.primary_dojo_id = d.id
      LEFT JOIN subscriptions s ON u.id = s.user_id AND s.status = 'active'
      ORDER BY u.created_at DESC
    `).all();

    // Get affiliated dojos for each member
    const membersWithAffiliations = await Promise.all(
      members.results.map(async (member) => {
        const affiliations = await request.env.DB.prepare(`
          SELECT dojo_id 
          FROM user_dojo_affiliations 
          WHERE user_id = ?
        `).bind(member.id).all();

        return {
          ...member,
          affiliated_dojo_ids: affiliations.results.map(a => a.dojo_id),
          has_active_subscription: member.has_active_subscription === 1
        };
      })
    );

    return new Response(JSON.stringify({
      members: membersWithAffiliations
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get members error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get members',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Create new member (admin only)
router.post('/api/members', async (request) => {
  try {
    // Check admin permission
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;

    const { email, name, phone, role = 'user', belt_rank, primary_dojo_id } = await request.json();

    // Validate input
    if (!email || !name) {
      return new Response(JSON.stringify({
        error: 'Missing required fields',
        message: 'Email and name are required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Check if user already exists
    const existingUser = await request.env.DB.prepare(
      'SELECT id FROM users WHERE email = ?'
    ).bind(email).first();

    if (existingUser) {
      return new Response(JSON.stringify({
        error: 'User already exists',
        message: 'Email is already registered'
      }), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Generate random password
    const randomPassword = Math.random().toString(36).slice(-8);
    const hashedPassword = await hashPassword(randomPassword);

    // Create user
    const result = await request.env.DB.prepare(`
      INSERT INTO users (
        email, password_hash, name, phone, role, status, belt_rank, 
        primary_dojo_id, joined_at, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      email,
      hashedPassword,
      name,
      phone,
      role,
      'active',
      belt_rank,
      primary_dojo_id,
      new Date().toISOString(),
      new Date().toISOString(),
      new Date().toISOString()
    ).run();

    // Add dojo affiliation if provided
    if (primary_dojo_id) {
      await request.env.DB.prepare(`
        INSERT INTO user_dojo_affiliations (user_id, dojo_id, is_primary, joined_at)
        VALUES (?, ?, ?, ?)
      `).bind(
        result.meta.last_row_id,
        primary_dojo_id,
        true,
        new Date().toISOString()
      ).run();
    }

    // Get created member
    const member = await request.env.DB.prepare(`
      SELECT 
        u.id,
        u.email,
        u.name,
        u.phone,
        u.role,
        u.status,
        u.belt_rank,
        u.primary_dojo_id,
        d.name as primary_dojo_name,
        u.joined_at,
        u.created_at,
        u.updated_at,
        0 as has_active_subscription
      FROM users u
      LEFT JOIN dojos d ON u.primary_dojo_id = d.id
      WHERE u.id = ?
    `).bind(result.meta.last_row_id).first();

    // TODO: Send welcome email with temporary password

    return new Response(JSON.stringify({
      message: 'Member created successfully',
      member: {
        ...member,
        affiliated_dojo_ids: primary_dojo_id ? [primary_dojo_id] : [],
        has_active_subscription: false
      },
      temporary_password: randomPassword // Remove in production
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Create member error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to create member',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Update member (admin only)
router.patch('/api/members/:id', async (request) => {
  try {
    // Check admin permission
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;

    const { id } = request.params;
    const { name, phone, belt_rank, primary_dojo_id } = await request.json();

    // Build update query
    const updates = [];
    const params = [];

    if (name !== undefined) {
      updates.push('name = ?');
      params.push(name);
    }
    if (phone !== undefined) {
      updates.push('phone = ?');
      params.push(phone);
    }
    if (belt_rank !== undefined) {
      updates.push('belt_rank = ?');
      params.push(belt_rank);
    }
    if (primary_dojo_id !== undefined) {
      updates.push('primary_dojo_id = ?');
      params.push(primary_dojo_id);
    }

    if (updates.length === 0) {
      return new Response(JSON.stringify({
        error: 'No updates provided'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    updates.push('updated_at = ?');
    params.push(new Date().toISOString());
    params.push(id);

    // Update user
    const result = await request.env.DB.prepare(
      `UPDATE users SET ${updates.join(', ')} WHERE id = ?`
    ).bind(...params).run();

    if (result.changes === 0) {
      return new Response(JSON.stringify({
        error: 'Member not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Update primary dojo affiliation if changed
    if (primary_dojo_id !== undefined) {
      // Remove old primary
      await request.env.DB.prepare(
        'UPDATE user_dojo_affiliations SET is_primary = 0 WHERE user_id = ?'
      ).bind(id).run();

      // Check if affiliation exists
      const existing = await request.env.DB.prepare(
        'SELECT id FROM user_dojo_affiliations WHERE user_id = ? AND dojo_id = ?'
      ).bind(id, primary_dojo_id).first();

      if (existing) {
        // Update existing
        await request.env.DB.prepare(
          'UPDATE user_dojo_affiliations SET is_primary = 1 WHERE id = ?'
        ).bind(existing.id).run();
      } else {
        // Create new
        await request.env.DB.prepare(
          'INSERT INTO user_dojo_affiliations (user_id, dojo_id, is_primary, joined_at) VALUES (?, ?, ?, ?)'
        ).bind(id, primary_dojo_id, true, new Date().toISOString()).run();
      }
    }

    // Get updated member
    const member = await request.env.DB.prepare(`
      SELECT 
        u.*,
        d.name as primary_dojo_name,
        CASE WHEN s.id IS NOT NULL AND s.status = 'active' THEN 1 ELSE 0 END as has_active_subscription
      FROM users u
      LEFT JOIN dojos d ON u.primary_dojo_id = d.id
      LEFT JOIN subscriptions s ON u.id = s.user_id AND s.status = 'active'
      WHERE u.id = ?
    `).bind(id).first();

    return new Response(JSON.stringify({
      message: 'Member updated successfully',
      member: {
        ...member,
        has_active_subscription: member.has_active_subscription === 1
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Update member error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to update member',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Delete member (admin only)
router.delete('/api/members/:id', async (request) => {
  try {
    // Check admin permission
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;

    const { id } = request.params;

    // Check if member exists
    const member = await request.env.DB.prepare(
      'SELECT id FROM users WHERE id = ?'
    ).bind(id).first();

    if (!member) {
      return new Response(JSON.stringify({
        error: 'Member not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Delete related data
    await request.env.DB.batch([
      request.env.DB.prepare('DELETE FROM bookings WHERE user_id = ?').bind(id),
      request.env.DB.prepare('DELETE FROM team_memberships WHERE user_id = ?').bind(id),
      request.env.DB.prepare('DELETE FROM user_dojo_affiliations WHERE user_id = ?').bind(id),
      request.env.DB.prepare('DELETE FROM subscriptions WHERE user_id = ?').bind(id),
    ]);

    // Delete user
    await request.env.DB.prepare('DELETE FROM users WHERE id = ?').bind(id).run();

    return new Response(JSON.stringify({
      message: 'Member deleted successfully'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Delete member error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to delete member',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Change member role (admin only)
router.patch('/api/members/:id/role', async (request) => {
  try {
    // Check admin permission
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;

    const { id } = request.params;
    const { role } = await request.json();

    if (!['user', 'instructor', 'admin'].includes(role)) {
      return new Response(JSON.stringify({
        error: 'Invalid role',
        message: 'Role must be user, instructor, or admin'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const result = await request.env.DB.prepare(
      'UPDATE users SET role = ?, updated_at = ? WHERE id = ?'
    ).bind(role, new Date().toISOString(), id).run();

    if (result.changes === 0) {
      return new Response(JSON.stringify({
        error: 'Member not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({
      message: 'Role updated successfully',
      role
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Change role error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to change role',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Change member status (admin only)
router.patch('/api/members/:id/status', async (request) => {
  try {
    // Check admin permission
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;

    const { id } = request.params;
    const { status } = await request.json();

    if (!['active', 'inactive', 'suspended'].includes(status)) {
      return new Response(JSON.stringify({
        error: 'Invalid status',
        message: 'Status must be active, inactive, or suspended'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const result = await request.env.DB.prepare(
      'UPDATE users SET status = ?, updated_at = ? WHERE id = ?'
    ).bind(status, new Date().toISOString(), id).run();

    if (result.changes === 0) {
      return new Response(JSON.stringify({
        error: 'Member not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({
      message: 'Status updated successfully',
      status
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Change status error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to change status',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

export { router as memberRoutes };
