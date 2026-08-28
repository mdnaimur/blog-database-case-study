-- =====================================================
-- 1. Fix typo: commnets -> comments
-- =====================================================

ALTER TABLE commnets RENAME TO comments;


-- =====================================================
-- 2. Add NOT NULL constraints
-- =====================================================

ALTER TABLE users
ALTER COLUMN role SET NOT NULL;


ALTER TABLE authors
ALTER COLUMN author_status SET NOT NULL;


ALTER TABLE blog_posts
ALTER COLUMN post_status SET NOT NULL;


ALTER TABLE comments
ALTER COLUMN created_at SET NOT NULL;


ALTER TABLE post_view_count
ALTER COLUMN view_count SET NOT NULL;


ALTER TABLE post_view_logs
ALTER COLUMN viewed_at SET NOT NULL;


-- =====================================================
-- 3. Add missing DEFAULT values
-- =====================================================

ALTER TABLE authors
ALTER COLUMN created_at SET DEFAULT CURRENT_TIMESTAMP;


ALTER TABLE authors
ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP;


ALTER TABLE comments
ALTER COLUMN created_at SET DEFAULT CURRENT_TIMESTAMP;


ALTER TABLE post_view_count
ALTER COLUMN view_count SET DEFAULT 0;


ALTER TABLE post_view_logs
ALTER COLUMN viewed_at SET DEFAULT CURRENT_TIMESTAMP;


-- =====================================================
-- 4. Fix foreign key delete behavior
-- =====================================================

-- authors -> users
ALTER TABLE authors
DROP CONSTRAINT authors_author_id_fkey;


ALTER TABLE authors
ADD CONSTRAINT fk_author_user
FOREIGN KEY (author_id)
REFERENCES users(user_id)
ON DELETE CASCADE;


-- blog_posts -> authors
ALTER TABLE blog_posts
DROP CONSTRAINT blog_posts_author_id_fkey;


ALTER TABLE blog_posts
ADD CONSTRAINT fk_post_author
FOREIGN KEY (author_id)
REFERENCES authors(author_id)
ON DELETE CASCADE;


-- post_categories -> blog_posts
ALTER TABLE post_categories
DROP CONSTRAINT post_categories_blog_post_id_fkey;


ALTER TABLE post_categories
ADD CONSTRAINT fk_pc_post
FOREIGN KEY (blog_post_id)
REFERENCES blog_posts(blog_post_id)
ON DELETE CASCADE;


-- post_categories -> categories
ALTER TABLE post_categories
DROP CONSTRAINT post_categories_cat_id_fkey;


ALTER TABLE post_categories
ADD CONSTRAINT fk_pc_category
FOREIGN KEY (cat_id)
REFERENCES categories(cat_id)
ON DELETE CASCADE;


-- comments -> blog_posts
ALTER TABLE comments
DROP CONSTRAINT comments_blog_post_id_fkey;


ALTER TABLE comments
ADD CONSTRAINT fk_comment_post
FOREIGN KEY (blog_post_id)
REFERENCES blog_posts(blog_post_id)
ON DELETE CASCADE;


-- comments -> users
ALTER TABLE comments
DROP CONSTRAINT comments_user_id_fkey;


ALTER TABLE comments
ADD CONSTRAINT fk_comment_user
FOREIGN KEY (user_id)
REFERENCES users(user_id)
ON DELETE CASCADE;


-- post_view_count -> blog_posts
ALTER TABLE post_view_count
DROP CONSTRAINT post_view_count_blog_post_id_fkey;


ALTER TABLE post_view_count
ADD CONSTRAINT fk_viewcount_post
FOREIGN KEY (blog_post_id)
REFERENCES blog_posts(blog_post_id)
ON DELETE CASCADE;


-- post_view_logs -> blog_posts
ALTER TABLE post_view_logs
DROP CONSTRAINT post_view_logs_blog_post_id_fkey;


ALTER TABLE post_view_logs
ADD CONSTRAINT fk_viewlog_post
FOREIGN KEY (blog_post_id)
REFERENCES blog_posts(blog_post_id)
ON DELETE CASCADE;


-- post_view_logs -> users
ALTER TABLE post_view_logs
DROP CONSTRAINT post_view_logs_user_id_fkey;


ALTER TABLE post_view_logs
ADD CONSTRAINT fk_viewlog_user
FOREIGN KEY (user_id)
REFERENCES users(user_id)
ON DELETE SET NULL;


-- =====================================================
-- 5. Fix post_view_logs anonymous user support
-- =====================================================

ALTER TABLE post_view_logs
ALTER COLUMN user_id DROP NOT NULL;


-- =====================================================
-- 6. Rename indexes after comments typo fix
-- =====================================================

ALTER INDEX commnets_blog_post_id_idx
RENAME TO idx_comments_post;


ALTER INDEX commnets_user_id_idx
RENAME TO idx_comments_user;