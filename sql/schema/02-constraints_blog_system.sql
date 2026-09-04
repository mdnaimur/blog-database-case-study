-- =====================================================
-- AUTHORS
-- =====================================================

ALTER TABLE authors
ADD CONSTRAINT fk_author_user
FOREIGN KEY (author_id)
REFERENCES users(user_id)
ON DELETE CASCADE;

-- =====================================================
-- BLOG POSTS
-- =====================================================

ALTER TABLE blog_posts
ADD CONSTRAINT fk_post_author
FOREIGN KEY (author_id)
REFERENCES authors(author_id)
ON DELETE CASCADE;

-- =====================================================
-- POST <-> CATEGORY
-- =====================================================

ALTER TABLE post_categories
ADD CONSTRAINT fk_pc_post
FOREIGN KEY (blog_post_id)
REFERENCES blog_posts(blog_post_id)
ON DELETE CASCADE;

ALTER TABLE post_categories
ADD CONSTRAINT fk_pc_category
FOREIGN KEY (cat_id)
REFERENCES categories(cat_id)
ON DELETE CASCADE;

-- =====================================================
-- COMMENTS
-- =====================================================

ALTER TABLE comments
ADD CONSTRAINT fk_comment_post
FOREIGN KEY (blog_post_id)
REFERENCES blog_posts(blog_post_id)
ON DELETE CASCADE;

ALTER TABLE comments
ADD CONSTRAINT fk_comment_user
FOREIGN KEY (user_id)
REFERENCES users(user_id)
ON DELETE CASCADE;

-- =====================================================
-- POST VIEW COUNT
-- =====================================================

ALTER TABLE post_view_count
ADD CONSTRAINT fk_viewcount_post
FOREIGN KEY (blog_post_id)
REFERENCES blog_posts(blog_post_id)
ON DELETE CASCADE;

-- =====================================================
-- POST VIEW LOGS
-- =====================================================

ALTER TABLE post_view_logs
ADD CONSTRAINT fk_viewlog_post
FOREIGN KEY (blog_post_id)
REFERENCES blog_posts(blog_post_id)
ON DELETE CASCADE;

ALTER TABLE post_view_logs
ADD CONSTRAINT fk_viewlog_user
FOREIGN KEY (user_id)
REFERENCES users(user_id)
ON DELETE SET NULL;