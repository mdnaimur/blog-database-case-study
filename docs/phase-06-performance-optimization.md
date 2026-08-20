


# 🔴  PERFORMANCE & OPTIMIZATION

## Query Optimization

1. Find the **top 10 most viewed posts** and determine which indexes would improve this query.
```sql
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

```
#### > index analysis 
Primary key already index
It run sequence sequnce scan and most cost part is soring view_count

```sql
CREATE INDEX idx_post_count_view_desc
ON post_view_count(view_count DESC);
```

After indexing cost is reduce significant . and improve this query quality



2. Optimize a query that retrieves **recent published posts ordered by `published_at`**.

``` sql

EXPLAIN ANALYZE SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE post_status = 'published'
ORDER BY published_at DESC
LIMIT 10;
```
**Best index**
post_status and then sort by published_at, use a composite index

```sql

CREATE INDEX idx_blog_posts_published_recent 
ON blog_posts (post_status, published_at DESC); 
```

3. Optimize a query that retrieves posts together with their **view counts and comment counts**.
  
```sql

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

```
**Best Index:**
Here for view_count portion already have doing job aggregate viwe count which helps faster. no need index,



4.  Analyze a query that joins `posts`, `comments`, and `post_view_counts` and determine whether it can produce **row multiplication**.

> For this posts , commnets, post_view_count can produce row
> multiplication. blog_posts have many commnets, blog blost 
> each have one row for view count so
> 1 post × 3 comments × 1 view_count= 3 rows
> row multiplication produce here

``` sql 
SELECT
    bp.blog_post_id,
    bp.title,
    COUNT(c.comment_id) AS comment_count,
    pvc.view_count
FROM blog_posts bp
LEFT JOIN comments c
    ON c.blog_post_id = bp.blog_post_id
LEFT JOIN post_view_count pvc
    ON pvc.blog_post_id = bp.blog_post_id
GROUP BY
    bp.blog_post_id,
    bp.title,
    pvc.view_count;

```


5.  Rewrite a query that uses multiple joins and aggregations to avoid **unnecessary duplicate rows**.

```sql
WITH comment_total AS (
    SELECT
        blog_post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY blog_post_id
),
view_total AS (
    SELECT
        blog_post_id,
        COUNT(*) AS total_views
    FROM post_view_logs
    GROUP BY blog_post_id
)
SELECT
    bp.blog_post_id,
    bp.title,
    COALESCE(ct.total_comments, 0) AS total_comments,
    COALESCE(vt.total_views, 0) AS total_views
FROM blog_posts bp
LEFT JOIN comment_total ct
    ON ct.blog_post_id = bp.blog_post_id
LEFT JOIN view_total vt
    ON vt.blog_post_id = bp.blog_post_id;


```

### Indexing

6. Determine which indexes should be created for a query filtering posts by `post_status` and ordering by `published_at`.

```sql
SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE post_status = 'published'
ORDER BY published_at DESC

```
Here Best Index will be 

```sql
CREATE INDEX idx_blog_posts_published_at
ON blog_posts (published_at DESC)
WHERE post_status = 'published';

```
This is partial indexing where `post_status = 'published'`

So PostgreSQL can find the newest published posts without sorting all posts.


> Force to use index using
```sql
SET enable_seqscan = off;
```


7.  Determine the appropriate indexes for finding **recent posts from the last 7 days**. 
   
``` sql
SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE post_status = 'published'
  AND published_at >= NOW() - INTERVAL '7 days'
ORDER BY published_at DESC;
```

```sql
CREATE INDEX idx_blog_posts_published_at
ON blog_posts (published_at DESC)
WHERE post_status = 'published';

```
This is partial indexing where `post_status = 'published'`

So PostgreSQL can find the newest published posts without sorting all posts.

8.  Determine which indexes would improve queries filtering `comments` by `post_id`.

```sql
SELECT *
FROM comments
WHERE blog_post_id = 100;
```

Here index is needed

```sql
CREATE INDEX idx_comments_post
ON comments(blog_post_id);
```

9.  Determine which indexes would improve queries filtering `post_view_logs` by:

* `post_id`
* `user_id`
* `viewed_at`


```sql
CREATE INDEX idx_post_view_logs_viewed_at
ON post_view_logs(viewed_at);

```

10.  Design indexes for efficiently retrieving the **top posts per author**.

``` sql

CREATE INDEX idx_blog_posts_author
ON blog_posts(author_id);
```

### Execution Plans

11. Use `EXPLAIN` to analyze a query that retrieves the latest 20 published posts.
    
#### `Query Plan`

```text
Limit  (cost=0.29..11.00 rows=20 width=65)
  ->  Index Scan using idx_blog_posts_published_recent on blog_posts
      (cost=0.29..2702.33 rows=5045 width=65)
      Index Cond: (post_status = 'published'::post_status)

```



12. Use `EXPLAIN ANALYZE` to identify the expensive operations in a multi-table analytics query. 

```sql


EXPLAIN ANALYZE
SELECT
    bp.blog_post_id,
    bp.title,
    COUNT(c.comment_id) AS total_comments,
    COALESCE(pvc.view_count, 0) AS total_views
FROM blog_posts bp
LEFT JOIN comments c
    ON c.blog_post_id = bp.blog_post_id
LEFT JOIN post_view_count pvc
    ON pvc.blog_post_id = bp.blog_post_id
GROUP BY
    bp.blog_post_id,
    bp.title,
    pvc.view_count;


```

#### Query Plan

```text
"HashAggregate  (cost=2516.57..2816.57 rows=30000 width=81) (actual time=13.700..14.455 rows=10000 loops=1)"
"  Group Key: bp.blog_post_id, pvc.view_count"
"  Batches: 1  Memory Usage: 3089kB"
"  ->  Hash Left Join  (cost=1229.00..2291.57 rows=30000 width=73) (actual time=3.093..9.951 rows=30479 loops=1)"
"        Hash Cond: (bp.blog_post_id = pvc.blog_post_id)"
"        ->  Hash Right Join  (cost=949.00..1932.78 rows=30000 width=65) (actual time=2.203..6.630 rows=30479 loops=1)"
"              Hash Cond: (c.blog_post_id = bp.blog_post_id)"
"              ->  Seq Scan on comments c  (cost=0.00..905.00 rows=30000 width=16) (actual time=0.005..1.043 rows=30000 loops=1)"
"              ->  Hash  (cost=824.00..824.00 rows=10000 width=57) (actual time=2.182..2.184 rows=10000 loops=1)"
"                    Buckets: 16384  Batches: 1  Memory Usage: 1003kB"
"                    ->  Seq Scan on blog_posts bp  (cost=0.00..824.00 rows=10000 width=57) (actual time=0.005..1.188 rows=10000 loops=1)"
"        ->  Hash  (cost=155.00..155.00 rows=10000 width=16) (actual time=0.878..0.878 rows=10000 loops=1)"
"              Buckets: 16384  Batches: 1  Memory Usage: 597kB"
"              ->  Seq Scan on post_view_count pvc  (cost=0.00..155.00 rows=10000 width=16) (actual time=0.002..0.372 rows=10000 loops=1)"
"Planning Time: 0.216 ms"
"Execution Time: 14.804 ms"
```



13.  Compare the performance of:

* Correlated subquery
* CTE
* JOIN


| Approach              | Typical choice                             |
| --------------------- | ------------------------------------------ |
| Correlated subquery   | 🟡 Simple, but verify performance          |
| JOIN + GROUP BY       | 🟢 Usually best for simple aggregation     |
| CTE + pre-aggregation | 🟢 Best when combining multiple aggregates |




14. Determine whether PostgreSQL is using an **Index Scan, Bitmap Index Scan, or Sequential Scan**, and explain why.


### PostgreSQL Scan Types


| Scan                  | What it does                                                              | Usually used when                                          |
| --------------------- | ------------------------------------------------------------------------- | ---------------------------------------------------------- |
| **Sequential Scan**   | Reads the table row-by-row                                                | Large portion of table is needed or index isn't beneficial |
| **Index Scan**        | Uses index to find matching rows, then accesses table                     | Small/selective result set                                 |
| **Bitmap Index Scan** | Uses index to collect matching row locations, then reads them efficiently | Many matching rows                                         |



### Aggregation Performance

15. Optimize a query that calculates **comment counts for every post**.


```sql
CREATE INDEX idx_comments_post
ON comments(blog_post_id);
```

17. Optimize a query that calculates **view counts for every user**.



```sql

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
    COALESCE(vt.total_views, 0) AS total_views
FROM users u
LEFT JOIN comment_total ct
    ON ct.user_id = u.user_id
LEFT JOIN view_total vt
    ON vt.user_id = u.user_id;
```

####  query Index

```sql
CREATE INDEX idx_post_view_logs_user
ON post_view_logs(user_id);
```



18.  Optimize a query that calculates both **views and comments per user** without creating a Cartesian multiplication effect.


```sql
CREATE INDEX idx_comments_user
ON comments(user_id);

CREATE INDEX idx_post_view_logs_user
ON post_view_logs(user_id);


```


19. Compare the performance of calculating aggregates using:

* Multiple joins
* Separate CTEs
* Pre-aggregated subqueries


| Approach                      | Performance        | Main Risk / Note                      |
| ----------------------------- | ------------------ | ------------------------------------- |
| **Multiple JOINs**            | 🔴 Can be slow     | Row multiplication before aggregation |
| **Separate CTEs**             | 🟢 Often efficient | Cleaner; **not automatically faster** |
| **Pre-aggregated Subqueries** | 🟢 Often efficient | Similar performance to CTEs           |




### Window Function Performance

21. Analyze the performance of ranking millions of posts using `ROW_NUMBER()`. 

```text
"WindowAgg  (cost=0.29..576.28 rows=10000 width=24) (actual time=0.086..3.072 rows=10000 loops=1)"
"  ->  Index Scan using idx_post_count_view_desc on post_view_count  (cost=0.29..426.28 rows=10000 width=16) (actual time=0.077..1.860 rows=10000 loops=1)"
"Planning Time: 0.117 ms"
"Execution Time: 3.279 ms"

```

22. Determine how indexing can help a query using:

`PARTITION BY user_id ORDER BY view_count DESC`

```sql
ROW_NUMBER() OVER (
    PARTITION BY user_id
    ORDER BY view_count DESC
)
```

an index like this can help if user_id and view_count are in the same table:

```sql
CREATE INDEX idx_user_view
ON table_name (user_id, view_count DESC);
```

23. Optimize a query that finds the **top 3 posts per author** from a very large posts table. 


``` sql
SELECT
    author_id,
    blog_post_id,
    title,
    view_count
FROM (
    SELECT
        bp.author_id,
        bp.blog_post_id,
        bp.title,
        pvc.view_count,
        ROW_NUMBER() OVER (
            PARTITION BY bp.author_id
            ORDER BY pvc.view_count DESC
        ) AS rn
    FROM blog_posts bp
    JOIN post_view_count pvc
        ON pvc.blog_post_id = bp.blog_post_id
) x
WHERE rn <= 3;
```
####  query Index

```sql
CREATE INDEX idx_blog_posts_author
ON blog_posts(author_id);
```


24. Compare the performance of:

* Window functions
* `DISTINCT ON`
* `LATERAL JOIN`

for finding the top post per author.

| Approach                                 | Performance idea                  | Your schema                           |
| ---------------------------------------- | --------------------------------- | ------------------------------------- |
| **`ROW_NUMBER()`**                       | Ranks every joined row            | 🟢 Good for Top N                     |
| **`DISTINCT ON`**                        | Gets first row per author         | 🟢 Excellent for Top 1                |
| **`LATERAL JOIN`**                       | Finds Top 1 separately per author | 🟢 Can be excellent                   |
| **`(author_id, view_count DESC)` index** | Can greatly help                  | ❌ Not possible across your two tables |


### Large-Scale Analytics

25. Design a query capable of calculating **daily post rankings** efficiently when `post_view_logs` contains millions of rows.


```sql
WITH daily_views AS (
    SELECT
        blog_post_id,
        viewed_at::date AS view_date,
        COUNT(*) AS daily_views
    FROM post_view_logs
    WHERE viewed_at >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY blog_post_id, viewed_at::date
)
SELECT
    view_date,
    blog_post_id,
    daily_views,
    RANK() OVER (
        PARTITION BY view_date
        ORDER BY daily_views DESC
    ) AS daily_rank
FROM daily_views;
```


```sql
CREATE INDEX idx_view_logs_date_post
ON post_view_logs (viewed_at, blog_post_id);
```


26. Optimize a **7-day trending-post query** when the view-log table contains hundreds of millions of records.


```sql
EXPLAIN ANALYZE 
WITH daily_views AS (
    SELECT
        blog_post_id,
        viewed_at::date AS view_date,
        COUNT(*) AS views
    FROM post_view_logs
    WHERE viewed_at >= CURRENT_TIMESTAMP - INTERVAL '60 days'
    GROUP BY
        blog_post_id,
        viewed_at::date
),
trending AS (
    SELECT
        blog_post_id,
        SUM(views) AS views_7d
    FROM daily_views
    GROUP BY blog_post_id
)
SELECT
    bp.blog_post_id,
    bp.title,
    t.views_7d
FROM trending t
JOIN blog_posts bp
    ON bp.blog_post_id = t.blog_post_id
WHERE bp.post_status = 'published'
ORDER BY t.views_7d DESC;

```


```sql
CREATE INDEX idx_view_logs_viewed_at_post
ON post_view_logs (viewed_at, blog_post_id);
```


27. Design an efficient strategy for calculating **running views** over a very large view-log table.

```sql
EXPLAIN ANALYZE

SELECT
    blog_post_id,
    viewed_at,
    COUNT(*) OVER (
        PARTITION BY blog_post_id
        ORDER BY viewed_at
    ) AS running_views
FROM post_view_logs;
```

### Query Index

```sql
CREATE INDEX idx_view_logs_time_post
ON post_view_logs (viewed_at, blog_post_id);

```

28. Determine when a **materialized view** would be better than calculating analytics directly from transactional tables.


```sql
CREATE MATERIALIZED VIEW post_analytics AS
SELECT
    blog_post_id,
    COUNT(*) AS total_views
FROM post_view_logs
GROUP BY blog_post_id;


SELECT *
FROM post_analytics
ORDER BY total_views DESC
LIMIT 10;
```

### When should you use a Materialized View?

Use a **materialized view (MV)** when:

> **The analytics query is expensive, runs frequently, and the underlying data doesn't need to be real-time.**

For your blog system:

```text
post_view_logs → hundreds of millions of rows
comments       → millions of rows
blog_posts     → posts
```

A query like:

```sql
SELECT
    blog_post_id,
    COUNT(*) AS total_views
FROM post_view_logs
GROUP BY blog_post_id;
```

may become expensive if executed repeatedly.

### Direct query vs Materialized View

| Situation                      | Direct tables | Materialized View |
| ------------------------------ | ------------- | ----------------- |
| Small tables                   | ✅             | ❌ unnecessary     |
| Real-time data required        | ✅             | ❌                 |
| Query runs occasionally        | ✅             | ❌                 |
| Complex analytics              | 🟡 expensive  | 🟢                |
| Query runs frequently          | 🔴 expensive  | 🟢                |
| Hundreds of millions of logs   | 🔴            | 🟢                |
| Slightly stale data acceptable | 🟡            | 🟢                |

### Example

Create:

```sql
CREATE MATERIALIZED VIEW post_analytics AS
SELECT
    blog_post_id,
    COUNT(*) AS total_views
FROM post_view_logs
GROUP BY blog_post_id;
```

Then:

```sql
SELECT *
FROM post_analytics
ORDER BY total_views DESC
LIMIT 10;
```

Instead of repeatedly scanning:

```text
hundreds of millions of logs
        ↓
GROUP BY
        ↓
analytics
```

 query:

```text
materialized view
      ↓
small result
      ↓
fast analytics
```

### But there's a trade-off

Materialized views are **not automatically updated**.

 refresh them:

```sql
REFRESH MATERIALIZED VIEW post_analytics;
```

So there is a trade-off:

```text
Transactional tables
→ fresh data
→ expensive analytics

Materialized view
→ fast analytics
→ potentially stale data
```

### Production rule ⭐

Use a materialized view when:

**Expensive query + frequent reads + data can be slightly stale**

For your **hundreds-of-millions view-log analytics**, materialized views or incremental summary tables become strong options.

If analytics must be **real-time**, don't use a normal materialized view as the primary solution; consider maintaining summary tables incrementally instead.



29. Design a materialized-view strategy for **trending posts**.


```sql
CREATE MATERIALIZED VIEW trending_posts AS
SELECT
    bp.blog_post_id,
    bp.title,
    COUNT(pvl.view_log_id) AS views_7d
FROM blog_posts bp
LEFT JOIN post_view_logs pvl
    ON pvl.blog_post_id = bp.blog_post_id
    AND pvl.viewed_at >= CURRENT_TIMESTAMP - INTERVAL '60 days'
WHERE bp.post_status = 'published'
GROUP BY
    bp.blog_post_id,
    bp.title;



	SELECT *
FROM trending_posts
ORDER BY views_7d DESC
LIMIT 10;


REFRESH MATERIALIZED VIEW trending_posts;

```


30. Determine when a **summary table / counter table** should be used instead of `COUNT(*)` on a large log table.

# Counter / Summary Table

## When to Use

Use a **counter/summary table** when:

> `COUNT(*)` on a large log/event table becomes too expensive or too frequent.

### Problem

```text
post_view_logs
→ individual view events
→ millions/hundreds of millions of rows
```

Repeatedly doing:

```sql
SELECT blog_post_id, COUNT(*)
FROM post_view_logs
GROUP BY blog_post_id;
```

requires PostgreSQL to process a large amount of data.

### Solution

Maintain a summary table:

```sql
post_view_count
```

```text
post_view_logs
→ historical/audit data

post_view_count
→ current total
→ fast reads
```

Instead of:

```sql
SELECT COUNT(*)
FROM post_view_logs
WHERE blog_post_id = 100;
```

use:

```sql
SELECT view_count
FROM post_view_count
WHERE blog_post_id = 100;
```
## Advanced PostgreSQL Performance

31. Identify queries that could benefit from **partial indexes**. 
32. 

 Published posts ⭐

 frequently query:

```sql
WHERE post_status = 'published'
```

Create:

```sql
CREATE INDEX idx_published_posts
ON blog_posts (published_at DESC)
WHERE post_status = 'published';
```

Useful for:

```sql
SELECT *
FROM blog_posts
WHERE post_status = 'published'
ORDER BY published_at DESC
LIMIT 20;
```

**Why:** The index contains only published posts, so it is smaller than a full-table index.

---

### 2. Active authors

 frequently have:

```sql
WHERE author_status = 'active'
```

Possible:

```sql
CREATE INDEX idx_active_authors
ON authors (author_id)
WHERE author_status = 'active';
```

Useful when filtering active authors frequently.

But if the table is small, the benefit may be negligible.

---

### 3. Recent view logs ⭐

For queries repeatedly looking at recent views:

```sql
WHERE viewed_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'
```

A normal index is usually more appropriate:

```sql
CREATE INDEX idx_view_logs_time_post
ON post_view_logs (viewed_at, blog_post_id);
```

A partial index using a rolling condition such as:

```sql
WHERE viewed_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'
```

is **not appropriate**, because partial-index predicates must be based on immutable conditions; `CURRENT_TIMESTAMP` changes over time.

---

### 4. Published posts + author

If you frequently query:

```sql
WHERE author_id = ?
AND post_status = 'published'
```

use:

```sql
CREATE INDEX idx_published_posts_author
ON blog_posts (author_id, published_at DESC)
WHERE post_status = 'published';
```

Very useful for:

> latest published posts by a particular author.

---


33. Identify queries that could benefit from **covering indexes using `INCLUDE`**.

For your schema, a **covering index** is useful when the query frequently filters/sorts by some columns but also needs a few extra columns in the `SELECT`.

### 1. Latest published posts ⭐

Query:

```sql
SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE post_status = 'published'
ORDER BY published_at DESC
LIMIT 20;
```

Good covering index:

```sql
CREATE INDEX idx_published_posts_cover
ON blog_posts (published_at DESC)
INCLUDE (blog_post_id, title)
WHERE post_status = 'published';
```

Why:

```text
Index:
published_at → sorting/filtering
      +
INCLUDE:
blog_post_id, title → returned values
```

PostgreSQL may then use an **Index Only Scan**.

---

### 2. Published posts by author

Query:

```sql
SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE author_id = 10
  AND post_status = 'published'
ORDER BY published_at DESC
LIMIT 10;
```

Index:

```sql
CREATE INDEX idx_author_published_cover
ON blog_posts (author_id, published_at DESC)
INCLUDE (blog_post_id, title)
WHERE post_status = 'published';
```

This is a strong candidate if this endpoint is frequently used.

---

### 3. Comments by user

Query:

```sql
SELECT
    comment_id,
    blog_post_id,
    created_at
FROM comments
WHERE user_id = 100
ORDER BY created_at DESC;
```

Covering index:

```sql
CREATE INDEX idx_comments_user_cover
ON comments (user_id, created_at DESC)
INCLUDE (comment_id, blog_post_id);
```

---

### Important distinction

Don't put everything into the index key:

❌

```sql
(user_id, created_at, comment_id, blog_post_id)
```

Prefer:

```sql
(user_id, created_at)
INCLUDE (comment_id, blog_post_id)
```

The **key columns** are used for searching/sorting.

`INCLUDE` columns are mainly there so PostgreSQL can retrieve the required output without visiting the table.

### Performance

Potential plan:

```text
Index Only Scan
        ↓
No/less heap access
        ↓
Faster query
```

But `INCLUDE` **does not guarantee** an Index Only Scan. PostgreSQL also needs the table pages to be sufficiently visible according to the visibility map.

### Best candidates in your schema

| Query                     | Covering index                            | Priority |
| ------------------------- | ----------------------------------------- | -------: |
| Latest published posts    | `(published_at) INCLUDE (...)`            |    ⭐⭐⭐⭐⭐ |
| Author's published posts  | `(author_id, published_at) INCLUDE (...)` |    ⭐⭐⭐⭐⭐ |
| User's comments           | `(user_id, created_at) INCLUDE (...)`     |     ⭐⭐⭐⭐ |
| Top posts by `view_count` | Depends on schema/join                    |       🟡 |

**Rule:** Put columns used for **filtering/sorting** in the index key; put columns needed only for **output** in `INCLUDE`.

34. Determine when **BRIN indexes** would be more appropriate than B-tree indexes for `post_view_logs`.


For your `post_view_logs`, **BRIN is better than B-tree when the table is huge and `viewed_at` follows the physical insertion order**.

### Example

Your table:

```text
post_view_logs
-------------------------
view_log_id
blog_post_id
user_id
viewed_at
```

If new logs are continuously inserted:

```text
old rows                         new rows
2026-01-01 → 2026-02-01 → ... → 2026-08-20
       physical table order roughly follows time
```

Then:

```sql
CREATE INDEX idx_view_logs_viewed_at_brin
ON post_view_logs USING BRIN (viewed_at);
```

BRIN stores information about **blocks/ranges of rows**, not every individual row.

### Why BRIN can be excellent

Suppose you have **500 million logs** and query:

```sql
SELECT COUNT(*)
FROM post_view_logs
WHERE viewed_at >= NOW() - INTERVAL '7 days';
```

A BRIN index can quickly identify the table blocks likely to contain those recent dates and skip most older blocks.

```text
500M rows
    ↓
BRIN
    ↓
"These blocks contain recent dates"
    ↓
scan only relevant blocks
```

### BRIN vs B-tree

|                                | B-tree      | BRIN                       |
| ------------------------------ | ----------- | -------------------------- |
| Huge table                     | 🟡          | 🟢 Excellent               |
| `viewed_at` time-range queries | 🟢          | 🟢 Excellent if correlated |
| Index size                     | Large       | ⭐ Very small               |
| Exact lookup                   | ⭐ Excellent | 🟡 Not ideal               |
| Randomly distributed values    | 🟢          | 🔴 Poor                    |
| Sequential/time-ordered logs   | 🟢          | ⭐ Excellent                |

### When NOT to use BRIN

If `viewed_at` is randomly distributed throughout the table:

```text
block 1 → 2026, 2024, 2025, 2023
block 2 → 2025, 2026, 2023, 2024
...
```

BRIN cannot eliminate many blocks effectively.

Then a B-tree is usually better:

```sql
CREATE INDEX idx_view_logs_viewed_at
ON post_view_logs (viewed_at);
```

### For your `post_view_logs`

Because this is a **large append-heavy log table**, I'd seriously consider:

```sql
CREATE INDEX idx_view_logs_viewed_at_brin
ON post_view_logs USING BRIN (viewed_at);
```

**if `viewed_at` is strongly correlated with physical row order.**

Check correlation with:

```sql
SELECT
    attname,
    correlation
FROM pg_stats
WHERE tablename = 'post_view_logs'
  AND attname = 'viewed_at';
```

A correlation close to **+1 or -1** indicates strong physical ordering and is a good sign for BRIN.

**Rule to remember:**

> **Huge table + naturally ordered data + range queries → BRIN.**
> **Small/medium table or random data/exact lookups → B-tree.**

35. Analyze whether partitioning `post_view_logs` by date would improve the 7-day analytics queries.


Yes — **for your `post_view_logs` with hundreds of millions of rows, date partitioning can significantly help 7-day analytics**, provided the queries filter by `viewed_at`.

### Example

Partition by month:

```sql
CREATE TABLE post_view_logs (
    view_log_id BIGINT,
    blog_post_id BIGINT,
    user_id BIGINT,
    viewed_at TIMESTAMP NOT NULL
) PARTITION BY RANGE (viewed_at);
```

Then:

```sql
CREATE TABLE post_view_logs_2026_08
PARTITION OF post_view_logs
FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
```

### Your 7-day query

```sql
SELECT
    blog_post_id,
    COUNT(*) AS views
FROM post_view_logs
WHERE viewed_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'
GROUP BY blog_post_id;
```

Without partitioning:

```text
500M rows
     ↓
find last 7 days
     ↓
process relevant rows
```

With monthly partitions:

```text
2026-01 partition ── ❌
2026-02 partition ── ❌
...
2026-07 partition ── ❌
2026-08 partition ── ✅
                         ↓
                    aggregate
```

This is called **partition pruning**.

### But partitioning doesn't automatically make the query fast

If the August partition itself contains 50 million rows:

```text
500M total
   ↓ partition pruning
50M rows
   ↓
GROUP BY
```

PostgreSQL still has to process those 50M rows.

So you should combine partitioning with an appropriate index, for example:

```sql
CREATE INDEX
ON post_view_logs_2026_08 (viewed_at, blog_post_id);
```

Or consider BRIN on `viewed_at` for a very large, time-ordered log partition.

### Which partition size?

For your workload:

| Partition | Recommendation                 |
| --------- | ------------------------------ |
| Yearly    | ❌ Too large                    |
| Monthly   | ⭐ Good starting point          |
| Weekly    | 🟢 Possible                    |
| Daily     | 🟡 Usually too many partitions |

For **7-day analytics**, monthly partitions are often a reasonable balance.

### When partitioning is worth it

Use it when:

* `post_view_logs` is **very large**
* Most analytics filter by `viewed_at`
* Queries frequently ask for recent periods such as 7/30/90 days
* Old data can eventually be archived/dropped
* You need better maintenance of historical data

### When it won't help much

If you run:

```sql
SELECT *
FROM post_view_logs
WHERE blog_post_id = 100;
```

without a `viewed_at` filter, date partitioning doesn't provide much benefit because PostgreSQL may need to inspect **all partitions**.

### Final answer

For your workload:

> **Yes, partition `post_view_logs` by `viewed_at` if it has hundreds of millions/billions of rows and most analytics are time-based.**

A strong production design is:

```text
post_view_logs
      │
      ├── 2026_07
      ├── 2026_08
      └── 2026_09
             ↓
      partition pruning
             ↓
       only recent data
             ↓
       7-day analytics
```

**Partitioning reduces the amount of data PostgreSQL needs to consider; indexes/BRIN improve access within the relevant partition.**


36. Design a partitioning strategy for a view-log table containing **billions of records**. 

For **billions of `post_view_logs`**, I would use **`RANGE` partitioning on `viewed_at`**, usually **monthly partitions** to start.

### 1. Parent table

```sql
CREATE TABLE post_view_logs (
    view_log_id  BIGINT NOT NULL,
    blog_post_id BIGINT NOT NULL,
    user_id      BIGINT,
    viewed_at    TIMESTAMP NOT NULL
) PARTITION BY RANGE (viewed_at);
```

### 2. Monthly partitions

```sql
CREATE TABLE post_view_logs_2026_08
PARTITION OF post_view_logs
FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

CREATE TABLE post_view_logs_2026_09
PARTITION OF post_view_logs
FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
```

For billions of rows, this keeps each partition manageable.

### 3. Index each partition

For time-based analytics:

```sql
CREATE INDEX idx_pvl_2026_08_viewed_at
ON post_view_logs_2026_08 USING BRIN (viewed_at);
```

For a very large, append-only log table, **BRIN is attractive because the index is tiny**.

If you frequently query a particular post within a time range, consider:

```sql
CREATE INDEX idx_pvl_2026_08_post_time
ON post_view_logs_2026_08 (blog_post_id, viewed_at);
```

Don't blindly create both; choose based on actual query patterns and `EXPLAIN`.

### 4. 7-day query

```sql
SELECT
    blog_post_id,
    COUNT(*) AS views
FROM post_view_logs
WHERE viewed_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'
GROUP BY blog_post_id;
```

PostgreSQL can perform **partition pruning**:

```text
Billions of rows
       ↓
Partition pruning
       ↓
Only recent partitions
       ↓
BRIN / B-tree
       ↓
Aggregate
```

### 5. Partition retention becomes easy

If logs older than 1 year can be removed, don't do:

```sql
DELETE FROM post_view_logs
WHERE viewed_at < ...;
```

Instead, drop/detach the old partition:

```sql
DROP TABLE post_view_logs_2025_08;
```

That's dramatically cheaper than deleting millions/billions of rows individually.

### Recommended architecture

```text
                 post_view_logs
                       │
                RANGE(viewed_at)
                       │
        ┌──────────────┼──────────────┐
        ↓              ↓              ↓
     2026_08        2026_09        2026_10
        │              │              │
       BRIN           BRIN           BRIN
        │              │              │
        └──────────────┼──────────────┘
                       ↓
                Analytics queries
```

### Monthly vs daily

| Strategy    | Verdict                                                 |
| ----------- | ------------------------------------------------------- |
| Yearly      | ❌ Too large                                             |
| **Monthly** | ⭐ Best starting point                                   |
| Weekly      | 🟢 Good if monthly partitions become too large          |
| Daily       | 🟡 Only when partitions are extremely large/high-volume |

**Key production rule:** Don't partition merely because the table has billions of rows. Partition when it gives you a concrete benefit—**partition pruning, easier retention/archiving, or manageable maintenance**. For your time-based view analytics, `RANGE(viewed_at)` is a strong fit.


37. Determine how **table statistics and `ANALYZE`** can affect PostgreSQL query planning.


### What do `ANALYZE` and table statistics do?

PostgreSQL's optimizer needs to **estimate how many rows a query will return** before choosing a plan.

`ANALYZE` collects statistics that help it make that decision.

```sql
ANALYZE post_view_logs;
```

PostgreSQL collects information such as:

* number of rows
* number of distinct values
* common values
* data distribution
* correlation with physical row order

You can see statistics through:

```sql
SELECT
    tablename,
    attname,
    n_distinct,
    most_common_vals,
    most_common_freqs,
    histogram_bounds,
    correlation
FROM pg_stats
WHERE tablename = 'post_view_logs';
```

### Why this affects performance

Suppose you run:

```sql
SELECT *
FROM post_view_logs
WHERE viewed_at >= CURRENT_DATE - 7;
```

PostgreSQL must decide:

```text
Index Scan?
     OR
Sequential Scan?
```

It estimates how many rows match.

#### Accurate statistics

```text
ANALYZE
   ↓
Accurate estimate
   ↓
"Only 2% of rows match"
   ↓
Index Scan ✅
```

#### Stale statistics

```text
Old statistics
     ↓
Wrong estimate
     ↓
"50% of rows match"
     ↓
Sequential Scan
```

The wrong estimate can lead to a bad execution plan.

### Example with joins

Suppose:

```sql
SELECT *
FROM blog_posts bp
JOIN post_view_logs pvl
    ON pvl.blog_post_id = bp.blog_post_id
WHERE pvl.viewed_at >= CURRENT_DATE - 7;
```

PostgreSQL needs to estimate:

```text
How many logs?
How many posts?
How many rows after filtering?
How many rows after JOIN?
```

Bad statistics → bad estimates → potentially bad join strategy.

### When should you run `ANALYZE`?

Normally PostgreSQL's **autovacuum/autoanalyze** handles this automatically.

Manually run it after a major data change when necessary:

```sql
ANALYZE post_view_logs;
ANALYZE blog_posts;
```

For example:

```text
Large bulk INSERT
       ↓
Data distribution changed significantly
       ↓
ANALYZE
       ↓
Planner gets fresh statistics
```

### Very large tables

For your **billions-of-row `post_view_logs`**, statistics become particularly important.

You can increase statistics for an important column:

```sql
ALTER TABLE post_view_logs
ALTER COLUMN viewed_at SET STATISTICS 500;
```

Then:

```sql
ANALYZE post_view_logs;
```

But don't increase statistics everywhere blindly—it increases ANALYZE work and stored statistics.

### How to detect the problem

Compare:

```sql
EXPLAIN ANALYZE
SELECT ...
```

Look for:

```text
estimated rows: 100
actual rows:    5000000
```

Huge difference = **possible statistics/cardinality-estimation problem**.

### Key idea ⭐

```text
ANALYZE
   ↓
Collect statistics
   ↓
Planner estimates row counts
   ↓
Chooses execution plan
   ↓
Index / Seq Scan / Join strategy / etc.
```

**`ANALYZE` doesn't make the query itself faster. It helps PostgreSQL choose a better plan.**



---

## Derived State Strategy

Certain analytical information is calculated instead of permanently stored.

Examples

- Popular Posts
- Total Views
- Trending Posts

These values are generated using aggregation queries or materialized views to improve query performance.



Yes. The important idea is:

## Derived State

**Derived state = data that can be calculated from other stored data.**

For your blog:

```text
Raw data
   ↓
post_view_logs
comments
blog_posts
   ↓
Aggregation
   ↓
Derived information
```

### Examples

| Derived information      | Calculated from            |
| ------------------------ | -------------------------- |
| **Total views**          | `post_view_logs`           |
| **Popular posts**        | `post_view_logs` + ranking |
| **Trending posts**       | Recent `post_view_logs`    |
| **Comment count**        | `comments`                 |
| **Top posts per author** | Posts + view counts        |

### 1. Calculate directly

```sql
SELECT
    blog_post_id,
    COUNT(*) AS total_views
FROM post_view_logs
GROUP BY blog_post_id;
```

Always accurate, but expensive if `post_view_logs` has billions of rows.

### 2. Materialized view

```text
post_view_logs
      ↓
aggregation
      ↓
materialized view
      ↓
fast reads
```

Good when analytics can be slightly stale.

### 3. Counter table

For frequently accessed values such as total views:

```text
post_view_logs
      ↓
increment
      ↓
post_view_count
      ↓
very fast read
```

### Key distinction

**Derived state does not mean "never store it."**

It means:

> The value is **derived from source data**, and you choose whether to calculate it on demand, materialize it, or maintain a counter for performance.

### Production decision

```text
Need real-time?
    ↓
Counter / incrementally maintained value

Can tolerate stale data?
    ↓
Materialized view

Small/occasional query?
    ↓
Calculate directly
```

For your blog system, this is the core pattern:

**Raw transactional data → derived analytics → optimized read path.**



---

## Search Architecture

The application uses PostgreSQL Full-Text Search for efficient searching.

Search Targets

- Blog title
- Blog content

Technologies

- tsvector
- tsquery
- GIN Index

---

## Performance Considerations

Optimization strategies include:

- Indexing frequently queried columns
- Materialized views
- Query optimization
- EXPLAIN ANALYZE
- Pagination

Frequently Indexed Columns

- post_id
- author_id
- category_id
- created_at
- publication_date

---



## PostgreSQL Full-Text Search

The idea is simple:

> Instead of searching millions of blog rows with `LIKE '%keyword%'`, PostgreSQL creates a searchable text representation and indexes it.

### 1. Search target

You want users to search:

```text
Blog title
Blog content
```

Example:

```text
Title:   PostgreSQL Indexing Guide
Content: Learn B-tree, BRIN and GIN indexes...
```

Search:

```text
postgresql indexing
```

---

### 2. `tsvector`

`tsvector` = **processed/searchable representation of text**.

```sql
SELECT to_tsvector(
    'english',
    'PostgreSQL indexing is very important'
);
```

Conceptually:

```text
"PostgreSQL indexing is very important"
                 ↓
tsvector
                 ↓
'important' 'index' 'postgresql'
```

It also performs things such as **stemming** and removes common stop words.

---

### 3. `tsquery`

`tsquery` = **what you want to search for**.

```sql
SELECT to_tsquery(
    'english',
    'postgresql & indexing'
);
```

Meaning:

```text
postgresql AND indexing
```

---

### 4. Search

For your blog:

```sql
SELECT
    blog_post_id,
    title
FROM blog_posts
WHERE to_tsvector(
    'english',
    title || ' ' || content
) @@ to_tsquery(
    'english',
    'postgresql & indexing'
);
```

`@@` means:

> Does this `tsvector` match this `tsquery`?

---

## 5. GIN index ⭐

Don't calculate `to_tsvector()` for every row during every search.

Create an index:

```sql
CREATE INDEX idx_blog_posts_search
ON blog_posts
USING GIN (
    to_tsvector('english', title || ' ' || content)
);
```

Now:

```text
User searches
     ↓
tsquery
     ↓
GIN index
     ↓
matching posts
```

### Why GIN?

GIN is designed for values containing **multiple searchable elements**, such as the lexemes inside a `tsvector`.

---

## Production pattern

For a large blog:

```text
blog_posts
   │
   ├── title
   └── content
        ↓
    tsvector
        ↓
    GIN index
        ↓
    tsquery
        ↓
   Search results
```

### Remember

| Component      | Purpose                              |
| -------------- | ------------------------------------ |
| **`tsvector`** | Converts text into searchable tokens |
| **`tsquery`**  | Represents the search query          |
| **`@@`**       | Performs the match                   |
| **GIN**        | Makes the search fast                |

**Core idea:** `tsvector` = searchable data, `tsquery` = search request, `GIN` = performance.


---
## Concurrency & Scalability

The system is designed for moderate traffic (approximately 1000 concurrent users).

Optimization techniques

- Read-heavy optimization
- Efficient indexing
- Query caching
- Reduced expensive joins


## Concurrency & Scalability

For your blog system, **1,000 concurrent users** means the database should handle many users reading data at the same time without expensive queries becoming a bottleneck.

### Main strategy

```text
1000 concurrent users
        ↓
   Application
        ↓
 ┌──────┼──────┐
 ↓      ↓      ↓
Cache  PostgreSQL
          ↓
   Optimized queries
          ↓
      Indexes
```

### 1. Read-heavy optimization ⭐

A blog is usually **read-heavy**:

```text
1000 requests
   ↓
900+ reads
100 writes
```

Optimize common reads such as:

* Homepage posts
* Post details
* Popular posts
* Trending posts
* Author pages

Use indexes, precomputed counters, and materialized views where appropriate.

---

### 2. Efficient indexing

Index columns used frequently in:

```sql
WHERE
JOIN
ORDER BY
```

Example:

```sql
CREATE INDEX idx_posts_published
ON blog_posts (published_at DESC)
WHERE post_status = 'published';
```

Don't create indexes for every column. Extra indexes increase:

* Storage
* INSERT/UPDATE cost
* Maintenance

---

### 3. Query caching

If thousands of users repeatedly request:

```text
"Top 10 trending posts"
```

don't necessarily calculate it from millions of logs every time.

```text
Request
   ↓
Cache?
 ┌─┴─┐
Yes  No
 ↓    ↓
Return Query DB
       ↓
     Cache
```

For frequently changing analytics, a short TTL such as **30–60 seconds** can significantly reduce database load.

---

### 4. Reduce expensive joins

Avoid joining multiple large one-to-many tables directly.

Bad:

```text
posts
  ↓
comments
  ↓
view_logs
```

This can cause **row multiplication**.

Better:

```text
comments
   ↓ GROUP BY
comment totals ──┐
                 ├── JOIN → posts
view logs        │
   ↓ GROUP BY    │
view totals ─────┘
```

---

## What actually matters for 1,000 concurrent users?

| Technique                | Purpose                   |
| ------------------------ | ------------------------- |
| **Indexes**              | Reduce database work      |
| **Query optimization**   | Reduce CPU/I/O            |
| **Caching**              | Avoid repeated DB queries |
| **Precomputed counters** | Fast totals               |
| **Materialized views**   | Fast analytics            |
| **Connection pooling**   | Control DB connections    |
| **Pagination**           | Avoid huge result sets    |

### Key point

**1,000 concurrent users does not automatically require a distributed database.**

For your blog system, a well-designed PostgreSQL database with:

> **good indexes + optimized queries + connection pooling + caching + precomputed analytics**

can comfortably support a moderate read-heavy workload, assuming the application and hardware are sized appropriately.
