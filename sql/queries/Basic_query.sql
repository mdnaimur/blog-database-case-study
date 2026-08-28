
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



-- 9. Find the **most active users** based on their total views and comments.


SELECT
    u.user_id,
    u.username,
    COALESCE(v.total_views, 0) AS total_views,
    COALESCE(c.total_comments, 0) AS total_comments
FROM users u

LEFT JOIN (
    SELECT
        c.user_id,
        COUNT(*) AS total_comments
    FROM comments c
    JOIN blog_posts bp
        ON bp.blog_post_id = c.blog_post_id
    WHERE bp.post_status = 'published'
    GROUP BY c.user_id
) c
    ON c.user_id = u.user_id

LEFT JOIN (
    SELECT
        c.user_id,
        SUM(pv.view_count) AS total_views
    FROM comments c
    JOIN blog_posts bp
        ON bp.blog_post_id = c.blog_post_id
    JOIN post_view_count pv
        ON pv.blog_post_id = bp.blog_post_id
    WHERE bp.post_status = 'published'
    GROUP BY c.user_id
) v
    ON v.user_id = u.user_id

ORDER BY
    total_views DESC,
    total_comments DESC
LIMIT 20;
;


-- // using ct 

WITH user_posts AS(
	SELECT DISTINCT
		c.user_id,
		c.blog_post_id
	FROM comments c
	JOIN blog_posts bp
		ON bp.blog_post_id = c.blog_post_id
	WHERE bp.post_status = 'published'
),

comment_totals AS (
    SELECT
        c.user_id,
        COUNT(*) AS total_comments
    FROM comments c
    JOIN blog_posts bp
        ON bp.blog_post_id = c.blog_post_id
    WHERE bp.post_status = 'published'
    GROUP BY c.user_id
),

view_totals AS (
    SELECT
        up.user_id,
        SUM(pv.view_count) AS total_views
    FROM user_posts up
    JOIN post_view_count pv
        ON pv.blog_post_id = up.blog_post_id
    GROUP BY up.user_id
)

SELECT
    u.user_id,
    u.username,
    COALESCE(v.total_views, 0) AS total_views,
    COALESCE(c.total_comments, 0) AS total_comments
FROM users u
LEFT JOIN comment_totals c
    ON c.user_id = u.user_id
LEFT JOIN view_totals v
    ON v.user_id = u.user_id
ORDER BY
    total_views DESC,
    total_comments DESC
LIMIT 20;


-- 10. Find each user's:

-- * Total comments
-- * Total views
-- * Activity score
WITH comment_total AS (
    SELECT
        user_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY user_id
),

view_total AS (
    SELECT
        user_id,
        COUNT(*) AS total_views
    FROM post_view_logs
    WHERE user_id IS NOT NULL
    GROUP BY user_id
)

SELECT
    u.user_id,
    u.username,
    COALESCE(ct.total_comments, 0) AS total_comments,
    COALESCE(vt.total_views, 0) AS total_views,
    (
        COALESCE(ct.total_comments, 0) * 3
        + COALESCE(vt.total_views, 0)
    ) AS activity_score
FROM users u
LEFT JOIN comment_total ct
    ON ct.user_id = u.user_id
LEFT JOIN view_total vt
    ON vt.user_id = u.user_id
ORDER BY activity_score DESC;


-- 11. Find the **top 10 trending posts from the last 7 days**, based on views.

SELECT
    bp.blog_post_id,
    bp.title,
    COUNT(pvl.view_log_id) AS views_last_7_days
FROM blog_posts bp
JOIN post_view_logs pvl
    ON pvl.blog_post_id = bp.blog_post_id
WHERE bp.post_status = 'published'
  AND pvl.viewed_at >= NOW() - INTERVAL '7 days'
GROUP BY
    bp.blog_post_id,
    bp.title
ORDER BY views_last_7_days DESC
LIMIT 10;

-- 12. Create a **trend score** using:

-- * Views = 1 point
-- * Comments = 3 points
-- Return the top 10 posts from the last 7 days.

WITH recent_views AS(
	SELECT
		blog_post_id,
		COUNT(*) AS views_last_7days
	FROM post_view_logs
	WHERE viewed_at >= NOW() - INTERVAL '30days'
	GROUP BY blog_post_id	
),

recent_comments AS(
	SELECT
		c.blog_post_id,
		COUNT(*) AS comments_last_7_days
	FROM comments c
	WHERE c.created_at >= NOW() - INTERVAL '30days'
	GROUP BY c.blog_post_id
)

SELECT
	bp.blog_post_id,
	bp.title,
	COALESCE(rv.views_last_7days, 0) AS views_last_7days,
	COALESCE(rc.comments_last_7_days, 0) AS comments_last_7_days,
	(
		COALESCE(rv.views_last_7days, 0) +  COALESCE(rc.comments_last_7_days, 0)*3
	) AS trend_score
FROM blog_posts bp
LEFT JOIN recent_views rv
    ON rv.blog_post_id = bp.blog_post_id
LEFT JOIN recent_comments rc
    ON rc.blog_post_id = bp.blog_post_id
WHERE bp.post_status = 'published'
ORDER BY trend_score DESC
LIMIT 10;


-- 13. Find all posts that **have no comments**.

SELECT
	bp.blog_post_id,
	bp.title,
	COUNT(c.comment_id) AS total_comment
FROM blog_posts bp
LEFT JOIN comments c
	ON c.blog_post_id = bp.blog_post_id
GROUP BY bp.blog_post_id, bp.title
HAVING COUNT(c.comment_id) = 0;



-- 14. Find all posts that **have no comments** using `NOT EXISTS`.

SELECT
	bp.blog_post_id,
	bp.title
FROM blog_posts bp
WHERE NOT EXISTS(
	SELECT 1
	FROM comments c
	WHERE c.blog_post_id = bp.blog_post_id
);



-- 15. Find the **number of posts in each category**, including categories with zero posts.



SELECT
    cg.cat_id,
    cg.category_name,
    COUNT(bp.blog_post_id) AS total_posts
FROM categories cg
LEFT JOIN post_categories pcg
    ON pcg.cat_id = cg.cat_id
LEFT JOIN blog_posts bp
    ON bp.blog_post_id = pcg.blog_post_id
GROUP BY cg.cat_id, cg.category_name;


-- 16. Build an **author directory** showing:

-- * User ID
-- * Username
-- * Bio
-- * Profile picture
-- * Author status
-- * Creation date

SELECT
	u.user_id,
	u.username,
	a.bio,
	a.profile_picture_url as profile_pic,
	a.author_status,
	u.created_at
FROM users u
LEFT JOIN authors a
	ON a.author_id = u.user_id;


    
-- 17.  Find all **banned authors**.

SELECT
	author_id,
	first_name,
	created_at,
	author_status
FROM authors
WHERE author_status = 'banned';