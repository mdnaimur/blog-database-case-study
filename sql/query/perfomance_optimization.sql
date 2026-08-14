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



