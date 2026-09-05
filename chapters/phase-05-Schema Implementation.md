# Phase 05 — Schema Implementation

## Objective

The objective of this phase is to implement the finalized physical database design in PostgreSQL.

The previous phases defined:

```text
Requirements
    ↓
Logical Data Model
    ↓
Physical Data Model
    ↓
Database Design
```

This phase converts that design into executable SQL:

```text
Database Design
      ↓
PostgreSQL DDL
      ↓
Tables
      ↓
Constraints
      ↓
Indexes
      ↓
Verification
```

---

# 5.1 PostgreSQL Schema Structure

The database schema is implemented using separate SQL files based on their responsibility.

```text
sql/
├── schema/
│   ├── 01-tables-blog-system.sql
│   ├── 02-constraints-blog-system.sql
│   └── 03-indexes-blog-system.sql
│
└── verification/
    └── 01-list-tables.sql
```

This separation keeps the implementation organized and prevents different database concerns from being mixed together.

---

# 5.2 Schema Implementation Order

The SQL files must be executed in the correct dependency order.

```text
01-tables
     ↓
02-constraints
     ↓
03-indexes
     ↓
verification
```

### Why this order?

Tables must exist before foreign keys can reference them.

Foreign-key relationships should exist before indexes designed for those relationships are created.

Finally, verification queries confirm that the schema was created successfully.

---

# 5.3 Creating PostgreSQL Types

The database uses PostgreSQL ENUM types for controlled values.

```sql
CREATE TYPE role AS ENUM (
    'admin',
    'author',
    'reader'
);

CREATE TYPE author_status AS ENUM (
    'active',
    'inactive',
    'banned'
);

CREATE TYPE post_status AS ENUM (
    'draft',
    'published',
    'archived'
);
```

These types restrict columns to predefined values.

For example, `post_status` cannot contain an arbitrary value such as:

```text
'unknown_status'
```

when the column uses the `post_status` ENUM.

---

# 5.4 Users Table

The `users` table stores the core user information.

```sql
CREATE TABLE users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role role NOT NULL DEFAULT 'reader',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Important implementation decisions:

* `user_id` uniquely identifies each user.
* Identity generation automatically generates IDs.
* `username` must be unique.
* `email` must be unique.
* `password` stores the password value used by the application for authentication.
* `role` uses the PostgreSQL ENUM.
* New users default to the `reader` role.

> If the column stores a hashed password, `password_hash` would be a clearer production-oriented name.

---

# 5.5 Authors Table

Authors are modeled as an extension of users.

```sql
CREATE TABLE authors (
    author_id BIGINT PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255),
    bio TEXT,
    profile_picture_url TEXT,
    author_status author_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

The important design characteristic is:

```text
authors.author_id
        ↓
users.user_id
```

The foreign-key relationship is added later in the constraints file.

This creates a one-to-one extension:

```text
users
  │
  └── authors
```

Only users represented in the `authors` table have author-specific information.

---

# 5.6 Blog Posts Table

The `blog_posts` table stores the main blog content.

```sql
CREATE TABLE blog_posts (
    blog_post_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    author_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    post_status post_status NOT NULL DEFAULT 'draft',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Important fields include:

| Column         | Purpose                        |
| -------------- | ------------------------------ |
| `blog_post_id` | Unique post identifier         |
| `author_id`    | Post author                    |
| `title`        | Post title                     |
| `content`      | Post content                   |
| `post_status`  | Draft/published/archived state |
| `created_at`   | Creation timestamp             |
| `published_at` | Publication timestamp          |
| `updated_at`   | Last update timestamp          |

`author_id` is `NOT NULL` because every blog post must have an author.

---

# 5.7 Categories Table

Categories organize blog posts.

```sql
CREATE TABLE categories (
    cat_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT
);
```

The unique constraint prevents duplicate category names.

For example, the database should not contain two identical categories such as:

```text
Technology
Technology
```

---

# 5.8 Post Categories Table

A blog post can belong to multiple categories, and a category can contain multiple posts.

Therefore, the many-to-many relationship is implemented through a junction table.

```sql
CREATE TABLE post_categories (
    blog_post_id BIGINT NOT NULL,
    cat_id BIGINT NOT NULL,
    PRIMARY KEY (blog_post_id, cat_id)
);
```

The composite primary key:

```text
(blog_post_id, cat_id)
```

prevents the same post-category relationship from being inserted twice.

Example:

```text
Post 1 → Technology
Post 1 → PostgreSQL
Post 2 → Technology
```

---

# 5.9 Comments Table

The `comments` table stores user comments on blog posts.

```sql
CREATE TABLE comments (
    comment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    blog_post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL
);
```

Each comment contains references to:

```text
User
  ↓
Comment
  ↓
Blog Post
```

The actual foreign-key constraints are added separately.

---

# 5.10 Post View Count Table

The project uses a counter table for fast access to total post views.

```sql
CREATE TABLE post_view_count (
    blog_post_id BIGINT PRIMARY KEY,
    view_count BIGINT NOT NULL DEFAULT 0
);
```

This table is intentionally different from `post_view_logs`.

```text
post_view_logs
    ↓
Detailed view events

post_view_count
    ↓
Current aggregated count
```

`post_view_count` is therefore a **derived/denormalized structure** used for efficient reads.

It is not part of the core logical entity model.

---

# 5.11 Post View Logs Table

The `post_view_logs` table stores individual view events.

```sql
CREATE TABLE post_view_logs (
    view_log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    blog_post_id BIGINT NOT NULL,
    user_id BIGINT,
    viewed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

`user_id` is nullable because a view may come from an unauthenticated visitor.

Therefore:

```text
Authenticated visitor
    → user_id available

Anonymous visitor
    → user_id = NULL
```

This allows the system to retain anonymous view events.

---

# 5.12 Foreign-Key Implementation

After all tables have been created, relationships are added using `ALTER TABLE`.

### Author → User

```sql
ALTER TABLE authors
ADD CONSTRAINT fk_author_user
FOREIGN KEY (author_id)
REFERENCES users(user_id)
ON DELETE CASCADE;
```

This implements the one-to-one extension between users and authors.

---

### Blog Post → Author

```sql
ALTER TABLE blog_posts
ADD CONSTRAINT fk_post_author
FOREIGN KEY (author_id)
REFERENCES authors(author_id)
ON DELETE CASCADE;
```

A post cannot reference a non-existent author.

---

### Post Categories → Blog Posts

```sql
ALTER TABLE post_categories
ADD CONSTRAINT fk_pc_post
FOREIGN KEY (blog_post_id)
REFERENCES blog_posts(blog_post_id)
ON DELETE CASCADE;
```

### Post Categories → Categories

```sql
ALTER TABLE post_categories
ADD CONSTRAINT fk_pc_category
FOREIGN KEY (cat_id)
REFERENCES categories(cat_id)
ON DELETE CASCADE;
```

Together these constraints enforce the many-to-many relationship.

---

# 5.13 Comment Foreign Keys

```sql
ALTER TABLE comments
ADD CONSTRAINT fk_comment_post
FOREIGN KEY (blog_post_id)
REFERENCES blog_posts(blog_post_id)
ON DELETE CASCADE;

ALTER TABLE comments
ADD CONSTRAINT fk_comment_user
FOREIGN KEY (user_id)
REFERENCES users(user_id)
ON DELETE CASCADE;
```

These constraints ensure that comments reference valid posts and users.

---

# 5.14 View Data Foreign Keys

The counter table references the post:

```sql
ALTER TABLE post_view_count
ADD CONSTRAINT fk_viewcount_post
FOREIGN KEY (blog_post_id)
REFERENCES blog_posts(blog_post_id)
ON DELETE CASCADE;
```

View logs reference the post:

```sql
ALTER TABLE post_view_logs
ADD CONSTRAINT fk_viewlog_post
FOREIGN KEY (blog_post_id)
REFERENCES blog_posts(blog_post_id)
ON DELETE CASCADE;
```

The user reference uses `SET NULL`:

```sql
ALTER TABLE post_view_logs
ADD CONSTRAINT fk_viewlog_user
FOREIGN KEY (user_id)
REFERENCES users(user_id)
ON DELETE SET NULL;
```

This is intentional.

If a user is deleted, historical view events can remain while the user reference becomes `NULL`.

---

# 5.15 Index Implementation

Indexes are implemented separately.

```sql
CREATE INDEX idx_blog_posts_author
ON blog_posts(author_id);

CREATE INDEX idx_blog_posts_status
ON blog_posts(post_status);

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

These indexes support common relationship and filtering patterns.

The detailed reasoning for index selection belongs to **Phase 08 — Indexing**.

Performance validation belongs to **Phase 09 — Query Optimization**.

---

# 5.16 Schema Verification

After implementation, the database should be verified.

The project includes:

```text
sql/
└── verification/
    └── 01-list-tables.sql
```

The verification query is:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';
```

This confirms that the expected tables exist in the PostgreSQL `public` schema.

Further verification can check:

* Tables
* Columns
* Constraints
* Foreign keys
* Indexes
* ENUM types

The purpose of verification is to ensure that the implemented database matches the intended design.

---

# 5.17 Final Schema Structure

After implementation, the database structure is:

```text
users
 │
 ├── authors
 │      │
 │      └── blog_posts
 │              │
 │              ├── post_categories ── categories
 │              │
 │              ├── comments
 │              │
 │              ├── post_view_count
 │              │
 │              └── post_view_logs
 │
 └── comments
```

The implementation therefore preserves the relationships defined during the modeling phases.

---

# 5.18 Implementation Summary

The schema implementation follows a clear separation of responsibilities:

```text
01-tables
    │
    ├── ENUM types
    ├── Tables
    ├── Columns
    ├── Primary Keys
    └── Basic Constraints
         ↓
02-constraints
    │
    ├── Foreign Keys
    └── Referential Actions
         ↓
03-indexes
    │
    └── Query-supporting Indexes
         ↓
verification
    │
    └── Validate Implementation
```

This structure makes the PostgreSQL schema easier to:

* Execute
* Review
* Debug
* Maintain
* Extend
* Version-control

---

# 5.19 Related Project Files

### Schema Implementation

➡️ [Tables](../sql/schema/01-tables-blog_system_case_study_schema.sql)

➡️ [Constraints](../sql/schema/02-constraints_blog_system.sql)

➡️ [Indexes](../sql/schema/03-index_blog_system.sql)

### Verification

➡️ [List Tables](../sql/schema/verification/01-list-tables.sql)

### Previous Phase

➡️ [Phase 04 — Database Design](/chapters/phase-04-schemaDB-design.md)

### Next Phase

➡️ [Phase 06 — Seed Data](/chapters/phase-06-Seed%20Data.md)

---
