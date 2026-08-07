

# 📘 PostgreSQL SQL Practice Questions

## 🟢 1. GENERAL SQL

### Basic Analytics

1. Find the **top 10 most viewed posts**.
   
```sql
SELECT 
	 bp.blog_post_id,
	 bp.title,
	pv.view_count
	
FROM blog_posts bp
JOIN post_view_count pv
	ON pv.blog_post_id = bp.blog_post_id
ORDER BY pv.view_count DESC

LIMIT 10;

```


2. Find the **top 10 most viewed posts** which one published.
   
``` sql

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
```

3. Find the **top 10 most viewed posts** along with the author's name and post title.


``` sql

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


```

4. Find the **most active authors** based on the number of posts they have published.

```sql
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

```

5. Find the posts with the **highest number of comments**.

``` sql

 SELECT 
  bp.blog_post_id,
  bp.title,
  COUNT(c.comment_id) AS total_comment
FROM comments c
JOIN blog_posts bp
	ON bp.blog_post_id = c.blog_post_id
GROUP BY  bp.blog_post_id, bp.title
ORDER BY total_comment DESC;

```

6. Calculate a **viral score** for each post using:

   * Views = 1 point
   * Comments = 3 points

   Return the top 10 posts.


``` sql

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


   ```

### Feed & Content

7. Retrieve the **10 latest posts** for a homepage feed.

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



8. Build a homepage feed showing:

   * Post ID
   * Title
   * Creation date
   * Author username
   * View count
   * Comment count


```sql
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

```

### User Analytics

9. Find the **most active users** based on their total views and comments.

10. Find each user's:

* Total comments
* Total views
* Activity score

### Trending

11. Find the **top 10 trending posts from the last 7 days**, based on views.

12. Create a **trend score** using:

* Views = 1 point
* Comments = 3 points

Return the top 10 posts from the last 7 days.

### Content Gap

13. Find all posts that **have no comments**.

14. Solve the same problem using `NOT EXISTS`.

### Category Analytics

15. Find the **number of posts in each category**, including categories with zero posts.

### Author Dashboard

16. Build an **author directory** showing:

* User ID
* Username
* Bio
* Profile picture
* Author status
* Creation date

17. Find all **banned authors**.

---

---

# 🎯 Practice Progression

| Level          | Questions | Main Focus                                             |
| -------------- | --------: | ------------------------------------------------------ |
| 🟢 General     |      1–17 | SELECT, JOIN, GROUP BY, filtering, aggregation         |
| 🟠 Advanced    |     18–25 | CTEs, Window Functions, Ranking                        |
| 🔴 Performance |     26–60 | Indexing, EXPLAIN, optimization, large-scale analytics |

**Recommended order:**
**General → Advanced → Performance**

Don't look for the answer first. For each question, try to write the query yourself, then test it against PostgreSQL and inspect the execution plan where appropriate.
