
-- 1. Find the **top 10 most viewed posts**.


SELECT 
	-- bp.blog_post_id,
	pv.view_count
	
FROM post_view_count pv
ORDER BY view_count DESC

LIMIT 10;

SELECT 
	 bp.blog_post_id,
	 bp.title,
	pv.view_count
	
FROM blog_posts bp
JOIN post_view_count pv
	ON pv.blog_post_id = bp.blog_post_id
ORDER BY pv.view_count DESC

LIMIT 10;


-- 2. Find the **top 10 most viewed posts** which one published.

SELECT
    bp.blog_post_id,
    bp.title,
    COALESCE(pv.view_count, 0) AS view_count
FROM blog_posts bp
LEFT JOIN post_view_count pv
ON pv.blog_post_id = bp.blog_post_id
WHERE bp.post_status = 'published'
ORDER BY view_count DESC
LIMIT 10;



-- 3. Find the **top 10 most viewed posts** along with the author's name and post title.

SELECT
    bp.blog_post_id,
    bp.title,
	a.first_name || ' ' || a.last_name AS full_name,
    COALESCE(pv.view_count, 0) AS view_count
FROM blog_posts bp
JOIN post_view_count pv
	ON pv.blog_post_id = bp.blog_post_id
JOIN authors a
	ON a.author_id = bp.author_id
WHERE bp.post_status = 'published'
ORDER BY view_count DESC
LIMIT 10;




-- 4. Find the **most active authors** based on the number of posts they have published.

SELECT
    a.author_id,
    a.first_name || ' ' || a.last_name AS full_name,
    COUNT(bp.blog_post_id) AS total_posts
FROM authors a
JOIN blog_posts bp
    ON bp.author_id = a.author_id
WHERE a.author_status = 'active'
AND bp.post_status = 'published'
GROUP BY a.author_id, a.first_name, a.last_name
ORDER BY total_posts DESC
LIMIT 10;


-- 5. Find the posts with the **highest number of comments**.

SELECT 
  bp.blog_post_id,
  bp.title,
  COUNT(c.comment_id) AS total_comment
FROM comments c
JOIN blog_posts bp
	ON bp.blog_post_id = c.blog_post_id
GROUP BY  bp.blog_post_id, bp.title
ORDER BY total_comment DESC;





-- 6.Calculate a **viral score** for each post using:

--    * Views = 1 point
--    * Comments = 3 points

--    Return the top 10 posts.

SELECT
    bp.blog_post_id,
    bp.title,
    COUNT(c.comment_id) AS total_comments,
    pvc.view_count AS total_views,
    (pvc.view_count + COUNT(c.comment_id) * 3) AS viral_score
FROM blog_posts bp
JOIN post_view_count pvc
    ON pvc.blog_post_id = bp.blog_post_id
LEFT JOIN comments c
    ON c.blog_post_id = bp.blog_post_id
WHERE bp.post_status = 'published'
GROUP BY
    bp.blog_post_id,
    bp.title,
    pvc.view_count
ORDER BY viral_score DESC
LIMIT 10;


-- 7. Retrieve the **10 latest posts** for a homepage feed.

SELECT
    blog_post_id,
    title,
    published_at,
    content
FROM blog_posts
WHERE post_status = 'published'
ORDER BY published_at DESC
LIMIT 10;



-- 8.Build a homepage feed showing:

--    * Post ID
--    * Title
--    * Creation date
--    * Author username
--    * View count
--    * Comment count


SELECT
    bp.blog_post_id,
    bp.title,
    bp.created_at,
    a.first_name || ' ' || a.last_name AS author_name,
    COALESCE(vc.view_count, 0) AS view_count,
    COUNT(c.comment_id) AS comment_count
FROM blog_posts bp
JOIN authors a
    ON a.author_id = bp.author_id
LEFT JOIN post_view_count vc
    ON vc.blog_post_id = bp.blog_post_id
LEFT JOIN comments c
    ON c.blog_post_id = bp.blog_post_id
WHERE bp.post_status = 'published'
GROUP BY
    bp.blog_post_id,
    bp.title,
    bp.created_at,
    a.first_name,
    a.last_name,
    vc.view_count
ORDER BY bp.published_at DESC
LIMIT 10;



