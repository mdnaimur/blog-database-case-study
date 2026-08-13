-- 1. Rank all posts by their **view count** using `ROW_NUMBER()`.


SELECT
	bp.blog_post_id,
	bp.title,
	vc.view_count,
	ROW_NUMBER() OVER(
		ORDER BY vc.view_count DESC
	) AS rank
FROM blog_posts bp
LEFT JOIN post_view_count vc
	ON vc.blog_post_id = bp.blog_post_Id



-- 2. Find the **most viewed post for each author**.



SELECT
    author_id,
    first_name,
    title,
    view_count
FROM (
    SELECT
        a.author_id,
        a.first_name,
        bp.title,
        COALESCE(pv.view_count, 0) AS view_count,
        ROW_NUMBER() OVER (
            PARTITION BY a.author_id
            ORDER BY COALESCE(pv.view_count, 0) DESC
        ) AS rn
    FROM authors a
    JOIN blog_posts bp
        ON bp.author_id = a.author_id
       AND bp.post_status = 'published'
    LEFT JOIN post_view_count pv
        ON pv.blog_post_id = bp.blog_post_id
    WHERE a.author_status = 'active'
) ranked
WHERE rn = 1;

-- > NOW for more clear in CTE

WITH ranked_posts AS (
    SELECT
        a.author_id,
        a.first_name,
        bp.title,
        COALESCE(pv.view_count, 0) AS view_count,
        ROW_NUMBER() OVER (
            PARTITION BY a.author_id
            ORDER BY COALESCE(pv.view_count, 0) DESC
        ) AS rn
    FROM authors a
    JOIN blog_posts bp
        ON bp.author_id = a.author_id
    LEFT JOIN post_view_count pv
        ON pv.blog_post_id = bp.blog_post_id
    WHERE a.author_status = 'active'
      AND bp.post_status = 'published'
)

SELECT
    author_id,
    first_name,
    title,
    view_count,
	rn AS RANK
FROM ranked_posts
WHERE rn = 1;




-- 3. Find the **top 3 most viewed posts for each author**.



SELECT 
	author_id,
	first_name,
	title,
	view_count,
	rank
FROM(
	SELECT
		a.author_id,
		a.first_name,
		bp.title,
		COALESCE (pvc.view_count,0) AS view_count,
	ROW_NUMBER() OVER(
		PARTITION BY  a.author_id
		ORDER BY COALESCE(pvc.view_count,0) DESC
	) AS rank
	FROM authors a
	 JOIN blog_posts bp
		ON bp.author_id = a.author_id
	LEFT JOIN post_view_count pvc
		ON pvc.blog_post_id = bp.blog_post_id
	WHERE bp.post_status = 'published'
	) ranked
WHERE rank <= 3
ORDER BY author_id, rank;




-- > with CTE



WITH ranked_posts AS (
    SELECT
        a.author_id,
        a.first_name,
        bp.title,
        COALESCE(pvc.view_count, 0) AS view_count,
        ROW_NUMBER() OVER (
            PARTITION BY a.author_id
            ORDER BY COALESCE(pvc.view_count, 0) DESC
        ) AS rank
    FROM authors a
    JOIN blog_posts bp
        ON bp.author_id = a.author_id
    LEFT JOIN post_view_count pvc
        ON pvc.blog_post_id = bp.blog_post_id
    WHERE bp.post_status = 'published'
)

SELECT
    author_id,
    first_name,
    title,
    view_count,
    rank
FROM ranked_posts
WHERE rank <= 3
ORDER BY author_id, rank;



-- 4. Find the **most popular post in each category** based on views.

SELECT
    blog_post_id,
    category_name,
    title,
    view_count
FROM (
    SELECT
        bp.blog_post_id,
        c.category_name,
        bp.title,
        COALESCE(pvc.view_count, 0) AS view_count,
        DENSE_RANK() OVER (
            PARTITION BY c.cat_id
            ORDER BY COALESCE(pvc.view_count, 0) DESC
        ) AS rank
    FROM blog_posts bp
    JOIN post_categories pc
        ON pc.blog_post_id = bp.blog_post_id
    JOIN categories c
        ON c.cat_id = pc.cat_id
    LEFT JOIN post_view_count pvc
        ON pvc.blog_post_id = bp.blog_post_id
) ranked
WHERE rank = 1;




-- 5.  Create a **user engagement leaderboard** by ranking users according to their total comments and views.


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
),

user_activity AS (
    SELECT
        u.user_id,
        u.username,
        COALESCE(ct.total_comments, 0) AS total_comments,
        COALESCE(vt.total_views, 0) AS total_views
    FROM users u
    LEFT JOIN comment_total ct
        ON ct.user_id = u.user_id
    LEFT JOIN view_total vt
        ON vt.user_id = u.user_id
)
SELECT
    user_id,
    username,
    total_comments,
    total_views,
    RANK() OVER (
        ORDER BY total_comments DESC, total_views DESC
    ) AS ranking_user
FROM user_activity
ORDER BY ranking_user;


-- subquery


SELECT
    user_id,
    username,
    total_comments,
    total_views,
    RANK() OVER (
        ORDER BY total_comments DESC, total_views DESC
    ) AS ranking_user
FROM (
    SELECT
        u.user_id,
        u.username,
        COUNT(DISTINCT c.comment_id) AS total_comments,
        COUNT(DISTINCT v.view_log_id) AS total_views
    FROM users u
    LEFT JOIN comments c
        ON c.user_id = u.user_id
    LEFT JOIN post_view_logs v
        ON v.user_id = u.user_id
    GROUP BY u.user_id, u.username
) AS user_totals;
	
	




-- 7. Calculate the **running number of views for each post over time**

SELECT
    blog_post_id,
    DATE(viewed_at) AS view_date,
    COUNT(*) AS daily_views,
    SUM(COUNT(*)) OVER (
        PARTITION BY blog_post_id
        ORDER BY DATE(viewed_at)
    ) AS running_views
FROM post_view_logs
GROUP BY
    blog_post_id,
    DATE(viewed_at)
ORDER BY
    blog_post_id,
    view_date;