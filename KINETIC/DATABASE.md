# KINETIC — Database Schema (Supabase / PostgreSQL)

## Overview

10 tables + Supabase Auth + Storage buckets. All tables use RLS (Row Level Security).

---

## Auth Setup

- **Providers**: Apple, Google (configure in Supabase Dashboard → Authentication → Providers)
- **Apple**: Requires Service ID, Team ID, Key ID, and Private Key from Apple Developer Console
- **Google**: Requires OAuth Client ID and Secret from Google Cloud Console
- **Redirect URL**: `kinetic://auth/callback`

---

## Tables

### 1. `profiles`

Linked 1:1 with `auth.users`. Created automatically on signup via trigger.

```sql
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nickname TEXT NOT NULL DEFAULT '',
    bio TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    tier TEXT NOT NULL DEFAULT 'free',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Public read (for feed), owner write
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone"
    ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
```

### 2. `sessions`

Recorded driving sessions.

```sql
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
```

> Note: For the search index, enable the `pg_trgm` extension first:
> `CREATE EXTENSION IF NOT EXISTS pg_trgm;`

### 3. `telemetry_data`

Per-session telemetry snapshot. One row per session.

```sql
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
```

### 4. `user_settings`

One row per user. Created automatically on signup via trigger.

```sql
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
```

---

## Auto-create profile + settings on signup

```sql
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
```

---

## Social Tables

### 5. `posts`

User-created posts linked to a driving session. Supports public, unlisted, and private visibility.

```sql
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

-- Public posts visible to all; private/unlisted only to owner
CREATE POLICY "Public posts are viewable by everyone"
    ON posts FOR SELECT
    USING (visibility = 'public' OR auth.uid() = user_id);

CREATE POLICY "Users can insert own posts"
    ON posts FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own posts"
    ON posts FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts"
    ON posts FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_posts_user ON posts(user_id);
CREATE INDEX idx_posts_feed ON posts(created_at DESC) WHERE visibility = 'public';
```

### 6. `post_media`

Media attachments (images/videos) for posts. Ordered by `sort_order`.

```sql
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
        SELECT id FROM posts WHERE visibility = 'public' OR auth.uid() = user_id
    ));

CREATE POLICY "Users can insert own post media"
    ON post_media FOR INSERT
    WITH CHECK (post_id IN (SELECT id FROM posts WHERE user_id = auth.uid()));

CREATE POLICY "Users can delete own post media"
    ON post_media FOR DELETE
    USING (post_id IN (SELECT id FROM posts WHERE user_id = auth.uid()));

CREATE INDEX idx_post_media_post ON post_media(post_id, sort_order);
```

### 7. `likes`

One like per user per post (enforced by UNIQUE constraint).

```sql
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
```

### 8. `comments`

Comments on posts. Users can edit/delete their own.

```sql
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
```

### 9. `bookmarks`

Saved/bookmarked posts. Private to each user.

```sql
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
```

### 10. `clips`

Short video clips from driving sessions. Private to each user.

```sql
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
```

> **Note:** An additional RLS policy is added to `sessions` to allow public read access when a session is linked to a public post (needed for the feed).

---

## Storage Buckets

```sql
-- Create buckets in Supabase Dashboard → Storage
-- 1. avatars    — profile pictures (public read)
-- 2. sessions   — session thumbnails and videos (private, owner-only)
-- 3. public     — legal HTMLs (public read)
-- 4. post-media — post images and videos (public read)
```

**Bucket policies:**
- `avatars`: Public read, authenticated insert/update/delete where `auth.uid()::text = (storage.foldername(name))[1]`
- `sessions`: Owner-only read/write where `auth.uid()::text = (storage.foldername(name))[1]`
- `post-media`: Public read, authenticated insert/update/delete where `auth.uid()::text = (storage.foldername(name))[1]`

---

## Entity Relationship

```
auth.users 1──1 profiles 1──* sessions 1──1 telemetry_data
                    │              │
                    │              ├──* clips
                    │              │
                    1──1 user_settings
                    │
                    1──* posts 1──* post_media
                    │     │
                    │     ├──* likes
                    │     ├──* comments
                    │     └──* bookmarks
                    │
                    1──* likes
                    1──* comments
                    1──* bookmarks
                    1──* clips
```

---

## Notes

- All timestamps use `TIMESTAMPTZ` (UTC)
- UUIDs generated with `gen_random_uuid()`
- Distance in kilometers, duration in seconds, speed in km/h, temperature in Celsius
- `tier` field in profiles: `'free'`, `'pro'`, `'gold'` — managed by app logic or Stripe webhooks
