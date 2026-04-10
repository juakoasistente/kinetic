-- ============================================
-- KINETIC — Supabase Database Setup
-- Run this entire file in Supabase SQL Editor
-- ============================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================
-- 1. PROFILES
-- ============================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nickname TEXT NOT NULL DEFAULT '',
    bio TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    tier TEXT NOT NULL DEFAULT 'free',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone"
    ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================
-- 2. SESSIONS
-- ============================================
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT '',
    vehicle TEXT NOT NULL DEFAULT '',
    date TIMESTAMPTZ NOT NULL DEFAULT now(),
    distance DOUBLE PRECISION NOT NULL DEFAULT 0,
    duration DOUBLE PRECISION NOT NULL DEFAULT 0,
    has_video BOOLEAN NOT NULL DEFAULT false,
    thumbnail_url TEXT,
    video_url TEXT,
    location_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own sessions"
    ON sessions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions"
    ON sessions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions"
    ON sessions FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own sessions"
    ON sessions FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_sessions_user_date ON sessions(user_id, date DESC);
CREATE INDEX idx_sessions_search ON sessions USING gin(name gin_trgm_ops);

-- ============================================
-- 3. TELEMETRY DATA
-- ============================================
CREATE TABLE telemetry_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL UNIQUE REFERENCES sessions(id) ON DELETE CASCADE,
    max_speed DOUBLE PRECISION NOT NULL DEFAULT 0,
    avg_speed DOUBLE PRECISION NOT NULL DEFAULT 0,
    distance DOUBLE PRECISION NOT NULL DEFAULT 0,
    elevation DOUBLE PRECISION NOT NULL DEFAULT 0,
    max_altitude DOUBLE PRECISION NOT NULL DEFAULT 0,
    fuel_consumption DOUBLE PRECISION NOT NULL DEFAULT 0,
    peak_g_force DOUBLE PRECISION NOT NULL DEFAULT 0,
    engine_temp DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE telemetry_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own telemetry"
    ON telemetry_data FOR SELECT
    USING (session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid()));

CREATE POLICY "Users can insert own telemetry"
    ON telemetry_data FOR INSERT
    WITH CHECK (session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid()));

CREATE POLICY "Users can delete own telemetry"
    ON telemetry_data FOR DELETE
    USING (session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid()));

CREATE INDEX idx_telemetry_session ON telemetry_data(session_id);

-- ============================================
-- 4. USER SETTINGS
-- ============================================
CREATE TABLE user_settings (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    show_speed BOOLEAN NOT NULL DEFAULT true,
    show_distance BOOLEAN NOT NULL DEFAULT true,
    show_time BOOLEAN NOT NULL DEFAULT false,
    show_gps BOOLEAN NOT NULL DEFAULT true,
    use_metric BOOLEAN NOT NULL DEFAULT true,
    language TEXT NOT NULL DEFAULT 'en',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own settings"
    ON user_settings FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own settings"
    ON user_settings FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own settings"
    ON user_settings FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 5. AUTO-CREATE PROFILE + SETTINGS ON SIGNUP
-- ============================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, nickname)
    VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', ''));

    INSERT INTO user_settings (user_id)
    VALUES (NEW.id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================
-- 6. POSTS
-- ============================================
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    session_id UUID REFERENCES sessions(id) ON DELETE SET NULL,
    description TEXT NOT NULL DEFAULT '',
    visibility TEXT NOT NULL DEFAULT 'public'
        CHECK (visibility IN ('public', 'unlisted', 'private')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public posts are viewable by everyone"
    ON posts FOR SELECT
    USING (
        visibility = 'public'
        OR auth.uid() = user_id
    );

CREATE POLICY "Users can insert own posts"
    ON posts FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own posts"
    ON posts FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts"
    ON posts FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_posts_user ON posts(user_id);
CREATE INDEX idx_posts_feed ON posts(created_at DESC) WHERE visibility = 'public';

-- ============================================
-- 7. POST MEDIA
-- ============================================
CREATE TABLE post_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    media_type TEXT NOT NULL DEFAULT 'image'
        CHECK (media_type IN ('image', 'video')),
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE post_media ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Post media viewable with post"
    ON post_media FOR SELECT
    USING (post_id IN (
        SELECT id FROM posts
        WHERE visibility = 'public' OR auth.uid() = user_id
    ));

CREATE POLICY "Users can insert own post media"
    ON post_media FOR INSERT
    WITH CHECK (post_id IN (SELECT id FROM posts WHERE user_id = auth.uid()));

CREATE POLICY "Users can delete own post media"
    ON post_media FOR DELETE
    USING (post_id IN (SELECT id FROM posts WHERE user_id = auth.uid()));

CREATE INDEX idx_post_media_post ON post_media(post_id, sort_order);

-- ============================================
-- 8. LIKES
-- ============================================
CREATE TABLE likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, post_id)
);

ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Likes are viewable by everyone"
    ON likes FOR SELECT USING (true);

CREATE POLICY "Users can insert own likes"
    ON likes FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own likes"
    ON likes FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_likes_post ON likes(post_id);
CREATE INDEX idx_likes_user ON likes(user_id);

-- ============================================
-- 9. COMMENTS
-- ============================================
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Comments are viewable by everyone"
    ON comments FOR SELECT USING (true);

CREATE POLICY "Users can insert own comments"
    ON comments FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments"
    ON comments FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
    ON comments FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_comments_post ON comments(post_id, created_at);

-- ============================================
-- 10. BOOKMARKS
-- ============================================
CREATE TABLE bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, post_id)
);

ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own bookmarks"
    ON bookmarks FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own bookmarks"
    ON bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own bookmarks"
    ON bookmarks FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_bookmarks_user ON bookmarks(user_id);

-- ============================================
-- 11. CLIPS
-- ============================================
CREATE TABLE clips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    session_id UUID REFERENCES sessions(id) ON DELETE SET NULL,
    title TEXT NOT NULL DEFAULT '',
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE clips ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own clips"
    ON clips FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own clips"
    ON clips FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own clips"
    ON clips FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own clips"
    ON clips FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_clips_user ON clips(user_id, created_at DESC);

-- ============================================
-- HELPER: Update sessions RLS to allow public read
-- when linked to a public post (needed for feed)
-- ============================================
CREATE POLICY "Sessions viewable via public posts"
    ON sessions FOR SELECT
    USING (
        id IN (
            SELECT session_id FROM posts
            WHERE visibility = 'public' AND session_id IS NOT NULL
        )
    );

-- ============================================
-- DONE! Now create these Storage buckets manually:
-- 1. avatars     (public)
-- 2. sessions    (private)
-- 3. public      (public) — for legal HTMLs
-- 4. post-media  (public) — for post images/videos
-- ============================================
