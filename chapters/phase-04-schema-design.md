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
  post_view logs
- post_view_count

## Primary Keys

Each table has a primary key for unique row identification.

## Foreign Keys

Foreign keys enforce relationships between related entities.

Example:

`blog_posts.author_id → authors.id`

## Constraints

**Data Integrity**

> Database integrity is enforced using relational constraints.


The design uses:

- PRIMARY KEY
- FOREIGN KEY
- UNIQUE
- NOT NULL
- CHECK
- DEFAULT

Examples

- Unique email addresses
- Valid foreign key references
- Comment status validation

## Design Decisions

### User and Author

Authors are modeled as an extension of users.

### Blog Posts and Categories

The many-to-many relationship is resolved using `post_categories`.

## Related SQL

> ➡️ [View Schema SQL](../sql/schema/01-tables-blog_system_case_study_schema.sql)

> ➡️ [View Constraints](../sql/schema/02-constraints_blog_system.sql)


