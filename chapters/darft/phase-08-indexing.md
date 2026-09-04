# Phase 08 — Indexing

## Objective

Design PostgreSQL indexes based on the **actual access patterns and query requirements** of the blog system.

The purpose of this phase is to determine:

* Which columns need indexes
* Which queries benefit from indexes
* Which index type is appropriate
* When to use composite indexes
* When to use partial indexes
* When to use covering indexes with `INCLUDE`
* When to use GIN for Full-Text Search
* When BRIN is appropriate
* When partitioning should be considered

This phase focuses on **index design**.

Actual performance measurement using `EXPLAIN ANALYZE`, before/after comparison, and query rewriting is covered in **Phase 09 — Query Optimization**.

---

# 8.1 Existing Indexes

Before adding advanced indexes, identify the indexes already created by the schema.

The current schema already has indexes automatically created by:

* `PRIMARY KEY`
* `UNIQUE`

For example:

```sql
CREATE TABLE users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL
);
```

PostgreSQL automatically creates indexes supporting:

```text
users_pkey
users_username_key
users_email_key
```

Therefore, creating another index such as:

```sql
CREATE INDEX idx_users_user_id
ON users(user_id);
```

would be redundant.

### Important Principle

> Do not create an index simply because a column is frequently used. Design indexes according to actual query patterns.

---

# 8.2 Basic B-Tree Indexes

PostgreSQL's default index type is **B-tree**.

B-tree indexes are appropriate for common operations such as:

```text
=
<
>
<=
>=
BETWEEN
ORDER BY
```

They are the primary index type for this blog system.

---

## 1. Index Blog Posts by Author

A common query is finding posts written by a particular author.

```sql
CREATE INDEX idx_blog_posts_author
ON blog_posts(author_id);
```

Example query:

```sql
SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE author_id = 10;
```

### Why?

Without an appropriate index, PostgreSQL may need to inspect many rows.

The index provides an efficient path to rows belonging to the requested author.

**Status:** ✅ Keep

---

# 8.3 Indexes for Foreign Keys

Foreign keys do **not automatically create indexes on the referencing column** in PostgreSQL.

For example:

```sql
blog_posts.author_id
```

references:

```text
authors.author_id
```

The primary key on `authors.author_id` is indexed automatically, but the referencing column:

```text
blog_posts.author_id
```

is not automatically indexed.

Therefore:

```sql
CREATE INDEX idx_blog_posts_author
ON blog_posts(author_id);
```

is useful.

Similarly:

```sql
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
```

These indexes support common relationship-based lookups.

---

# 8.4 Index Blog Posts by Status

A simple status index can support queries such as:

```sql
SELECT
    blog_post_id,
    title
FROM blog_posts
WHERE post_status = 'published';
```

Possible index:

```sql
CREATE INDEX idx_blog_posts_status
ON blog_posts(post_status);
```

However, this is **not necessarily the best production index**.

The blog application frequently needs:

```sql
WHERE post_status = 'published'
ORDER BY published_at DESC
```

Therefore, a more targeted index may be better.

This leads to **partial indexes**.

---

# 8.5 Partial Indexes

A partial index contains only rows satisfying a condition.

This is especially useful for the blog system because many queries work only with published posts.

For example:

```sql
CREATE INDEX idx_blog_posts_published_at
ON blog_posts(published_at DESC)
WHERE post_status = 'published';
```

This index contains only published posts.

---

## 2. Optimize the Latest Published Posts Access Pattern

The application frequently executes:

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

The index:

```sql
CREATE INDEX idx_blog_posts_published_at
ON blog_posts(published_at DESC)
WHERE post_status = 'published';
```

matches the important parts of the query:

```text
WHERE
    post_status = 'published'

ORDER BY
    published_at DESC
```

### Why Partial Index?

Draft and archived posts are excluded from the index.

Therefore, if the majority of the table contains non-published content, the index can be significantly smaller than a full-table index.

**Phase:** 08 — Indexing

**Performance proof:** Phase 09 — Query Optimization

---

# 8.6 Composite Indexes

A composite index contains multiple columns.

Example:

```sql
CREATE INDEX idx_blog_posts_author_published
ON blog_posts(
    author_id,
    published_at DESC
);
```

This can support queries such as:

```sql
SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE author_id = 10
ORDER BY published_at DESC;
```

The index provides:

```text
author_id
    ↓
published_at DESC
```

which matches the query's filtering and ordering pattern.

---

## 3. Author's Published Posts

A more targeted version can combine composite indexing with a partial index:

```sql
CREATE INDEX idx_blog_posts_author_published
ON blog_posts(
    author_id,
    published_at DESC
)
WHERE post_status = 'published';
```

This is particularly useful for:

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

### Design Principle

Column order matters.

For:

```text
(author_id, published_at)
```

the index is naturally useful for queries filtering by `author_id` and then ordering/ranging by `published_at`.

Do not assume:

```text
(published_at, author_id)
```

is equivalent.

---

# 8.7 Composite Index for View Logs

`post_view_logs` is expected to become one of the largest tables in the system.

Common access patterns include:

```text
views for a post
views for a user
recent views for a post
```

For recent views belonging to a particular post:

```sql
SELECT
    view_log_id,
    viewed_at,
    user_id
FROM post_view_logs
WHERE blog_post_id = 100
ORDER BY viewed_at DESC;
```

A suitable index is:

```sql
CREATE INDEX idx_view_logs_post_time
ON post_view_logs(
    blog_post_id,
    viewed_at DESC
);
```

### Why?

The index groups records by:

```text
blog_post_id
```

and orders them by:

```text
viewed_at DESC
```

This matches the access pattern.

---

# 8.8 Index for User View History

For user-specific view history:

```sql
SELECT
    blog_post_id,
    viewed_at
FROM post_view_logs
WHERE user_id = 25
ORDER BY viewed_at DESC;
```

Use:

```sql
CREATE INDEX idx_view_logs_user_time
ON post_view_logs(
    user_id,
    viewed_at DESC
);
```

This is more useful than having only:

```sql
CREATE INDEX idx_post_view_logs_user
ON post_view_logs(user_id);
```

when the application also needs the user's views ordered by time.

---

# 8.9 Index for Comments

A common operation is retrieving comments belonging to a post.

```sql
SELECT
    comment_id,
    user_id,
    content,
    created_at
FROM comments
WHERE blog_post_id = 100
ORDER BY created_at DESC;
```

A simple index:

```sql
CREATE INDEX idx_comments_post
ON comments(blog_post_id);
```

supports the filter.

But if the application consistently requires chronological ordering, a better access-pattern index can be:

```sql
CREATE INDEX idx_comments_post_created
ON comments(
    blog_post_id,
    created_at DESC
);
```

### Design Decision

Do not automatically keep both:

```sql
idx_comments_post
idx_comments_post_created
```

unless both serve different important workloads.

The composite index can often make the simpler index unnecessary.

---

# 8.10 Covering Indexes with `INCLUDE`

PostgreSQL supports covering indexes using `INCLUDE`.

Example:

```sql
CREATE INDEX idx_blog_posts_latest_covering
ON blog_posts(published_at DESC)
INCLUDE (
    blog_post_id,
    title
)
WHERE post_status = 'published';
```

This can support:

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

The index contains:

```text
Search / ordering column
    ↓
published_at

Included columns
    ↓
blog_post_id
title
```

### Why `INCLUDE`?

Included columns are available from the index without becoming part of the index's search ordering.

This can make **Index Only Scan** possible.

### Important

`INCLUDE` does **not guarantee** an Index Only Scan.

PostgreSQL also considers table visibility information and the overall cost of the query.

Therefore, actual confirmation belongs in Phase 09 using:

```sql
EXPLAIN (ANALYZE, BUFFERS)
```

---

# 8.11 Covering Index for Author Posts

For an author dashboard:

```sql
SELECT
    blog_post_id,
    title,
    published_at
FROM blog_posts
WHERE author_id = 10
  AND post_status = 'published'
ORDER BY published_at DESC;
```

A possible covering index is:

```sql
CREATE INDEX idx_blog_posts_author_published_covering
ON blog_posts(
    author_id,
    published_at DESC
)
INCLUDE (blog_post_id, title)
WHERE post_status = 'published';
```

### Access pattern

```text
WHERE
    author_id = ?

AND
    post_status = 'published'

ORDER BY
    published_at DESC

SELECT
    blog_post_id,
    title,
    published_at
```

This is a strong example of designing an index around a **specific query pattern**.

---

# 8.12 Full-Text Search

The blog system requires keyword searching through:

* Post title
* Post content

A normal B-tree index is not designed for full-text search.

PostgreSQL provides:

```text
tsvector
tsquery
@@
GIN
```

---

## 4. Create a Search Vector

Conceptually:

```sql
SELECT
    to_tsvector(
        'english',
        title || ' ' || content
    )
FROM blog_posts;
```

A search query can then use:

```sql
SELECT
    blog_post_id,
    title
FROM blog_posts
WHERE to_tsvector(
    'english',
    title || ' ' || content
)
@@ plainto_tsquery('english', 'postgresql indexing');
```

However, calculating `to_tsvector()` for every row during every search is not ideal for a production workload.

A better design is to maintain a searchable `tsvector`.

---

# 8.13 GIN Index for Full-Text Search

A GIN index is well suited for PostgreSQL full-text search.

For example, if the table has a `search_vector` column:

```sql
CREATE INDEX idx_blog_posts_search
ON blog_posts
USING GIN(search_vector);
```

Then:

```sql
SELECT
    blog_post_id,
    title
FROM blog_posts
WHERE search_vector
      @@ plainto_tsquery('english', 'postgresql indexing');
```

### Why GIN?

GIN is designed for efficiently indexing composite values such as:

* Full-text search vectors
* Arrays
* JSONB keys/values

For this project, the primary use is **Full-Text Search**.

---

# 8.14 Full-Text Search Architecture

The final search architecture can be represented as:

```text
Blog Post
    │
    ├── title
    └── content
          │
          ↓
      tsvector
          │
          ↓
      GIN Index
          │
          ↓
      tsquery
          │
          ↓
     Search Results
```

### Important

Search architecture belongs to the database design discussion, but:

```text
Search design
    → Phase 04

GIN index
    → Phase 08

Search performance testing
    → Phase 09
```

---

# 8.15 BRIN Indexes

`post_view_logs` is expected to contain a large number of rows.

The table is also append-heavy:

```text
new view
   ↓
new row
   ↓
later timestamp
```

This makes `viewed_at` a candidate for a BRIN index when physical row order is reasonably correlated with time.

Example:

```sql
CREATE INDEX idx_view_logs_viewed_at_brin
ON post_view_logs
USING BRIN(viewed_at);
```

### Why BRIN?

BRIN indexes summarize ranges of table pages rather than storing an index entry for every row like a typical B-tree.

Therefore they can be extremely small.

They are especially useful for large tables where the indexed column has a strong relationship with physical row order.

---

# 8.16 When Should BRIN Be Used?

BRIN is a candidate when:

```text
Very large table
        +
Column has physical correlation
        +
Queries use ranges
        +
Rows are naturally ordered
```

For example:

```sql
SELECT
    COUNT(*)
FROM post_view_logs
WHERE viewed_at >= NOW() - INTERVAL '7 days';
```

### Important

Do not assume BRIN is automatically faster than B-tree.

The effectiveness depends on:

* Table size
* Data distribution
* Physical correlation
* Query selectivity
* Maintenance pattern

Actual comparison belongs in Phase 09.

---

# 8.17 Checking Column Correlation

PostgreSQL statistics contain correlation information.

For example:

```sql
SELECT
    tablename,
    attname,
    correlation
FROM pg_stats
WHERE tablename = 'post_view_logs'
  AND attname = 'viewed_at';
```

A high absolute correlation indicates that the physical order of rows is strongly related to the column's logical order.

This can make BRIN more attractive.

### Important

Correlation is evidence for considering BRIN, not a guarantee of performance improvement.

---

# 8.18 Partial Index for Published Posts

Another useful partial-index pattern is:

```sql
CREATE INDEX idx_blog_posts_published
ON blog_posts(published_at DESC)
WHERE post_status = 'published';
```

This supports queries such as:

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

This is more targeted than:

```sql
CREATE INDEX idx_blog_posts_status
ON blog_posts(post_status);
```

when the primary workload is retrieving published posts in chronological order.

---

# 8.19 Partial Index for Active Authors

If the application frequently retrieves only active authors:

```sql
SELECT
    author_id,
    first_name,
    last_name
FROM authors
WHERE author_status = 'active';
```

a partial index could be considered:

```sql
CREATE INDEX idx_authors_active
ON authors(author_status)
WHERE author_status = 'active';
```

However, this is **not automatically necessary**.

If almost all authors are active, the index may provide little benefit.

This is an important indexing principle:

> An index should solve a real access pattern and provide enough selectivity or ordering benefit to justify its maintenance cost.

---

# 8.20 Index for Category Relationships

The junction table:

```text
post_categories
```

has:

```sql
PRIMARY KEY (blog_post_id, cat_id)
```

This automatically provides an index beginning with:

```text
blog_post_id
```

Therefore, a query such as:

```sql
SELECT cat_id
FROM post_categories
WHERE blog_post_id = 100;
```

can use the primary-key index.

However, the reverse lookup:

```sql
SELECT blog_post_id
FROM post_categories
WHERE cat_id = 5;
```

benefits from:

```sql
CREATE INDEX idx_post_categories_category
ON post_categories(cat_id);
```

### Important

This demonstrates why composite-key column order matters.

```text
PRIMARY KEY (blog_post_id, cat_id)
```

is not equivalent to:

```text
PRIMARY KEY (cat_id, blog_post_id)
```

for index access.

---

# 8.21 Avoid Redundant Indexes

Suppose we already have:

```sql
CREATE INDEX idx_blog_posts_author_published
ON blog_posts(author_id, published_at DESC);
```

Creating:

```sql
CREATE INDEX idx_blog_posts_author
ON blog_posts(author_id);
```

may be unnecessary depending on the workload because the composite index has `author_id` as its leading column.

Likewise, do not create separate indexes merely because every column appears in a query.

### Bad approach

```text
Every WHERE column
        ↓
Create an index
```

### Better approach

```text
Application query patterns
        ↓
Identify filtering
        ↓
Identify ordering
        ↓
Identify joins
        ↓
Consider selectivity
        ↓
Design index
        ↓
Measure
```

---

# 8.22 Indexing and Write Performance

Indexes improve reads but increase write overhead.

When a row is inserted or updated, PostgreSQL may need to update multiple indexes.

For example:

```text
INSERT blog post
       │
       ├── table
       ├── PK index
       ├── unique index
       ├── author index
       ├── status index
       └── other indexes
```

Therefore, adding indexes without justification can cause:

* Additional storage
* More write work
* More maintenance
* More vacuum/index-maintenance overhead

The goal is not:

> **Maximum number of indexes**

The goal is:

> **The smallest useful set of indexes that efficiently supports important workloads.**

---

# 8.23 Indexing Strategy for This Blog System

Based on the application's query patterns, the main candidates are:

### `blog_posts`

```sql
CREATE INDEX idx_blog_posts_author
ON blog_posts(author_id);
```

```sql
CREATE INDEX idx_blog_posts_published_at
ON blog_posts(published_at DESC)
WHERE post_status = 'published';
```

Potential composite version:

```sql
CREATE INDEX idx_blog_posts_author_published
ON blog_posts(
    author_id,
    published_at DESC
)
WHERE post_status = 'published';
```

Potential covering version:

```sql
CREATE INDEX idx_blog_posts_author_published_covering
ON blog_posts(
    author_id,
    published_at DESC
)
INCLUDE (blog_post_id, title)
WHERE post_status = 'published';
```

These should **not all automatically coexist**. They represent alternative designs that should be evaluated against actual workloads.

---

### `comments`

```sql
CREATE INDEX idx_comments_post_created
ON comments(
    blog_post_id,
    created_at DESC
);
```

Potentially:

```sql
CREATE INDEX idx_comments_user_created
ON comments(
    user_id,
    created_at DESC
);
```

depending on user-comment access patterns.

---

### `post_view_logs`

```sql
CREATE INDEX idx_view_logs_post_time
ON post_view_logs(
    blog_post_id,
    viewed_at DESC
);
```

```sql
CREATE INDEX idx_view_logs_user_time
ON post_view_logs(
    user_id,
    viewed_at DESC
);
```

Potential BRIN:

```sql
CREATE INDEX idx_view_logs_viewed_at_brin
ON post_view_logs
USING BRIN(viewed_at);
```

Again, the BRIN index should be evaluated based on table size and physical correlation.

---

### `post_categories`

```sql
CREATE INDEX idx_post_categories_category
ON post_categories(cat_id);
```

The primary key already handles the reverse direction beginning with `blog_post_id`.

---

# 8.24 Index Design Matrix

| Query Pattern              | Candidate Index                                  | Type                |
| -------------------------- | ------------------------------------------------ | ------------------- |
| Posts by author            | `(author_id)`                                    | B-tree              |
| Latest published posts     | `(published_at DESC) WHERE published`            | Partial B-tree      |
| Author's latest posts      | `(author_id, published_at DESC) WHERE published` | Composite + Partial |
| Post comments              | `(blog_post_id, created_at DESC)`                | Composite B-tree    |
| User comments              | `(user_id, created_at DESC)`                     | Composite B-tree    |
| Post view history          | `(blog_post_id, viewed_at DESC)`                 | Composite B-tree    |
| User view history          | `(user_id, viewed_at DESC)`                      | Composite B-tree    |
| Category → posts           | `(cat_id)`                                       | B-tree              |
| Full-text search           | `search_vector`                                  | GIN                 |
| Huge time-ordered view log | `viewed_at`                                      | BRIN                |

---

# 8.25 Table Partitioning

Partitioning is related to large-table performance and maintenance, but **partitioning is not an index type**.

For this system, the main candidate is:

```text
post_view_logs
```

because it can become extremely large and is naturally time-based.

Conceptually:

```text
post_view_logs
       │
       ├── 2026-01
       ├── 2026-02
       ├── 2026-03
       ├── 2026-04
       └── ...
```

A range-partitioned design could use:

```sql
CREATE TABLE post_view_logs (
    view_log_id BIGINT GENERATED ALWAYS AS IDENTITY,
    blog_post_id BIGINT NOT NULL,
    user_id BIGINT,
    viewed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
)
PARTITION BY RANGE (viewed_at);
```

Then partitions can be created by time period.

For example:

```sql
CREATE TABLE post_view_logs_2026_09
PARTITION OF post_view_logs
FOR VALUES FROM ('2026-09-01')
             TO ('2026-10-01');
```

### Why Partition?

Partitioning can help with:

* Time-range queries
* Data retention
* Removing old data
* Maintenance
* Managing very large tables

### Important

Partitioning should not be added simply because a table is large.

The workload must justify it.

---

# 8.26 Indexing vs Partitioning

These solve different problems.

### Index

```text
Table
 ↓
Index
 ↓
Find relevant rows efficiently
```

### Partitioning

```text
Large table
 ↓
Partitions
 ↓
Eliminate irrelevant partitions
 ↓
Search relevant partition(s)
```

They can also be combined.

For example:

```text
post_view_logs
      ↓
range partition by viewed_at
      ↓
B-tree indexes inside partitions
```

---

# 8.27 Final Indexing Strategy

The indexing strategy for this project can be summarized as:

```text
Business Query
      ↓
Identify access pattern
      ↓
Filtering?
      ↓
Ordering?
      ↓
Join?
      ↓
Large table?
      ↓
Choose index type
      │
      ├── B-tree
      ├── Composite
      ├── Partial
      ├── INCLUDE
      ├── GIN
      └── BRIN
      ↓
Implement candidate index
      ↓
Phase 09
EXPLAIN ANALYZE
      ↓
Measure actual benefit
```

---

# 8.28 Recommended Index File


> ➡️ [View Indexes](../sql/schema/03-index_blog_system.sql)




The final executable index definitions should remain in:

```text
sql/
└── schema/
    └── 03-indexes-blog-system.sql
```



