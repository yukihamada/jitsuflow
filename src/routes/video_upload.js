/**
 * 動画アップロードAPI
 * Cloudflare R2を使用した動画ファイル管理
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';

const router = Router();

// 動画アップロード用の署名付きURL生成
router.post('/api/videos/upload-url', async (request) => {
  try {
    const { 
      title, 
      description, 
      category,
      difficulty_level,
      access_type = 'members_only',
      file_name,
      file_size,
      mime_type
    } = await request.json();
    
    // バリデーション
    if (!title || !file_name || !file_size || !mime_type) {
      return new Response(JSON.stringify({
        error: 'Missing required fields',
        message: 'title, file_name, file_size, mime_type are required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // MIMEタイプチェック（動画のみ許可）
    const allowedMimeTypes = ['video/mp4', 'video/webm', 'video/quicktime', 'video/x-msvideo'];
    if (!allowedMimeTypes.includes(mime_type)) {
      return new Response(JSON.stringify({
        error: 'Invalid file type',
        message: 'Only video files are allowed'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // ファイルサイズ制限（1GB）
    const maxSize = 1024 * 1024 * 1024; // 1GB
    if (file_size > maxSize) {
      return new Response(JSON.stringify({
        error: 'File too large',
        message: 'Maximum file size is 1GB'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // ユニークなファイル名生成
    const timestamp = Date.now();
    const randomId = Math.random().toString(36).substring(2, 15);
    const fileExtension = file_name.split('.').pop();
    const cloudflareKey = `videos/${timestamp}-${randomId}.${fileExtension}`;
    
    // データベースに動画レコード作成
    const videoResult = await request.env.DB.prepare(`
      INSERT INTO videos (
        title, description, category, difficulty_level,
        instructor_id, url, duration, thumbnail_url,
        view_count, is_premium, created_at, updated_at,
        file_url, file_size, mime_type, cloudflare_id,
        processing_status, uploaded_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      title,
      description || '',
      category || 'general',
      difficulty_level || 'beginner',
      request.user.role === 'instructor' ? request.user.userId : null,
      '', // URLは後で更新
      0, // durationは後で更新
      '', // thumbnailは後で生成
      0,
      access_type === 'premium' ? 1 : 0,
      new Date().toISOString(),
      new Date().toISOString(),
      '', // file_urlは後で更新
      file_size,
      mime_type,
      cloudflareKey,
      'uploading',
      request.user.userId
    ).run();
    
    const videoId = videoResult.meta.last_row_id;
    
    // アクセス権限設定
    await request.env.DB.prepare(`
      INSERT INTO video_access_permissions (
        video_id, permission_type, permission_value, created_at
      ) VALUES (?, ?, ?, ?)
    `).bind(
      videoId,
      access_type,
      access_type === 'specific_students' ? '[]' : null,
      new Date().toISOString()
    ).run();
    
    // R2署名付きURLを生成
    const r2 = request.env.R2_BUCKET;
    const uploadUrl = await r2.createMultipartUpload(cloudflareKey, {
      httpMetadata: {
        contentType: mime_type,
      },
      customMetadata: {
        videoId: videoId.toString(),
        uploadedBy: request.user.userId.toString(),
        title: title
      }
    });
    
    return new Response(JSON.stringify({
      video_id: videoId,
      upload_url: uploadUrl.uploadId,
      cloudflare_key: cloudflareKey,
      message: 'Upload URL created successfully'
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Create upload URL error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to create upload URL',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 動画アップロード完了処理
router.post('/api/videos/:videoId/complete-upload', async (request) => {
  try {
    const { videoId } = request.params;
    const { cloudflare_key } = await request.json();
    
    // 動画レコード取得
    const video = await request.env.DB.prepare(
      'SELECT * FROM videos WHERE id = ? AND uploaded_by = ?'
    ).bind(videoId, request.user.userId).first();
    
    if (!video) {
      return new Response(JSON.stringify({
        error: 'Video not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // R2からファイル情報取得
    const r2 = request.env.R2_BUCKET;
    const object = await r2.head(cloudflare_key);
    
    if (!object) {
      return new Response(JSON.stringify({
        error: 'Upload failed',
        message: 'File not found in storage'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // 公開URLを生成
    const publicUrl = `https://videos.jitsuflow.com/${cloudflare_key}`;
    
    // データベース更新
    await request.env.DB.prepare(`
      UPDATE videos 
      SET 
        url = ?,
        file_url = ?,
        processing_status = ?,
        updated_at = ?
      WHERE id = ?
    `).bind(
      publicUrl,
      publicUrl,
      'completed',
      new Date().toISOString(),
      videoId
    ).run();
    
    // サムネイル生成をキューに追加（Workers Queue使用）
    if (request.env.VIDEO_PROCESSING_QUEUE) {
      await request.env.VIDEO_PROCESSING_QUEUE.send({
        type: 'generate_thumbnail',
        videoId: videoId,
        cloudflareKey: cloudflare_key
      });
    }
    
    return new Response(JSON.stringify({
      message: 'Upload completed successfully',
      video_id: videoId,
      url: publicUrl
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Complete upload error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to complete upload',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 動画一覧取得（アクセス権限考慮）
router.get('/api/videos', async (request) => {
  try {
    const url = new URL(request.url);
    const category = url.searchParams.get('category');
    const instructor_id = url.searchParams.get('instructor_id');
    const limit = parseInt(url.searchParams.get('limit')) || 20;
    const offset = parseInt(url.searchParams.get('offset')) || 0;
    
    let query = `
      SELECT 
        v.*,
        u.name as instructor_name,
        vap.permission_type,
        vap.permission_value,
        COUNT(DISTINCT vv.id) as actual_view_count
      FROM videos v
      LEFT JOIN users u ON v.instructor_id = u.id
      LEFT JOIN video_access_permissions vap ON v.id = vap.video_id
      LEFT JOIN video_views vv ON v.id = vv.video_id
      WHERE v.processing_status = 'completed'
    `;
    
    const params = [];
    
    // カテゴリーフィルター
    if (category) {
      query += ' AND v.category = ?';
      params.push(category);
    }
    
    // インストラクターフィルター
    if (instructor_id) {
      query += ' AND v.instructor_id = ?';
      params.push(instructor_id);
    }
    
    // アクセス権限フィルター
    if (request.user.role !== 'admin') {
      query += ` AND (
        vap.permission_type = 'public' OR
        (vap.permission_type = 'members_only' AND ? IS NOT NULL) OR
        (vap.permission_type = 'specific_students' AND 
         JSON_EXTRACT(vap.permission_value, '$') LIKE '%' || ? || '%')
      )`;
      params.push(request.user.userId, request.user.userId);
    }
    
    query += ' GROUP BY v.id ORDER BY v.created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);
    
    const videos = await request.env.DB.prepare(query).bind(...params).all();
    
    return new Response(JSON.stringify({
      videos: videos.results,
      pagination: {
        limit,
        offset,
        has_more: videos.results.length === limit
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get videos error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get videos',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 動画削除
router.delete('/api/videos/:videoId', async (request) => {
  try {
    const { videoId } = request.params;
    
    // 動画情報取得
    const video = await request.env.DB.prepare(`
      SELECT * FROM videos 
      WHERE id = ? AND (uploaded_by = ? OR ? = 'admin')
    `).bind(videoId, request.user.userId, request.user.role).first();
    
    if (!video) {
      return new Response(JSON.stringify({
        error: 'Video not found or unauthorized'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // R2からファイル削除
    if (video.cloudflare_id) {
      const r2 = request.env.R2_BUCKET;
      await r2.delete(video.cloudflare_id);
    }
    
    // データベースから削除（関連データも自動削除）
    await request.env.DB.prepare(
      'DELETE FROM videos WHERE id = ?'
    ).bind(videoId).run();
    
    return new Response(JSON.stringify({
      message: 'Video deleted successfully'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Delete video error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to delete video',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 動画視聴記録
router.post('/api/videos/:videoId/view', async (request) => {
  try {
    const { videoId } = request.params;
    const { watch_duration } = await request.json();
    
    // 視聴記録作成または更新
    await request.env.DB.prepare(`
      INSERT INTO video_views (
        video_id, user_id, view_date, watch_duration, created_at
      ) VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(video_id, user_id, view_date) DO UPDATE SET
        watch_duration = watch_duration + excluded.watch_duration
    `).bind(
      videoId,
      request.user.userId,
      new Date().toISOString().split('T')[0],
      watch_duration || 0,
      new Date().toISOString()
    ).run();
    
    // 視聴回数更新
    await request.env.DB.prepare(
      'UPDATE videos SET view_count = view_count + 1 WHERE id = ?'
    ).bind(videoId).run();
    
    return new Response(JSON.stringify({
      message: 'View recorded'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Record view error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to record view',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 動画アクセス権限更新
router.put('/api/videos/:videoId/permissions', async (request) => {
  try {
    const { videoId } = request.params;
    const { permission_type, permission_value } = await request.json();
    
    // 権限チェック（アップロード者または管理者のみ）
    const video = await request.env.DB.prepare(`
      SELECT * FROM videos 
      WHERE id = ? AND (uploaded_by = ? OR ? = 'admin')
    `).bind(videoId, request.user.userId, request.user.role).first();
    
    if (!video) {
      return new Response(JSON.stringify({
        error: 'Video not found or unauthorized'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // アクセス権限更新
    await request.env.DB.prepare(`
      UPDATE video_access_permissions 
      SET permission_type = ?, permission_value = ?
      WHERE video_id = ?
    `).bind(permission_type, permission_value, videoId).run();
    
    return new Response(JSON.stringify({
      message: 'Permissions updated successfully'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Update permissions error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to update permissions',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

export { router as videoUploadRoutes };