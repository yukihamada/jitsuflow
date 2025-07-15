-- Videos table for training content
CREATE TABLE IF NOT EXISTS videos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    instructor_id INTEGER NOT NULL,
    duration INTEGER NOT NULL, -- duration in seconds
    thumbnail_url TEXT,
    video_url TEXT NOT NULL,
    is_premium BOOLEAN DEFAULT 0,
    status TEXT DEFAULT 'draft' CHECK(status IN ('draft', 'published', 'archived')),
    view_count INTEGER DEFAULT 0,
    category TEXT,
    tags TEXT, -- JSON array of tags
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    published_at DATETIME DEFAULT NULL,
    FOREIGN KEY (instructor_id) REFERENCES users(id)
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_videos_status ON videos(status);
CREATE INDEX IF NOT EXISTS idx_videos_premium ON videos(is_premium);
CREATE INDEX IF NOT EXISTS idx_videos_instructor ON videos(instructor_id);

-- Sample videos
INSERT INTO videos (title, description, instructor_id, duration, thumbnail_url, video_url, is_premium, status, category, tags, published_at) VALUES
('基本的なガードパス', '初心者向けのガードパステクニック。正しいポジショニングと圧力のかけ方を解説。', 1, 600, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 'https://example.com/videos/guard-pass-basics.mp4', 0, 'published', 'fundamentals', '["guard_pass","basics","beginner"]', CURRENT_TIMESTAMP),
('ベリンボロの基礎', 'モダン柔術の代表的なテクニック、ベリンボロの基本的な動きと原理を解説。', 1, 900, 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800', 'https://example.com/videos/berimbolo-basics.mp4', 1, 'published', 'advanced', '["berimbolo","guard","advanced"]', CURRENT_TIMESTAMP),
('アームバーの連続技', 'アームバーからの様々な連続技とトランジション。', 1, 720, 'https://images.unsplash.com/photo-1549719386-74dfcbf7dbed?w=800', 'https://example.com/videos/armbar-chains.mp4', 0, 'published', 'submissions', '["armbar","submission","chains"]', CURRENT_TIMESTAMP),
('デラヒーバガードの攻防', 'デラヒーバガードの設定方法と、そこからのスイープとサブミッション。', 1, 1200, 'https://images.unsplash.com/photo-1552072092-7f9a2aa1a5f5?w=800', 'https://example.com/videos/dlr-guard.mp4', 1, 'published', 'guard', '["dlr","guard","sweep"]', CURRENT_TIMESTAMP),
('エスケープドリル集', '各種ポジションからのエスケープをドリル形式で練習。', 1, 480, 'https://images.unsplash.com/photo-1598266663439-2056e6aacfde?w=800', 'https://example.com/videos/escape-drills.mp4', 0, 'published', 'drills', '["escape","drills","defense"]', CURRENT_TIMESTAMP);