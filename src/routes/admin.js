/**
 * Admin routes for managing products, users, etc.
 */

// Update Product
export async function updateProduct(request) {
  try {
    const productId = request.params.id;
    const { name, price, stock_quantity, description, category } = await request.json();
    
    // Validate input
    if (!name && price === undefined && stock_quantity === undefined) {
      return new Response(JSON.stringify({
        error: 'No fields to update',
        message: 'Provide at least one field to update'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Build update query dynamically
    const updates = [];
    const params = [];
    
    if (name) {
      updates.push('name = ?');
      params.push(name);
    }
    if (price !== undefined) {
      updates.push('price = ?');
      params.push(price);
    }
    if (stock_quantity !== undefined) {
      updates.push('stock_quantity = ?');
      params.push(stock_quantity);
    }
    if (description !== undefined) {
      updates.push('description = ?');
      params.push(description);
    }
    if (category) {
      updates.push('category = ?');
      params.push(category);
    }
    
    updates.push('updated_at = ?');
    params.push(new Date().toISOString());
    
    params.push(productId);
    
    const result = await request.env.DB.prepare(
      `UPDATE products SET ${updates.join(', ')} WHERE id = ?`
    ).bind(...params).run();
    
    if (result.meta.changes === 0) {
      return new Response(JSON.stringify({
        error: 'Product not found',
        message: 'No product found with the given ID'
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Get updated product
    const product = await request.env.DB.prepare(
      'SELECT * FROM products WHERE id = ?'
    ).bind(productId).first();
    
    return new Response(JSON.stringify({
      message: 'Product updated successfully',
      product
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Update product error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to update product',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// Delete Product
export async function deleteProduct(request) {
  try {
    const productId = request.params.id;
    
    // Soft delete by setting is_active to 0
    const result = await request.env.DB.prepare(
      'UPDATE products SET is_active = 0, updated_at = ? WHERE id = ? AND is_active = 1'
    ).bind(new Date().toISOString(), productId).run();
    
    if (result.meta.changes === 0) {
      return new Response(JSON.stringify({
        error: 'Product not found',
        message: 'No active product found with the given ID'
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    return new Response(JSON.stringify({
      message: 'Product deleted successfully'
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Delete product error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to delete product',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// Get Single Product
export async function getProduct(request) {
  try {
    const productId = request.params.id;
    
    const product = await request.env.DB.prepare(
      'SELECT * FROM products WHERE id = ? AND is_active = 1'
    ).bind(productId).first();
    
    if (!product) {
      return new Response(JSON.stringify({
        error: 'Product not found',
        message: 'No product found with the given ID'
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    return new Response(JSON.stringify(product), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get product error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to get product',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// Delete User (Admin only)
export async function deleteUser(request) {
  try {
    // Check if requester is admin
    if (request.user.role !== 'admin') {
      return new Response(JSON.stringify({
        error: 'Unauthorized',
        message: 'Only admins can delete users'
      }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    const userId = request.params.id;
    
    // Prevent self-deletion
    if (userId == request.user.userId) {
      return new Response(JSON.stringify({
        error: 'Cannot delete self',
        message: 'You cannot delete your own account'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Soft delete by setting is_active to 0
    const result = await request.env.DB.prepare(
      'UPDATE users SET is_active = 0, updated_at = ? WHERE id = ? AND is_active = 1'
    ).bind(new Date().toISOString(), userId).run();
    
    if (result.meta.changes === 0) {
      return new Response(JSON.stringify({
        error: 'User not found',
        message: 'No active user found with the given ID'
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    return new Response(JSON.stringify({
      message: 'User deleted successfully'
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Delete user error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to delete user',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// Delete Video
export async function deleteVideo(request) {
  try {
    const videoId = request.params.id;
    
    // Check if requester has permission (admin or instructor who owns the video)
    const video = await request.env.DB.prepare(
      'SELECT instructor_id FROM videos WHERE id = ?'
    ).bind(videoId).first();
    
    if (!video) {
      return new Response(JSON.stringify({
        error: 'Video not found',
        message: 'No video found with the given ID'
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    if (request.user.role !== 'admin' && video.instructor_id !== request.user.userId) {
      return new Response(JSON.stringify({
        error: 'Unauthorized',
        message: 'You do not have permission to delete this video'
      }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Delete video
    const result = await request.env.DB.prepare(
      'DELETE FROM videos WHERE id = ?'
    ).bind(videoId).run();
    
    return new Response(JSON.stringify({
      message: 'Video deleted successfully'
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Delete video error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to delete video',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// Get All Users (Admin only)
export async function getAllUsers(request) {
  try {
    // Check if requester is admin
    if (request.user.role !== 'admin') {
      return new Response(JSON.stringify({
        error: 'Unauthorized',
        message: 'Only admins can view all users'
      }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    const users = await request.env.DB.prepare(
      'SELECT id, email, name, role, created_at FROM users WHERE is_active = 1 ORDER BY created_at DESC'
    ).all();
    
    return new Response(JSON.stringify(users.results || []), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get users error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to get users',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}