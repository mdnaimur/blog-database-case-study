# Blog Management System - Database Schema Design

## Overview

This document describes the database schema design for a **Blog Management System**.

The system supports:

* User management with role-based access
* Author profiles
* Blog post creation and publishing workflow
* Categories and post categorization
* User comments
* Post view tracking and analytics

The database is designed using **PostgreSQL** with normalization principles, foreign key relationships, indexing, and data integrity constraints.

---

# Database Technology

| Component      | Technology                    |
| -------------- | ----------------------------- |
| Database       | PostgreSQL                    |
| Schema Type    | Relational Database           |
| Primary Keys   | BIGINT Identity Columns       |
| Relationships  | Foreign Keys                  |
| Data Integrity | Constraints + Cascading Rules |

---

# Entity Relationship Overview

```
Users
 |
 |
 +---- Authors
          |
          |
          +---- Blog Posts
                    |
                    |
          +---------+----------+
          |                    |
     Categories            Comments
          |
          |
 Post Categories


Blog Posts
 |
 |
 +---- Post View Count

Blog Posts
 |
 |
 +---- Post View Logs
```

---

# Database Tables

## 1. Users Table

Stores all registered users.

### Purpose

* Authentication
* Authorization
* User identity management

### Columns

| Column     | Type      | Description           |
| ---------- | --------- | --------------------- |
| user_id    | BIGINT    | Primary key           |
| username   | VARCHAR   | Unique username       |
| email      | VARCHAR   | Unique email          |
| password   | VARCHAR   | Hashed password       |
| role       | ENUM      | User permission level |
| created_at | TIMESTAMP | Account creation time |

### User Roles

```
admin
author
reader
```

---

# 2. Authors Table

Stores additional information for users who create blog posts.

### Relationship

```
users (1) ---- (1) authors
```

A user can become an author.

### Columns

| Column              | Type      | Description           |
| ------------------- | --------- | --------------------- |
| author_id           | BIGINT    | Foreign key to users  |
| first_name          | VARCHAR   | Author first name     |
| last_name           | VARCHAR   | Author last name      |
| bio                 | TEXT      | Author description    |
| profile_picture_url | TEXT      | Profile image         |
| author_status       | ENUM      | Author account status |
| created_at          | TIMESTAMP | Creation date         |
| updated_at          | TIMESTAMP | Last update           |

### Author Status

```
active
inactive
banned
```

---

# 3. Blog Posts Table

Stores all blog articles.

### Relationship

```
authors (1)
     |
     |
blog_posts (many)
```

One author can create many posts.

### Columns

| Column       | Type      | Description       |
| ------------ | --------- | ----------------- |
| blog_post_id | BIGINT    | Primary key       |
| author_id    | BIGINT    | Post owner        |
| title        | VARCHAR   | Blog title        |
| content      | TEXT      | Blog content      |
| post_status  | ENUM      | Publishing status |
| created_at   | TIMESTAMP | Creation time     |
| published_at | TIMESTAMP | Publishing time   |
| updated_at   | TIMESTAMP | Last update       |

### Post Status

```
draft
published
archived
```

---

# 4. Categories Table

Stores blog categories.

Examples:

```
Technology
Programming
Database
Career
Tutorial
```

### Columns

| Column        | Type    | Description      |
| ------------- | ------- | ---------------- |
| cat_id        | BIGINT  | Primary key      |
| category_name | VARCHAR | Category name    |
| description   | TEXT    | Category details |

---

# 5. Post Categories Table

Handles the many-to-many relationship between posts and categories.

### Relationship

```
Blog Post
    |
    |
Many Categories
```

Example:

A post:

```
"PostgreSQL Indexing Tutorial"
```

can belong to:

```
Database
Programming
Backend
```

### Columns

| Column       | Type   |
| ------------ | ------ |
| blog_post_id | BIGINT |
| cat_id       | BIGINT |

Primary Key:

```
(blog_post_id, cat_id)
```

---

# 6. Comments Table

Stores user comments on blog posts.

### Relationship

```
User
 |
 |
Comments
 |
 |
Blog Post
```

### Columns

| Column       | Type      | Description   |
| ------------ | --------- | ------------- |
| comment_id   | BIGINT    | Primary key   |
| content      | TEXT      | Comment text  |
| blog_post_id | BIGINT    | Related post  |
| user_id      | BIGINT    | Comment owner |
| created_at   | TIMESTAMP | Comment time  |

---

# 7. Post View Count Table

Stores total views for each post.

### Purpose

Fast access to view statistics.

Example:

```
Post:
How PostgreSQL Works

Views:
15000
```

### Columns

| Column       | Type   |
| ------------ | ------ |
| blog_post_id | BIGINT |
| view_count   | BIGINT |

---

# 8. Post View Logs Table

Stores detailed view history.

### Purpose

Analytics and tracking.

Example:

```
User A viewed Post 10
at
2026-01-01 10:30
```

### Columns

| Column       | Type      |
| ------------ | --------- |
| view_log_id  | BIGINT    |
| blog_post_id | BIGINT    |
| user_id      | BIGINT    |
| viewed_at    | TIMESTAMP |

Anonymous visitors are supported:

```
user_id = NULL
```

---

# Relationships Summary

| Relationship           | Type         |
| ---------------------- | ------------ |
| User → Author          | One-to-One   |
| Author → Blog Posts    | One-to-Many  |
| Blog Post → Comments   | One-to-Many  |
| User → Comments        | One-to-Many  |
| Blog Post → Categories | Many-to-Many |
| Blog Post → View Count | One-to-One   |
| Blog Post → View Logs  | One-to-Many  |

---

# Database Constraints

## Primary Keys

Every table has a unique identifier.

Example:

```
users.user_id
blog_posts.blog_post_id
comments.comment_id
```

---

## Foreign Keys

Maintain relationship integrity.

Example:

```
blog_posts.author_id
        |
        |
authors.author_id
```

---

## Delete Rules

### Cascade Delete

Used when child data should automatically disappear.

Example:

Deleting a post removes:

```
comments
categories relation
view logs
```

---

### Set NULL

Used for optional relationships.

Example:

Deleting a user:

```
post_view_logs.user_id = NULL
```

The view history remains.

---

# Index Strategy

Indexes are created for frequently searched columns.

## Blog Post Indexes

```sql
author_id
post_status
```

Used for:

* Author filtering
* Published post listing

---

## Comment Indexes

```sql
blog_post_id
user_id
```

Used for:

* Loading comments
* User activity lookup

---

## View Log Indexes

```sql
blog_post_id
user_id
```

Used for analytics queries.

---

# Normalization

The database follows normalization principles:

## First Normal Form (1NF)

* Atomic values
* No repeating groups

Example:

Bad:

```
categories:
"Java,Python,SQL"
```

Good:

```
post_categories
---------------
post_id
category_id
```

---

## Second Normal Form (2NF)

Non-key columns depend on the complete primary key.

Example:

```
post_categories

(blog_post_id, cat_id)
```

---

## Third Normal Form (3NF)

No unnecessary duplicate data.

Example:

Author information is separated:

```
users
authors
```

---

# Future Improvements

Possible extensions:

* Likes system
* Bookmarks
* Tags
* Notifications
* User followers
* Post reactions
* Full-text search
* Audit logging
* Soft delete support

---

# Conclusion

This schema provides a scalable foundation for a production-level blog platform.

The design focuses on:

* Data integrity
* Clean relationships
* Query performance
* Maintainability
* Future scalability

Built with PostgreSQL relational database principles.
