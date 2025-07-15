/**
 * Teams and affiliations routes for JitsuFlow API
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';

const router = Router();

// Get all dojos
router.get('/api/dojos', async (request) => {
  try {
    const dojos = await request.env.DB.prepare(
      'SELECT * FROM dojos ORDER BY name'
    ).all();

    return new Response(JSON.stringify({
      dojos: dojos.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get dojos error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get dojos',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get user's teams
router.get('/api/teams', async (request) => {
  try {
    const url = new URL(request.url);
    const userId = url.searchParams.get('user_id') || 1;

    const teams = await request.env.DB.prepare(
      `SELECT t.*, d.name as dojo_name, tm.role, tm.status as membership_status
       FROM teams t
       JOIN dojos d ON t.dojo_id = d.id
       LEFT JOIN team_memberships tm ON t.id = tm.team_id AND tm.user_id = ?
       WHERE tm.user_id IS NOT NULL OR t.created_by = ?
       ORDER BY t.name`
    ).bind(userId, userId).all();

    return new Response(JSON.stringify({
      teams: teams.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get teams error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get teams',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Create new team
router.post('/api/teams', async (request) => {
  try {
    const { name, description, dojo_id, created_by = 1 } = await request.json();

    // Validate input
    if (!name || !dojo_id) {
      return new Response(JSON.stringify({
        error: 'Missing required fields',
        message: 'name and dojo_id are required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Create team
    const result = await request.env.DB.prepare(
      'INSERT INTO teams (name, description, dojo_id, created_by, created_at) VALUES (?, ?, ?, ?, ?)'
    ).bind(
      name,
      description,
      dojo_id,
      created_by,
      new Date().toISOString()
    ).run();

    // Add creator as admin member
    await request.env.DB.prepare(
      'INSERT INTO team_memberships (user_id, team_id, role, status, joined_at) VALUES (?, ?, ?, ?, ?)'
    ).bind(
      created_by,
      result.insertId,
      'admin',
      'active',
      new Date().toISOString()
    ).run();

    return new Response(JSON.stringify({
      message: 'Team created successfully',
      team_id: result.insertId
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Create team error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to create team',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Join team
router.post('/api/teams/:id/join', async (request) => {
  try {
    const { id } = request.params;
    const { user_id = 1 } = await request.json();

    // Check if team exists
    const team = await request.env.DB.prepare(
      'SELECT * FROM teams WHERE id = ?'
    ).bind(id).first();

    if (!team) {
      return new Response(JSON.stringify({
        error: 'Team not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Check if already member
    const existingMembership = await request.env.DB.prepare(
      'SELECT * FROM team_memberships WHERE user_id = ? AND team_id = ?'
    ).bind(user_id, id).first();

    if (existingMembership) {
      return new Response(JSON.stringify({
        error: 'Already member',
        message: 'User is already a member of this team'
      }), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Add membership
    await request.env.DB.prepare(
      'INSERT INTO team_memberships (user_id, team_id, role, status, joined_at) VALUES (?, ?, ?, ?, ?)'
    ).bind(
      user_id,
      id,
      'member',
      'active',
      new Date().toISOString()
    ).run();

    return new Response(JSON.stringify({
      message: 'Successfully joined team'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Join team error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to join team',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get user's dojo affiliations
router.get('/api/affiliations', async (request) => {
  try {
    const url = new URL(request.url);
    const userId = url.searchParams.get('user_id') || 1;

    const affiliations = await request.env.DB.prepare(
      `SELECT uda.*, d.name, d.address, d.instructor, d.pricing_info
       FROM user_dojo_affiliations uda
       JOIN dojos d ON uda.dojo_id = d.id
       WHERE uda.user_id = ?
       ORDER BY uda.is_primary DESC, d.name`
    ).bind(userId).all();

    return new Response(JSON.stringify({
      affiliations: affiliations.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get affiliations error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get affiliations',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Add dojo affiliation
router.post('/api/affiliations', async (request) => {
  try {
    const { user_id = 1, dojo_id, is_primary = false } = await request.json();

    // Check if already affiliated
    const existing = await request.env.DB.prepare(
      'SELECT * FROM user_dojo_affiliations WHERE user_id = ? AND dojo_id = ?'
    ).bind(user_id, dojo_id).first();

    if (existing) {
      return new Response(JSON.stringify({
        error: 'Already affiliated',
        message: 'User is already affiliated with this dojo'
      }), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // If setting as primary, unset other primary affiliations
    if (is_primary) {
      await request.env.DB.prepare(
        'UPDATE user_dojo_affiliations SET is_primary = FALSE WHERE user_id = ?'
      ).bind(user_id).run();
    }

    // Add affiliation
    await request.env.DB.prepare(
      'INSERT INTO user_dojo_affiliations (user_id, dojo_id, is_primary, joined_at) VALUES (?, ?, ?, ?)'
    ).bind(
      user_id,
      dojo_id,
      is_primary,
      new Date().toISOString()
    ).run();

    return new Response(JSON.stringify({
      message: 'Dojo affiliation added successfully'
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Add affiliation error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to add affiliation',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Update primary dojo
router.patch('/api/affiliations/:dojo_id/primary', async (request) => {
  try {
    const { dojo_id } = request.params;
    const { user_id = 1 } = await request.json();

    // Unset all primary affiliations for user
    await request.env.DB.prepare(
      'UPDATE user_dojo_affiliations SET is_primary = FALSE WHERE user_id = ?'
    ).bind(user_id).run();

    // Set new primary
    const result = await request.env.DB.prepare(
      'UPDATE user_dojo_affiliations SET is_primary = TRUE WHERE user_id = ? AND dojo_id = ?'
    ).bind(user_id, dojo_id).run();

    if (result.changes === 0) {
      return new Response(JSON.stringify({
        error: 'Affiliation not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({
      message: 'Primary dojo updated successfully'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Update primary dojo error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to update primary dojo',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

export { router as teamRoutes };
