chapters/
├── phase-00-problem-statement.md
├── phase-01-requirement-analysis.md
├── phase-02-logical-data-modeling.md
├── phase-03-physical-data-modeling.md
├── phase-04-database-design.md
├── phase-05-schema-implementation.md
├── phase-06-seed-data.md
├── phase-07-sql-analysis.md
├── phase-08-indexing.md
├── phase-09-query-optimization.md
└── phase-10-final-analysis.md

## Phase 04 — Database Design

**Purpose:** Decide the final database structure before implementation.

`chapters/phase-04-database-design.md`

```md
# Phase 04 — Database Design

## Objective

Translate the logical and physical models into the final PostgreSQL
database design.

## Tables

The database contains:

- users
- authors
- blog_posts
- categories
- post_categories
- comments
- post_view_logs

## Primary Keys

Each table has a primary key for unique row identification.

## Foreign Keys

Foreign keys enforce relationships between related entities.

Example:

`blog_posts.author_id → authors.id`

## Constraints

The design uses:

- PRIMARY KEY
- FOREIGN KEY
- UNIQUE
- NOT NULL
- CHECK
- DEFAULT

## Design Decisions

### User and Author

Authors are modeled as an extension of users.

### Blog Posts and Categories

The many-to-many relationship is resolved using `post_categories`.

## Related SQL

➡️ [View Schema SQL](../sql/schema/)

➡️ [View Constraints](../sql/schema/constraints.sql)
```

So **don't paste 300 lines of SQL into the chapter**.

---

# Phase 05 — Schema Implementation

**Purpose:** Actually create the PostgreSQL objects.

`chapters/phase-05-schema-implementation.md`

````md
# Phase 05 — Schema Implementation

## Objective

Implement the database design in PostgreSQL.

## Implementation

The schema was implemented using PostgreSQL DDL.

### Example

```sql
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE
);
````

The complete implementation is available here:

➡️ [Schema SQL](../sql/schema/)

````

Actual file:

```text
sql/
└── schema/
    ├── 01-tables.sql
    ├── 02-constraints.sql
    ├── 03-indexes.sql
    └── 04-views.sql
````

**Chapter = explanation + small examples.**
**SQL folder = complete executable SQL.**

---

# Phase 06 — Seed Data

**Purpose:** Put realistic data into the database.

`chapters/phase-06-seed-data.md`

````md
# Phase 06 — Seed Data

## Objective

Populate the database with realistic data for testing and query
performance.

## Dataset

| Entity | Approx. Rows |
|---|---:|
| Users | 10,000 |
| Authors | 1,000 |
| Blog Posts | 20,000 |
| Categories | 50 |
| Comments | 100,000 |
| View Logs | 500,000 |

## Execution Order

Users
→ Authors
→ Categories
→ Posts
→ Post Categories
→ Comments
→ View Logs

## Example

```sql
INSERT INTO categories (name)
VALUES ('Technology');
````

➡️ [View Seed SQL](../seed/)

````

Actual data generation/inserts stay in:

```text
seed/
├── 01-users.sql
├── 02-authors.sql
├── 03-categories.sql
├── 04-posts.sql
└── ...
````

---

# Phase 07 — SQL Analysis

This is where you show **real business questions**.

`chapters/phase-07-sql-analysis.md`

````md
# Phase 07 — SQL Analysis

## Objective

Analyze the blog data using real-world business queries.

## Query 01 — Most Viewed Posts

### Business Question

Which posts are the most viewed?

### SQL

```sql
SELECT
    p.id,
    p.title,
    COUNT(v.id) AS view_count
FROM blog_posts p
JOIN post_view_logs v
    ON v.post_id = p.id
GROUP BY p.id, p.title
ORDER BY view_count DESC
LIMIT 10;
````

### Result

[show result/table]

### Related SQL

➡️ [View Query](../sql/queries/most-viewed-posts.sql)

---

## Query 02 — Most Active Commenters

...

## Query 03 — Top Posts by Category

...

````

This phase is about **querying the database**, not optimizing it.

---

# Phase 08 — Indexing

Now you ask:

> What indexes should this database have based on actual query patterns?

`chapters/phase-08-indexing.md`

```md
# Phase 08 — Indexing

## Objective

Design indexes to support frequent and important queries.

## Query Pattern

The following query frequently filters posts by author:

```sql
SELECT *
FROM blog_posts
WHERE author_id = 10;
````

## Index

```sql
CREATE INDEX idx_blog_posts_author_id
ON blog_posts(author_id);
```

➡️ [View Index SQL](../sql/indexes/)

````

Then discuss:

```text
B-tree
Composite index
Partial index
GIN / Full-text search
Unique index
````

**Important:** Don't just list indexes.

Explain:

> Query pattern → index choice → reason.

---

# Phase 09 — Query Optimization

This is where you **prove that something was slow and improved**.

`chapters/phase-09-query-optimization.md`

````md
# Phase 09 — Query Optimization

## Objective

Identify expensive queries and improve their execution performance.

## Case Study — Most Viewed Posts

### Before Optimization

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ...
````

### Problem

The query performed a sequential scan on
`post_view_logs`.

### Optimization

Added:

```sql
CREATE INDEX idx_post_view_logs_post_id
ON post_view_logs(post_id);
```

### After Optimization

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ...
```

### Result

| Metric         |   Before |      After |
| -------------- | -------: | ---------: |
| Execution Time |   850 ms |     120 ms |
| Scan           | Seq Scan | Index Scan |

````

Actual EXPLAIN output goes in:

```text
analysis/
└── execution-plans/
    ├── most-viewed-before.txt
    └── most-viewed-after.txt
````

This is your **strongest performance section**.

---

# Phase 10 — Final Analysis

This is **not another SQL section**.

It's the conclusion of the case study.

`chapters/phase-10-final-analysis.md`

```md
# Phase 10 — Final Analysis

## Final Architecture

[Physical ERD]

## Performance Summary

| Query | Before | After | Improvement |
|---|---:|---:|---:|
| Most viewed posts | 850 ms | 120 ms | 85.9% |
| Popular posts | 620 ms | 95 ms | 84.7% |

## Key Decisions

- Normalized core transactional data
- Added indexes based on query patterns
- Used PostgreSQL full-text search
- Used aggregation/materialization where appropriate

## Trade-offs

Indexes improve read performance but increase storage
and write overhead.

## Limitations

- Moderate traffic assumption
- Single PostgreSQL instance
- External media storage

## Conclusion

The final database satisfies the defined functional,
consistency, and performance requirements.
```

---

# So your complete project flow is

```text
Phase 04 — Database Design
        │
        │  "What should the database look like?"
        ↓
Phase 05 — Schema Implementation
        │
        │  "Build it in PostgreSQL"
        ↓
Phase 06 — Seed Data
        │
        │  "Put realistic data into it"
        ↓
Phase 07 — SQL Analysis
        │
        │  "Can we answer business questions?"
        ↓
Phase 08 — Indexing
        │
        │  "What indexes do our queries need?"
        ↓
Phase 09 — Query Optimization
        │
        │  "Can we make expensive queries faster?"
        ↓
Phase 10 — Final Analysis
        │
        │  "What did we achieve?"
        ↓
       DONE
```

### The most important rule

**Don't duplicate your SQL in the Markdown chapters.**

Use:

```text
chapters/
    → explanation
    → decisions
    → selected SQL examples
    → results
    → links

sql/
    → complete executable SQL

analysis/
    → EXPLAIN ANALYZE output
    → benchmarks
    → performance evidence
```

That will make the GitHub repository look like a **professional database case study**, rather than a collection of Markdown files.
