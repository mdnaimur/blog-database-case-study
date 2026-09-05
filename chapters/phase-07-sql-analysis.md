

# Phase 07 — SQL Analysis

## Objective

Analyze the blog system using real-world PostgreSQL queries for content, engagement, user, author, category, and trending analytics.

The queries in this phase focus on **retrieving and analyzing business data**.

This phase demonstrates how the database answers practical application and reporting requirements using:

* Filtering
* Aggregation
* Joins
* CTEs
* Subqueries
* Conditional aggregation
* Window functions
* Ranking
* Running aggregates
* Derived business metrics

Query performance optimization, index design, and execution-plan analysis are covered later in **Phase 08 — Indexing** and **Phase 09 — Query Optimization**.

---

# 7.1 Basic Analytics

## 1. Find the Top 10 Most Viewed Posts

Identify the most viewed posts using the precomputed `post_view_count` table.

```sql
SELECT
    bp.blog_post_id,
    bp.title,
    pvc.view_count
FROM blog_posts bp
JOIN post_view_count pvc
    ON pvc.blog_post_id = bp.blog_post_id
ORDER BY pvc.view_count DESC
LIMIT 10;
```

### Purpose

This query supports a **popular posts** or **most viewed posts** section.

---

## 2. Find the Top 10 Most Viewed Published Posts

Return only published posts while including posts that have no entry in `post_view_count`.

```sql
SELECT
    bp.blog_post_id,
    bp.title,
    COALESCE(pvc.view_count, 0) AS view_count
FROM blog_posts bp
LEFT JOIN post_view_count pvc
    ON pvc.blog_post_id = bp.blog_post_id
WHERE bp.post_status = 'published'
ORDER BY view_count DESC
LIMIT 10;
```

### Why `LEFT JOIN`?

A published post may have zero recorded views.

Using `LEFT JOIN` ensures that such a post remains in the result.

`COALESCE()` converts the missing value to `0`.

---

## 3. Find the Top 10 Most Viewed Published Posts with Author Information

```sql
SELECT
    bp.blog_post_id,
    bp.title,
    a.first_name || ' ' || a.last_name AS author_name,
    COALESCE(pvc.view_count, 0) AS view_count
FROM blog_posts bp
JOIN authors a
    ON a.author_id = bp.author_id
LEFT JOIN post_view_count pvc
    ON pvc.blog_post_id = bp.blog_post_id
WHERE bp.post_status = 'published'
ORDER BY view_count DESC
LIMIT 10;
```

### Purpose

This represents a common application/reporting query where post popularity is displayed together with its author.

---

## 4. Find the Most Active Authors

Determine the most active authors based on the number of published posts.

```sql
SELECT
    a.author_id,
    a.first_name || ' ' || a.last_name AS author_name,
    COUNT(*) AS total_posts
FROM authors a
JOIN blog_posts bp
    ON bp.author_id = a.author_id
WHERE a.author_status = 'active'
  AND bp.post_status = 'published'
GROUP BY
    a.author_id,
    a.first_name,
    a.last_name
ORDER BY total_posts DESC
LIMIT 10;
```

### Purpose

Useful for an author dashboard or administrative analytics.

---

## 5. Find Posts with the Highest Number of Comments

```sql
SELECT
    bp.blog_post_id,
    bp.title,
    COUNT(c.comment_id) AS total_comments
FROM blog_posts bp
LEFT JOIN comments c
    ON c.blog_post_id = bp.blog_post_id
WHERE bp.post_status = 'published'
GROUP BY
    bp.blog_post_id,
    bp.title
ORDER BY total_comments DESC
LIMIT 10;
```

### Why `COUNT(c.comment_id)`?

Because `comment_id` is `NULL` for posts with no comments.

Therefore:

```text
COUNT(c.comment_id) = 0
```

for those posts.

---

## 6. Calculate a Viral Score

Define a simple engagement score:

```text
View    = 1 point
Comment = 3 points
```

```sql
SELECT
    bp.blog_post_id,
    bp.title,
    COALESCE(pvc.view_count, 0) AS total_views,
    COUNT(c.comment_id) AS total_comments,
    (
        COALESCE(pvc.view_count, 0)
        + COUNT(c.comment_id) * 3
    ) AS viral_score
FROM blog_posts bp
LEFT JOIN post_view_count pvc
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
```

### Purpose

Demonstrates a **derived business metric** rather than simply sorting by one database column.

---

# 7.2 Feed & Content

## 7. Retrieve the 10 Latest Published Posts

```sql
SELECT
    blog_post_id,
    title,
    published_at,
    content
FROM blog_posts
WHERE post_status = 'published'
ORDER BY published_at DESC
LIMIT 10;
```

### Purpose

This represents a basic blog feed or latest-posts page.

---

## 8. Build a Homepage Feed

Return:

* Post ID
* Title
* Creation date
* Author username
* Author name
* View count
* Comment count

```sql
SELECT
    bp.blog_post_id,
    bp.title,
    bp.created_at,
    u.username AS author_username,
    a.first_name || ' ' || a.last_name AS author_name,
    COALESCE(pvc.view_count, 0) AS view_count,
    COUNT(c.comment_id) AS comment_count
FROM blog_posts bp
JOIN authors a
    ON a.author_id = bp.author_id
JOIN users u
    ON u.user_id = a.author_id
LEFT JOIN post_view_count pvc
    ON pvc.blog_post_id = bp.blog_post_id
LEFT JOIN comments c
    ON c.blog_post_id = bp.blog_post_id
WHERE bp.post_status = 'published'
GROUP BY
    bp.blog_post_id,
    bp.title,
    bp.created_at,
    bp.published_at,
    u.username,
    a.first_name,
    a.last_name,
    pvc.view_count
ORDER BY bp.published_at DESC
LIMIT 10;
```

### Purpose

This is a realistic **homepage/feed query** combining multiple parts of the blog system.

---

# 7.3 User Analytics

## 9. Find the Most Active Users

Determine user activity based on:

* Total views
* Total comments

User views must come from `post_view_logs.user_id`.

```sql
WITH comment_totals AS (
    SELECT
        user_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY user_id
),
view_totals AS (
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
```

> **Important:** `post_view_count` represents the total views of a post. It cannot determine how many posts a particular user viewed. User-level view activity must come from `post_view_logs.user_id`.

---

## 10. Calculate User Activity Score

Scoring:

```text
View    = 1 point
Comment = 3 points
```

```sql
WITH comment_totals AS (
    SELECT
        user_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY user_id
),
view_totals AS (
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
    COALESCE(c.total_comments, 0) AS total_comments,
    COALESCE(v.total_views, 0) AS total_views,
    (
        COALESCE(v.total_views, 0)
        + COALESCE(c.total_comments, 0) * 3
    ) AS activity_score
FROM users u
LEFT JOIN comment_totals c
    ON c.user_id = u.user_id
LEFT JOIN view_totals v
    ON v.user_id = u.user_id
ORDER BY activity_score DESC;
```

### Purpose

Demonstrates combining multiple user activities into a single analytical metric.

---

# 7.4 Trending Analytics

## 11. Find the Top 10 Trending Posts from the Last 7 Days

Trending is based on views during the last seven days.

```sql
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
```

### Purpose

Unlike `post_view_count`, this query measures **recent activity**.

---

## 12. Calculate a Trend Score

Scoring:

```text
View    = 1 point
Comment = 3 points
```

Only activity from the last seven days is considered.

```sql
WITH recent_views AS (
    SELECT
        blog_post_id,
        COUNT(*) AS views_last_7_days
    FROM post_view_logs
    WHERE viewed_at >= NOW() - INTERVAL '7 days'
    GROUP BY blog_post_id
),
recent_comments AS (
    SELECT
        blog_post_id,
        COUNT(*) AS comments_last_7_days
    FROM comments
    WHERE created_at >= NOW() - INTERVAL '7 days'
    GROUP BY blog_post_id
)
SELECT
    bp.blog_post_id,
    bp.title,
    COALESCE(rv.views_last_7_days, 0) AS views_last_7_days,
    COALESCE(rc.comments_last_7_days, 0) AS comments_last_7_days,
    (
        COALESCE(rv.views_last_7_days, 0)
        + COALESCE(rc.comments_last_7_days, 0) * 3
    ) AS trend_score
FROM blog_posts bp
LEFT JOIN recent_views rv
    ON rv.blog_post_id = bp.blog_post_id
LEFT JOIN recent_comments rc
    ON rc.blog_post_id = bp.blog_post_id
WHERE bp.post_status = 'published'
ORDER BY trend_score DESC
LIMIT 10;
```

### Why separate CTEs?

Views and comments are aggregated independently before being joined.

This avoids multiplying view rows by comment rows.

That same problem will become important later in **Phase 09 — Query Optimization**.

---

# 7.5 Content Gap Analysis

## 13. Find Published Posts with No Comments

```sql
SELECT
    bp.blog_post_id,
    bp.title
FROM blog_posts bp
LEFT JOIN comments c
    ON c.blog_post_id = bp.blog_post_id
WHERE bp.post_status = 'published'
GROUP BY
    bp.blog_post_id,
    bp.title
HAVING COUNT(c.comment_id) = 0;
```

### Purpose

Identify published content that receives no discussion or engagement.

---

## 14. Find Published Posts with No Comments Using `NOT EXISTS`

```sql
SELECT
    bp.blog_post_id,
    bp.title
FROM blog_posts bp
WHERE bp.post_status = 'published'
  AND NOT EXISTS (
      SELECT 1
      FROM comments c
      WHERE c.blog_post_id = bp.blog_post_id
  );
```

### Purpose

This solves the same business problem using an existence test rather than aggregation.

The two approaches are useful for later comparison in **Phase 09 — Query Optimization**.

**Portfolio status:** The `NOT EXISTS` version is useful, but one version can be presented as the primary business query and the other as an alternative implementation.

---

# 7.6 Category Analytics

## 15. Find the Number of Posts in Each Category

Include categories that currently have zero posts.

```sql
SELECT
    c.cat_id,
    c.category_name,
    COUNT(bp.blog_post_id) AS total_posts
FROM categories c
LEFT JOIN post_categories pc
    ON pc.cat_id = c.cat_id
LEFT JOIN blog_posts bp
    ON bp.blog_post_id = pc.blog_post_id
GROUP BY
    c.cat_id,
    c.category_name
ORDER BY total_posts DESC;
```

### Purpose

Useful for category dashboards and content distribution analysis.

---

# 7.7 Author Dashboard

## 16. Build an Author Directory

Return:

* User ID
* Username
* Bio
* Profile picture
* Author status
* Creation date

```sql
SELECT
    u.user_id,
    u.username,
    a.bio,
    a.profile_picture_url,
    a.author_status,
    u.created_at
FROM users u
JOIN authors a
    ON a.author_id = u.user_id;
```

### Purpose

Represents an author-management or author-directory query.

---

## 17. Find All Banned Authors

```sql
SELECT
    author_id,
    first_name,
    last_name,
    created_at,
    author_status
FROM authors
WHERE author_status = 'banned';
```

### Purpose

Administrative query for identifying authors who are currently banned.

---

# 7.8 Advanced SQL — CTEs, Subqueries & Analytical Queries

The following queries remain in **Phase 07** because they are still primarily about answering business questions.

They introduce more advanced PostgreSQL SQL techniques.

---

## 18. Rank All Posts by View Count

Use `ROW_NUMBER()` to assign every post a unique sequential position.

```sql
SELECT
    bp.blog_post_id,
    bp.title,
    COALESCE(pvc.view_count, 0) AS view_count,
    ROW_NUMBER() OVER (
        ORDER BY COALESCE(pvc.view_count, 0) DESC
    ) AS position
FROM blog_posts bp
LEFT JOIN post_view_count pvc
    ON pvc.blog_post_id = bp.blog_post_id;
```

### Important

`ROW_NUMBER()` does **not** give equal rank to tied values.

For example:

```text
Views   ROW_NUMBER
100     1
100     2
90      3
```

For true ranking with ties, use `RANK()` or `DENSE_RANK()`.

---

## 19. Find the Most Viewed Post per Author

```sql
WITH ranked_posts AS (
    SELECT
        bp.author_id,
        bp.blog_post_id,
        bp.title,
        COALESCE(pvc.view_count, 0) AS view_count,
        ROW_NUMBER() OVER (
            PARTITION BY bp.author_id
            ORDER BY COALESCE(pvc.view_count, 0) DESC
        ) AS position
    FROM blog_posts bp
    LEFT JOIN post_view_count pvc
        ON pvc.blog_post_id = bp.blog_post_id
)
SELECT
    author_id,
    blog_post_id,
    title,
    view_count
FROM ranked_posts
WHERE position = 1;
```

### Purpose

Find each author's single most-viewed post.

If ties should return **all** equally popular posts, use `DENSE_RANK()` instead of `ROW_NUMBER()`.

---

## 20. Find the Top 3 Posts per Author

```sql
WITH ranked_posts AS (
    SELECT
        bp.author_id,
        bp.blog_post_id,
        bp.title,
        COALESCE(pvc.view_count, 0) AS view_count,
        ROW_NUMBER() OVER (
            PARTITION BY bp.author_id
            ORDER BY COALESCE(pvc.view_count, 0) DESC
        ) AS position
    FROM blog_posts bp
    LEFT JOIN post_view_count pvc
        ON pvc.blog_post_id = bp.blog_post_id
)
SELECT
    author_id,
    blog_post_id,
    title,
    view_count
FROM ranked_posts
WHERE position <= 3
ORDER BY
    author_id,
    position;
```

### Purpose

This is a classic **Top-N-per-group** problem.

---

## 21. Find the Most Popular Posts per Category

```sql
WITH category_posts AS (
    SELECT
        pc.cat_id,
        bp.blog_post_id,
        bp.title,
        COALESCE(pvc.view_count, 0) AS view_count,
        DENSE_RANK() OVER (
            PARTITION BY pc.cat_id
            ORDER BY COALESCE(pvc.view_count, 0) DESC
        ) AS rank
    FROM post_categories pc
    JOIN blog_posts bp
        ON bp.blog_post_id = pc.blog_post_id
    LEFT JOIN post_view_count pvc
        ON pvc.blog_post_id = bp.blog_post_id
)
SELECT
    cat_id,
    blog_post_id,
    title,
    view_count,
    rank
FROM category_posts
WHERE rank = 1;
```

### Why `DENSE_RANK()`?

If multiple posts have the same highest view count, they all receive rank `1`.

---

## 22. Build a User Engagement Leaderboard

Calculate:

```text
Activity Score = Views + (Comments × 3)
```

Then rank users.

```sql
WITH comment_totals AS (
    SELECT
        user_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY user_id
),
view_totals AS (
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
        COALESCE(v.total_views, 0) AS total_views,
        COALESCE(c.total_comments, 0) AS total_comments,
        (
            COALESCE(v.total_views, 0)
            + COALESCE(c.total_comments, 0) * 3
        ) AS activity_score
    FROM users u
    LEFT JOIN view_totals v
        ON v.user_id = u.user_id
    LEFT JOIN comment_totals c
        ON c.user_id = u.user_id
)
SELECT
    user_id,
    username,
    total_views,
    total_comments,
    activity_score,
    DENSE_RANK() OVER (
        ORDER BY activity_score DESC
    ) AS activity_rank
FROM user_activity
ORDER BY activity_rank;
```

### Purpose

Combines:

* CTEs
* aggregation
* derived metrics
* window functions
* ranking

This is a strong advanced SQL example for the case study.

---

# 7.9 Time-Based Ranking

## 23. Rank Posts by Daily Views

Calculate daily views and rank posts within each day.

```sql
WITH daily_views AS (
    SELECT
        DATE(viewed_at) AS view_date,
        blog_post_id,
        COUNT(*) AS daily_views
    FROM post_view_logs
    GROUP BY
        DATE(viewed_at),
        blog_post_id
)
SELECT
    view_date,
    blog_post_id,
    daily_views,
    DENSE_RANK() OVER (
        PARTITION BY view_date
        ORDER BY daily_views DESC
    ) AS daily_rank
FROM daily_views
ORDER BY
    view_date DESC,
    daily_rank;
```

### Purpose

Useful for daily trending or analytics dashboards.

---

# 7.10 Running Aggregates

## 24. Calculate Running Views for Each Post

Using the view log, calculate the cumulative number of views received by each post.

```sql
SELECT
    blog_post_id,
    viewed_at,
    COUNT(*) OVER (
        PARTITION BY blog_post_id
        ORDER BY viewed_at
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS running_views
FROM post_view_logs
ORDER BY
    blog_post_id,
    viewed_at;
```

### Purpose

Demonstrates a **running aggregate** using a window function.

---

# 7.11 Ranking Function Comparison

## 25. Compare `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()`

```sql
SELECT
    bp.blog_post_id,
    bp.title,
    COALESCE(pvc.view_count, 0) AS view_count,

    ROW_NUMBER() OVER (
        ORDER BY COALESCE(pvc.view_count, 0) DESC
    ) AS row_number,

    RANK() OVER (
        ORDER BY COALESCE(pvc.view_count, 0) DESC
    ) AS rank,

    DENSE_RANK() OVER (
        ORDER BY COALESCE(pvc.view_count, 0) DESC
    ) AS dense_rank

FROM blog_posts bp
LEFT JOIN post_view_count pvc
    ON pvc.blog_post_id = bp.blog_post_id
ORDER BY view_count DESC;
```

### Example

If the view counts are:

```text
100
100
90
80
```

The results are conceptually:

```text
View    ROW_NUMBER    RANK    DENSE_RANK
100          1          1          1
100          2          1          1
90           3          3          2
80           4          4          3
```

### Purpose

This is primarily an **advanced SQL learning example**.

It is useful for demonstrating PostgreSQL window functions, but it is not a major business requirement by itself.

---
