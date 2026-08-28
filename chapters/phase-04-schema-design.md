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





## Data Integrity

Database integrity is enforced using relational constraints.

Constraints used

- PRIMARY KEY
- FOREIGN KEY
- UNIQUE
- CHECK
- NOT NULL

Examples

- Unique email addresses
- Valid foreign key references
- Comment status validation