# Phase 09 — Query Optimization

## Objective

Optimize PostgreSQL queries by analyzing their execution plans, identifying bottlenecks, applying appropriate changes, and measuring the results.

The focus of this phase is:

* `EXPLAIN`
* `EXPLAIN ANALYZE`
* Scan methods
* Join strategies
* Aggregation
* Row multiplication
* Query rewriting
* CTEs and subqueries
* Window-function performance
* Large-scale analytics
* Materialized views
* Counter / summary tables
* Statistics
* Benchmarking

The key principle is:

> **Do not optimize based on assumption. Measure first, change one thing, and measure again.**

---

# 9.1 Query Optimization Workflow

A professional optimization process should follow:

```text
Business Query
      ↓
Baseline Query
      ↓
EXPLAIN
      ↓
EXPLAIN ANALYZE
      ↓
Identify Bottleneck
      ↓
Choose Optimization
      ↓
Implement Change
      ↓
EXPLAIN ANALYZE Again
      ↓
Compare Results
      ↓
Keep / Reject Optimization
```

The final case study should show **evidence**, not simply state that an index or rewrite is faster.

---

# 9.2 EXPLAIN

`EXPLAIN` shows PostgreSQL's planned execution strategy without actually executing the query.

Example:

```sql
EXPLAIN
SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE post_status = 'published'
ORDER BY published_at DESC
LIMIT 10;
```

A simplified plan might contain:

```text
Limit
  -> Sort
       -> Seq Scan on blog_posts
```

This tells us PostgreSQL chose:

```text
Seq Scan
    ↓
Sort
    ↓
Limit
```

### Purpose

Use `EXPLAIN` to understand **what PostgreSQL plans to do**.

---

# 9.3 EXPLAIN ANALYZE

`EXPLAIN ANALYZE` actually executes the query and reports what happened.

```sql
EXPLAIN (ANALYZE)
SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE post_status = 'published'
ORDER BY published_at DESC
LIMIT 10;
```

It provides information such as:

* Actual execution time
* Actual rows
* Loops
* Planning time
* Execution time
* Chosen scan
* Join strategy

A better production-analysis format is:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE post_status = 'published'
ORDER BY published_at DESC
LIMIT 10;
```

`BUFFERS` helps determine whether the query is spending significant work on shared-buffer hits or reads.

---

# 9.4 Estimated Rows vs Actual Rows

One of the most important parts of a PostgreSQL execution plan is:

```text
rows=estimated
actual rows=observed
```

For example:

```text
Index Scan
  (cost=...)
  (actual time=... rows=100000 loops=1)
```

Suppose PostgreSQL estimates:

```text
rows=100
```

but actually processes:

```text
rows=100000
```

That is a major estimation difference.

Poor cardinality estimates can cause PostgreSQL to select an inefficient execution strategy.

### Important

An estimate mismatch does **not automatically mean statistics are stale**.

Possible causes include:

* Data distribution
* Correlated columns
* Insufficient statistics
* Complex predicates
* Data changes
* Query structure

---

# 9.5 Sequential Scan vs Index Scan

A sequential scan reads the table sequentially.

```text
Seq Scan
    ↓
many/all table rows
```

An index scan uses an index to locate relevant rows.

```text
Index
  ↓
matching rows
  ↓
table
```

Example:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    blog_post_id,
    title
FROM blog_posts
WHERE author_id = 10;
```

If:

```text
blog_posts.author_id
```

has a useful index, PostgreSQL may choose an index-based plan.

### Important

A sequential scan is **not automatically bad**.

For a query returning a large percentage of a table, PostgreSQL may correctly determine that scanning the table is cheaper than repeatedly accessing rows through an index.

---

# 9.6 Index Scan vs Index Only Scan

An `Index Scan` uses the index but may still need to access the table.

An `Index Only Scan` can sometimes obtain all required information from the index.

For example, a covering index:

```sql
CREATE INDEX idx_blog_posts_latest_covering
ON blog_posts(published_at DESC)
INCLUDE (blog_post_id, title)
WHERE post_status = 'published';
```

may allow PostgreSQL to use:

```text
Index Only Scan
```

for an appropriate query.

### Important

`INCLUDE` does not guarantee an Index Only Scan.

PostgreSQL also considers visibility information and query cost.

Use:

```sql
EXPLAIN (ANALYZE, BUFFERS)
```

to verify the actual plan.

---

# 9.7 Optimize Latest Published Posts

Baseline query:

```sql
SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE post_status = 'published'
ORDER BY published_at DESC
LIMIT 10;
```

First measure:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE post_status = 'published'
ORDER BY published_at DESC
LIMIT 10;
```

Possible optimization:

```sql
CREATE INDEX idx_blog_posts_published_at
ON blog_posts(published_at DESC)
WHERE post_status = 'published';
```

Then run the same:

```sql
EXPLAIN (ANALYZE, BUFFERS)
...
```

### Compare

Record:

```text
Before:
Planning Time
Execution Time
Buffers

After:
Planning Time
Execution Time
Buffers
```

### Case-study value

**High.**

This gives a clear:

```text
Query
→ Index design
→ Plan
→ Measurement
```

story.

---

# 9.8 Optimize Author's Published Posts

Baseline:

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

Candidate index:

```sql
CREATE INDEX idx_blog_posts_author_published
ON blog_posts(
    author_id,
    published_at DESC
)
WHERE post_status = 'published';
```

Measure before and after:

```sql
EXPLAIN (ANALYZE, BUFFERS)
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

### What to investigate

Look for changes such as:

```text
Seq Scan
   ↓
Index Scan

Sort
   ↓
ordered index access
```

Do not claim that the index eliminates the sort unless the actual plan demonstrates it.

---

# 9.9 Join Strategy Analysis

PostgreSQL can use different join algorithms.

The major ones are:

```text
Nested Loop
Hash Join
Merge Join
```

---

## Nested Loop

Conceptually:

```text
Outer rows
    ↓
For each row
    ↓
Find matching inner rows
```

This can be excellent when the outer relation is small and the inner side can be accessed efficiently.

---

## Hash Join

Conceptually:

```text
Build hash table
       ↓
Probe matching rows
```

Often useful for larger equality joins.

---

## Merge Join

Conceptually:

```text
Sorted input A
      +
Sorted input B
      ↓
Merge matching rows
```

Useful when inputs are already suitably ordered or sorting is worthwhile.

### Important

There is no universally "best" join algorithm.

PostgreSQL chooses based on estimated cost and available statistics.

---

# 9.10 Analyze Multi-Table Analytics

Consider the homepage-style query:

```sql
SELECT
    bp.blog_post_id,
    bp.title,
    u.username,
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
    u.username,
    pvc.view_count;
```

Analyze it:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ...
```

Investigate:

* Number of rows entering each join
* Join algorithm
* Aggregation cost
* Sort cost
* Sequential scans
* Buffer usage

This is where Phase 09 moves beyond simply asking whether an index exists.

---

# 9.11 Row Multiplication Problem

A particularly important problem in this database is joining multiple one-to-many relationships.

Suppose a post has:

```text
10 views
5 comments
```

If both raw relationships are joined together:

```text
post
 ├── 10 view rows
 └── 5 comment rows
```

the join can produce:

```text
10 × 5 = 50 rows
```

before aggregation.

Therefore, a query such as:

```sql
SELECT
    bp.blog_post_id,
    COUNT(pvl.view_log_id) AS views,
    COUNT(c.comment_id) AS comments
FROM blog_posts bp
LEFT JOIN post_view_logs pvl
    ON pvl.blog_post_id = bp.blog_post_id
LEFT JOIN comments c
    ON c.blog_post_id = bp.blog_post_id
GROUP BY bp.blog_post_id;
```

can produce incorrect counts.

For example:

```text
Actual:
views    = 10
comments = 5

Naive join:
views    = 50
comments = 50
```

This is both a **correctness and performance problem**.

---

# 9.12 Pre-Aggregation

A better approach is to aggregate each one-to-many relationship independently.

```sql
WITH view_totals AS (
    SELECT
        blog_post_id,
        COUNT(*) AS total_views
    FROM post_view_logs
    GROUP BY blog_post_id
),
comment_totals AS (
    SELECT
        blog_post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY blog_post_id
)
SELECT
    bp.blog_post_id,
    bp.title,
    COALESCE(v.total_views, 0) AS total_views,
    COALESCE(c.total_comments, 0) AS total_comments
FROM blog_posts bp
LEFT JOIN view_totals v
    ON v.blog_post_id = bp.blog_post_id
LEFT JOIN comment_totals c
    ON c.blog_post_id = bp.blog_post_id;
```

### Why this is better

Instead of:

```text
posts
 ↓
views × comments
 ↓
aggregation
```

we do:

```text
views
 ↓
aggregate

comments
 ↓
aggregate

        ↓
     join results
```

This reduces row multiplication.

### Case-study value

**Very high.**

This is one of the strongest optimization examples in the project.

---

# 9.13 `LEFT JOIN + HAVING` vs `NOT EXISTS`

From Phase 07:

### Version A

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

### Version B

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

Both answer the same business question.

Now benchmark both:

```sql
EXPLAIN (ANALYZE, BUFFERS)
...
```

### What to compare

* Execution time
* Rows examined
* Join strategy
* Buffer usage
* Effect of `comments(blog_post_id)` index

### Important

Do not claim:

> `NOT EXISTS` is always faster.

The correct conclusion must come from the actual workload and execution plans.

---

# 9.14 Correlated Subquery vs Join vs CTE

Consider a query that calculates comment totals.

Possible implementations include:

```text
Correlated subquery
        vs
JOIN + GROUP BY
        vs
Pre-aggregated CTE
```

Example correlated approach:

```sql
SELECT
    bp.blog_post_id,
    bp.title,
    (
        SELECT COUNT(*)
        FROM comments c
        WHERE c.blog_post_id = bp.blog_post_id
    ) AS comment_count
FROM blog_posts bp;
```

Alternative:

```sql
SELECT
    bp.blog_post_id,
    bp.title,
    COUNT(c.comment_id) AS comment_count
FROM blog_posts bp
LEFT JOIN comments c
    ON c.blog_post_id = bp.blog_post_id
GROUP BY
    bp.blog_post_id,
    bp.title;
```

### Optimization rule

Do not decide based only on SQL appearance.

Benchmark:

```sql
EXPLAIN (ANALYZE, BUFFERS)
```

on the same dataset.

---

# 9.15 Window Function Optimization

Consider:

```sql
SELECT
    blog_post_id,
    title,
    view_count,
    ROW_NUMBER() OVER (
        PARTITION BY author_id
        ORDER BY view_count DESC
    ) AS position
FROM post_statistics;
```

Window functions may require:

```text
Scan
 ↓
Sort
 ↓
WindowAgg
```

For example:

```text
Sort
  Sort Key:
    author_id
    view_count DESC

WindowAgg
```

### What to investigate

* Number of rows entering the window operation
* Sort method
* Sort memory
* Disk spill
* Total execution time

### Important

A small test such as:

```text
10,000 rows
```

does not demonstrate "large-scale" window-function performance.

For a scalability claim, use a substantially larger representative dataset.

---

# 9.16 Top-N per Group Optimization

A common Phase 07 query is:

> Find the top 3 posts for each author.

One implementation uses:

```sql
ROW_NUMBER()
```

Another PostgreSQL-specific approach may use:

```text
DISTINCT ON
```

Another may use:

```text
LATERAL
```

These approaches should not be declared universally better.

The correct optimization workflow is:

```text
Same requirement
       ↓
ROW_NUMBER()
       ↓
DISTINCT ON
       ↓
LATERAL
       ↓
EXPLAIN ANALYZE
       ↓
Compare
```

---

# 9.17 `ROW_NUMBER()` vs `DISTINCT ON` vs `LATERAL`

For example, PostgreSQL's `DISTINCT ON` can solve a "first row per group" requirement:

```sql
SELECT DISTINCT ON (author_id)
    author_id,
    blog_post_id,
    title,
    view_count
FROM post_statistics
ORDER BY
    author_id,
    view_count DESC;
```

`ROW_NUMBER()` provides a more general solution:

```sql
WITH ranked AS (
    SELECT
        author_id,
        blog_post_id,
        title,
        view_count,
        ROW_NUMBER() OVER (
            PARTITION BY author_id
            ORDER BY view_count DESC
        ) AS position
    FROM post_statistics
)
SELECT *
FROM ranked
WHERE position = 1;
```

A `LATERAL` approach can retrieve a limited number of rows per parent.

### Optimization comparison

The case study should compare them using:

```sql
EXPLAIN (ANALYZE, BUFFERS)
```

on the same data.

---

# 9.18 Trending Query Optimization

The Phase 07 trending query calculates views over the last seven days:

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

A relevant index candidate is:

```sql
CREATE INDEX idx_view_logs_post_time
ON post_view_logs(
    blog_post_id,
    viewed_at DESC
);
```

But the optimal index depends on the actual filtering and join pattern.

Another candidate may involve:

```sql
CREATE INDEX idx_view_logs_viewed_at
ON post_view_logs(viewed_at);
```

These should be tested rather than blindly creating both.

---

# 9.19 Large-Scale Analytics

Queries that operate over `post_view_logs` can become expensive because this table can grow much faster than the main entity tables.

For example:

```sql
SELECT
    blog_post_id,
    COUNT(*) AS total_views
FROM post_view_logs
GROUP BY blog_post_id;
```

At large scale:

```text
Millions of view records
        ↓
Scan
        ↓
Aggregation
        ↓
Results
```

Even with an index, PostgreSQL may still need to process a large number of rows.

This leads to a key architectural question:

> Should this value be calculated from raw data every time?

For frequently requested metrics, the answer may eventually be **no**.

---

# 9.20 Materialized Views

A materialized view stores the result of a query physically.

Example:

```sql
CREATE MATERIALIZED VIEW popular_posts AS
SELECT
    bp.blog_post_id,
    bp.title,
    COUNT(pvl.view_log_id) AS total_views
FROM blog_posts bp
JOIN post_view_logs pvl
    ON pvl.blog_post_id = bp.blog_post_id
GROUP BY
    bp.blog_post_id,
    bp.title;
```

Querying it:

```sql
SELECT
    blog_post_id,
    title,
    total_views
FROM popular_posts
ORDER BY total_views DESC
LIMIT 10;
```

Instead of repeatedly aggregating millions of raw view records, the application reads the precomputed result.

---

# 9.21 Refreshing a Materialized View

A materialized view does not automatically reflect new underlying rows.

Refresh it with:

```sql
REFRESH MATERIALIZED VIEW popular_posts;
```

For production systems, refresh strategy becomes an architectural decision.

There is a trade-off:

```text
Freshness
    ↕
Query performance
```

More frequent refresh:

```text
More current
+
More refresh cost
```

Less frequent refresh:

```text
Less refresh cost
+
Potentially stale results
```

---

# 9.22 Trending Materialized View

A trending report could also be precomputed.

Conceptually:

```text
Raw view logs
      ↓
7-day aggregation
      ↓
Materialized view
      ↓
Trending page
```

However, be careful with time-dependent definitions.

A materialized view containing:

```sql
NOW() - INTERVAL '7 days'
```

does not continuously move its seven-day window.

The window changes when the materialized view is refreshed.

Therefore:

```text
Materialized view
+
Refresh schedule
```

must be designed together.

---

# 9.23 Counter / Summary Table

The project already contains:

```text
post_view_count
```

This is a **derived summary/counter table**.

Instead of repeatedly calculating:

```sql
SELECT
    blog_post_id,
    COUNT(*)
FROM post_view_logs
GROUP BY blog_post_id;
```

the system maintains:

```text
post_view_logs
      ↓
increment counter
      ↓
post_view_count
```

Then:

```sql
SELECT
    blog_post_id,
    view_count
FROM post_view_count
ORDER BY view_count DESC
LIMIT 10;
```

becomes much cheaper.

---

# 9.24 Materialized View vs Counter Table

| Approach          | Read Speed        | Freshness         | Write Complexity |
| ----------------- | ----------------- | ----------------- | ---------------- |
| Raw aggregation   | Low at huge scale | Real-time         | Low              |
| Materialized view | High              | Refresh-dependent | Medium           |
| Counter table     | Very high         | Near real-time    | Higher           |

### Counter table

Best when:

* A simple metric is frequently requested
* Near-real-time values are required
* Incremental updates are manageable

### Materialized view

Best when:

* The calculation is complex
* Reads are frequent
* Some staleness is acceptable
* Periodic refresh is practical

This is an important architectural optimization for the blog system.

---

# 9.25 `ANALYZE` and Statistics

PostgreSQL uses statistics to estimate:

* Number of rows
* Data distribution
* Selectivity
* Join cardinality

Run:

```sql
ANALYZE blog_posts;
```

or:

```sql
ANALYZE post_view_logs;
```

After significant data changes, refreshed statistics can improve planner estimates.

You can inspect statistics using:

```sql
SELECT
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats
WHERE tablename = 'post_view_logs';
```

### Important

`ANALYZE` does not directly make a query faster.

Its purpose is to provide better information to the planner.

Better statistics can lead to:

```text
Better estimates
      ↓
Better plan selection
      ↓
Potentially better execution
```

---

# 9.26 Statistics and Cardinality Problems

Suppose the plan estimates:

```text
100 rows
```

but execution produces:

```text
100,000 rows
```

Investigate:

1. Is the data distribution unusual?
2. Are statistics current?
3. Is the predicate highly correlated?
4. Does the query contain multiple correlated conditions?
5. Would higher statistics targets help?

For example:

```sql
ALTER TABLE blog_posts
ALTER COLUMN author_id SET STATISTICS 500;

ANALYZE blog_posts;
```

Do this only when there is evidence that the default statistics target is insufficient.

---

# 9.27 Benchmarking

Optimization should be measured consistently.

For each optimization, record:

```text
Query
Dataset size
Baseline execution time
Baseline plan
Optimization
Optimized execution time
Optimized plan
Improvement
```

Example:

| Metric         |   Before |      After |
| -------------- | -------: | ---------: |
| Execution Time |    85 ms |      12 ms |
| Rows Processed |  500,000 |         10 |
| Buffers        |   12,500 |         35 |
| Scan           | Seq Scan | Index Scan |

The numbers above are **examples only**. Your case study should contain actual measurements from your PostgreSQL environment.

---

# 9.28 Stress Testing

`EXPLAIN ANALYZE` measures an individual database query.

It does not simulate the full application's concurrent workload.

For broader testing:

```text
Dataset
   ↓
Baseline query
   ↓
Single-query measurement
   ↓
Concurrent workload
   ↓
Measure latency / throughput
   ↓
Optimize
   ↓
Repeat
```

Useful metrics include:

* Requests per second
* Average latency
* p95 latency
* p99 latency
* Error rate
* Database CPU
* Database I/O
* Connection utilization

### Important

Do not describe a query as "scalable to 1000 concurrent users" unless you actually test or have sufficient evidence for that claim.

---

# 9.29 Query Optimization Checklist

For each important query:

```text
□ Define the business requirement
□ Run the baseline query
□ EXPLAIN
□ EXPLAIN ANALYZE
□ Check estimated vs actual rows
□ Check scan type
□ Check join strategy
□ Check sort operations
□ Check aggregation
□ Check buffer usage
□ Identify bottleneck
□ Apply one optimization
□ Run EXPLAIN ANALYZE again
□ Compare before/after
□ Keep the change only if evidence supports it
```

---

# 9.30 Optimization Case Studies for This Project

The strongest optimization cases for the portfolio are:

### Case Study 1 — Latest Published Posts

```text
Query
 ↓
Sequential/less efficient plan
 ↓
Partial B-tree index
 ↓
EXPLAIN ANALYZE
 ↓
Before vs After
```

### Case Study 2 — Author's Latest Posts

```text
Query
 ↓
Composite + Partial Index
 ↓
EXPLAIN ANALYZE
 ↓
Compare
```

### Case Study 3 — Row Multiplication

```text
Posts
 ↓
Views × Comments
 ↓
Incorrect/expensive aggregation
 ↓
Pre-aggregate
 ↓
EXPLAIN ANALYZE
```

### Case Study 4 — `NOT EXISTS` vs `LEFT JOIN`

```text
Same requirement
       ↓
Two SQL implementations
       ↓
EXPLAIN ANALYZE
       ↓
Compare
```

### Case Study 5 — Top-N per Author

```text
ROW_NUMBER()
     vs
DISTINCT ON
     vs
LATERAL
     ↓
EXPLAIN ANALYZE
     ↓
Compare
```

### Case Study 6 — Derived View Counts

```text
Raw view logs
      ↓
Repeated COUNT(*)
      ↓
Expensive analytics
      ↓
Counter / summary table
      ↓
Fast reads
```

This is particularly relevant because the project's `post_view_count` table already represents this architectural decision.

---

# 9.31 Phase 09 Case-Study Flow

The strongest overall story is:

```text
Business Requirement
        ↓
Phase 07
SQL Query
        ↓
Phase 08
Index Design
        ↓
Phase 09
EXPLAIN ANALYZE
        ↓
Identify Bottleneck
        ↓
Optimization
        ↓
EXPLAIN ANALYZE Again
        ↓
Before / After Comparison
        ↓
Phase 10
Final Performance Analysis
```

---

# Phase 09 — Final Organization

```text
Phase 09 — Query Optimization
│
├── 9.1 Optimization Workflow
│
├── 9.2 EXPLAIN
│
├── 9.3 EXPLAIN ANALYZE
│
├── 9.4 Estimated vs Actual Rows
│
├── 9.5 Sequential Scan vs Index Scan
│
├── 9.6 Index Scan vs Index Only Scan
│
├── 9.7 Latest Published Posts Optimization
│
├── 9.8 Author Posts Optimization
│
├── 9.9 Join Strategy Analysis
│
├── 9.10 Multi-Table Query Analysis
│
├── 9.11 Row Multiplication
│
├── 9.12 Pre-Aggregation
│
├── 9.13 NOT EXISTS vs LEFT JOIN
│
├── 9.14 Correlated Subquery vs JOIN vs CTE
│
├── 9.15 Window Function Optimization
│
├── 9.16 Top-N per Group
│
├── 9.17 ROW_NUMBER vs DISTINCT ON vs LATERAL
│
├── 9.18 Trending Query Optimization
│
├── 9.19 Large-Scale Analytics
│
├── 9.20 Materialized Views
│
├── 9.21 Materialized View Refresh
│
├── 9.22 Trending Materialized Views
│
├── 9.23 Counter / Summary Tables
│
├── 9.24 Materialized View vs Counter Table
│
├── 9.25 ANALYZE and Statistics
│
├── 9.26 Cardinality Estimation
│
├── 9.27 Benchmarking
│
├── 9.28 Stress Testing
│
└── 9.29 Optimization Case Studies
```

## What should remain in the final portfolio?

**Highest-value material:**

* `EXPLAIN ANALYZE`
* Before/after performance evidence
* Latest published posts optimization
* Composite/partial index optimization
* Row multiplication + pre-aggregation
* `NOT EXISTS` vs `LEFT JOIN` comparison
* Top-N-per-group comparison
* Large-scale view-log analysis
* Materialized view vs counter table
* Statistics/cardinality analysis
* Benchmark results

The rest can support those main case studies rather than becoming a collection of disconnected optimization experiments.

**Phase 09 is complete.**

➡️ **Continue with Phase 10 — Final Analysis**.
