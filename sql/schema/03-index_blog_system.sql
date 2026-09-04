-- =====================================================
-- Foreign-key / relationship INDEXES
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




-- =====================================================
--Advanced candidate indexes 
-- =====================================================


-- 1. Find the **top 10 most viewed posts** and determine which indexes would improve this query.


CREATE INDEX idx_post_count_view_desc
ON post_view_count(view_count DESC);



-- 2. Optimize a query that retrieves **recent published posts ordered by `published_at`**.

CREATE INDEX idx_blog_posts_published_recent 
ON blog_posts (post_status, published_at DESC); 


-- 4. Determine which indexes should be created for a query filtering posts by `post_status` and ordering by `published_at`.

CREATE INDEX idx_blog_posts_published_at
ON blog_posts (published_at DESC)
WHERE post_status = 'published';  //partial indexing 


-- 5.  Determine the appropriate indexes for finding **recent posts from the last 7 days**.


CREATE INDEX idx_blog_posts_published_at
ON blog_posts (published_at DESC)
WHERE post_status = 'published';


-- 6.  Determine which indexes would improve queries filtering `comments` by `post_id`.


CREATE INDEX idx_comments_post
ON comments(blog_post_id);


-- 7.  Determine which indexes would improve queries filtering `post_view_logs` by:

-- * `post_id`
-- * `user_id`
-- * `viewed_at`


CREATE INDEX idx_post_view_logs_viewed_at
ON post_view_logs(viewed_at);



--  7. Design indexes for efficiently retrieving the **top posts per author**.



CREATE INDEX idx_blog_posts_author
ON blog_posts(author_id);


