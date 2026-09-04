-- 1. Find the **top 10 most viewed posts** and determine which indexes would improve this query.



CREATE INDEX idx_post_count_view_desc
ON post_view_count(view_count DESC);


EXPLAIN  ANALYZE
SELECT
    bp.blog_post_id,
    bp.title,
    pvc.view_count
FROM blog_posts bp
JOIN post_view_count pvc
    ON pvc.blog_post_id = bp.blog_post_id
ORDER BY pvc.view_count DESC
LIMIT 10;



-- 2. Optimize a query that retrieves **recent published posts ordered by `published_at`**.

CREATE INDEX idx_blog_posts_published_recent 
ON blog_posts (post_status, published_at DESC); 


EXPLAIN ANALYZE SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE post_status = 'published'
ORDER BY published_at DESC
LIMIT 10;


-- 3. Optimize a query that retrieves posts together with their **view counts and comment counts**.


-- **Best Index:**
-- Here for view_count portion already have doing job aggregate viwe count which helps faster. no need index,

EXPLAIN ANALYZE
SELECT
    bp.blog_post_id,
    bp.title,
    COALESCE(pvc.view_count, 0) AS view_count,
    COUNT(c.comment_id) AS comment_count
FROM blog_posts bp
LEFT JOIN post_view_count pvc
    ON pvc.blog_post_id = bp.blog_post_id
LEFT JOIN comments c
    ON c.blog_post_id = bp.blog_post_id
GROUP BY
    bp.blog_post_id,
    bp.title,
    pvc.view_count;



-- 4. Determine which indexes should be created for a query filtering posts by `post_status` and ordering by `published_at`.

CREATE INDEX idx_blog_posts_published_at
ON blog_posts (published_at DESC)
WHERE post_status = 'published';  //partial indexing 

SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE post_status = 'published'
ORDER BY published_at DESC;


-- 5.  Determine the appropriate indexes for finding **recent posts from the last 7 days**.


CREATE INDEX idx_blog_posts_published_at
ON blog_posts (published_at DESC)
WHERE post_status = 'published';

SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE post_status = 'published'
  AND published_at >= NOW() - INTERVAL '7 days'
ORDER BY published_at DESC;



-- 6.  Determine which indexes would improve queries filtering `comments` by `post_id`.


CREATE INDEX idx_comments_post
ON comments(blog_post_id);


SELECT *
FROM comments
WHERE blog_post_id = 100;




-- 7.  Determine which indexes would improve queries filtering `post_view_logs` by:

-- * `post_id`
-- * `user_id`
-- * `viewed_at`


CREATE INDEX idx_post_view_logs_viewed_at
ON post_view_logs(viewed_at);



--  7. Design indexes for efficiently retrieving the **top posts per author**.



CREATE INDEX idx_blog_posts_author
ON blog_posts(author_id);