-- =====================================================
-- ENUMS
-- =====================================================

CREATE TYPE role AS ENUM (
    'admin',
    'author',
    'reader'
);

CREATE TYPE author_status AS ENUM (
    'active',
    'inactive',
    'banned'
);

CREATE TYPE post_status AS ENUM (
    'draft',
    'published',
    'archived'
);

-- =====================================================
-- USERS
-- =====================================================

CREATE TABLE users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role role NOT NULL DEFAULT 'reader',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- AUTHORS
-- =====================================================

CREATE TABLE authors (
    author_id BIGINT PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255),
    bio TEXT,
    profile_picture_url TEXT,
    author_status author_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_author_user
        FOREIGN KEY (author_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);

-- =====================================================
-- BLOG POSTS
-- =====================================================

CREATE TABLE blog_posts (
    blog_post_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    author_id BIGINT NOT NULL,

    title VARCHAR(255) NOT NULL,

    content TEXT NOT NULL,

    post_status post_status NOT NULL DEFAULT 'draft',

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    published_at TIMESTAMP,

    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_post_author
        FOREIGN KEY (author_id)
        REFERENCES authors(author_id)
        ON DELETE CASCADE
);

-- =====================================================
-- CATEGORIES
-- =====================================================

CREATE TABLE categories (

    cat_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    category_name VARCHAR(255) UNIQUE NOT NULL,

    description TEXT

);

-- =====================================================
-- POST <-> CATEGORY
-- Many-to-Many
-- =====================================================

CREATE TABLE post_categories (

    blog_post_id BIGINT NOT NULL,

    cat_id BIGINT NOT NULL,

    PRIMARY KEY (blog_post_id, cat_id),

    CONSTRAINT fk_pc_post
        FOREIGN KEY (blog_post_id)
        REFERENCES blog_posts(blog_post_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_pc_category
        FOREIGN KEY (cat_id)
        REFERENCES categories(cat_id)
        ON DELETE CASCADE

);

-- =====================================================
-- COMMENTS
-- =====================================================

CREATE TABLE comments (

    comment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    content TEXT NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    blog_post_id BIGINT NOT NULL,

    user_id BIGINT NOT NULL,

    CONSTRAINT fk_comment_post
        FOREIGN KEY (blog_post_id)
        REFERENCES blog_posts(blog_post_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_comment_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE

);

-- =====================================================
-- POST VIEW COUNT
-- =====================================================

CREATE TABLE post_view_count (

    blog_post_id BIGINT PRIMARY KEY,

    view_count BIGINT NOT NULL DEFAULT 0,

    CONSTRAINT fk_viewcount_post
        FOREIGN KEY (blog_post_id)
        REFERENCES blog_posts(blog_post_id)
        ON DELETE CASCADE

);

-- =====================================================
-- POST VIEW LOGS
-- =====================================================

CREATE TABLE post_view_logs (

    view_log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    blog_post_id BIGINT NOT NULL,

    user_id BIGINT,

    viewed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_viewlog_post
        FOREIGN KEY (blog_post_id)
        REFERENCES blog_posts(blog_post_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_viewlog_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE SET NULL

);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX idx_blog_posts_author
ON blog_posts(author_id);

CREATE INDEX idx_blog_posts_status
ON blog_posts(post_status);

CREATE INDEX idx_comments_post
ON comments(blog_post_id);

CREATE INDEX idx_comments_user
ON comments(user_id);

CREATE INDEX idx_post_view_logs_post
ON post_view_logs(blog_post_id);

CREATE INDEX idx_post_view_logs_user
ON post_view_logs(user_id);

CREATE INDEX idx_post_categories_category
ON post_categories(cat_id);



SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';