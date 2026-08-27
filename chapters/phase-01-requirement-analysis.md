
# 1. System Overview

We are building a **blog platform system** where:

- Users can register and manage profiles
- Authors can create and manage blog posts
- Readers can view, search, and interact with posts
- System tracks engagement (views, comments, popularity)

---

# 2. Functional Requirements

## 2.1 User Management

- Users can register using email, username, and password
- Users can log in using their credentials
- Users can update their profile information
- System supports role-based access control (User, Author, Admin)


---

## 2.2 Blog Post Management

- Authors can create, read, update, and delete blog posts (CRUD)
- Each blog post contains:
  - title
  - content
  - publication date
  - author reference
- Blog posts can belong to multiple categories
- Users can filter posts by:
  - category
  - publication date
  - popularity (views)

---

## 2.3 Commenting System

- Users can comment on blog posts
- Authors can approve or delete comments on their posts
- Comments are displayed in chronological order
- Each comment is linked to a user and a blog post

---



## 2.4 Content Organization & Search

- Authors can create and manage categories
- Blog posts can be searched by:
  - keywords in title
  - keywords in content
- Full-text search support is expected (PostgreSQL feature)

---

## 2.5 Derived State Tracking (Analytics)

- Track total view count per blog post
- Store detailed post view logs (timestamp, optional user info)
- Identify popular posts using aggregated data
- Use materialized views for performance optimization

---

# 3. Non-Functional Requirements

- System runs on a web-based architecture with PostgreSQL database
- Must support up to 1000 concurrent users
- Ensure data consistency across:
  - posts
  - comments
  - views
  - logs
- Blog listing and popular posts must load within 2 seconds
- Use indexing, caching, and query optimization for performance
- The system should support efficient searching and retrieval(indexing)
- The system should respond to common user requests within 2 seconds.
- The system should support future scalability.

---

# 4. Assumptions and Constraints

- System uses PostgreSQL as the primary database
- Media uploads (images/videos) are supported with limited storage (stored externally, DB stores URLs)
- Email addresses must be validated and unique (enforced via database constraints)
- System assumes moderate traffic (not large-scale distributed system)



---

# 5. Data Requirements

The system must store the following entities:

## Users
- Stores user account information:
  - email
  - username
  - password
  - bio
  - role (user, author, admin)

## Authors
- Stores author-specific metadata (can be extended from users)

## Blog Posts
- Stores blog content:
  - title
  - content
  - publication date
  - author_id

## Categories
- Stores category information:
  - name
  - description

## Comments
- Stores user comments:
  - comment text
  - user_id
  - post_id
  - timestamp
  - status (approved/pending/removed)

## Post Views
- Stores total view count per blog post

## Post View Logs
- Stores detailed view events:
  - post_id
  - user_id (optional)
  - timestamp

## Popular Posts
- Stores aggregated popularity metrics
- Can be implemented using materialized views or summary tables


---

# 6. Business Rules

## User Rules

1. Each user must have a unique email address.
2. Each user must have a unique username.
3. Each user is assigned exactly one role (User, Author, or Admin).
4. Only authenticated users can access protected features.

---

## Author Rules

1. Only users with the **Author** role can create, publish, edit, or delete blog posts.
2. An author may create multiple blog posts.
3. Every published blog post must have exactly one author.

---

## Blog Post Rules

1. Every blog post must have a title.
2. Every blog post must contain content before publication.
3. A blog post must belong to at least one category.
4. A blog post may belong to multiple categories.
5. A blog post cannot be published without an assigned author.

---

## Category Rules

1. Category names must be unique.
2. A category may contain multiple blog posts.

---

## Comment Rules

1. Only authenticated users can create comments.
2. Every comment belongs to exactly one blog post.
3. Every comment is created by exactly one user.
4. Comments may require approval before becoming visible.
5. Only approved comments are visible to readers.

---

## View Tracking Rules

1. Every view log records one blog post view.
2. A view log may optionally be associated with a registered user.
3. A blog post may have multiple view logs.
4. Popular posts are calculated from view statistics and engagement data.

---

# 7. Relationship Rules

| Entity A  | Entity B     | Cardinality            | Description                                                                                       |
| --------- | ------------ | ---------------------- | ------------------------------------------------------------------------------------------------- |
| Users     | BlogPosts    | One-to-Many            | One author can create many blog posts. Each blog post has exactly one author.                     |
| BlogPosts | Categories   | Many-to-Many           | A blog post may belong to multiple categories, and each category may contain multiple blog posts. |
| Users     | Comments     | One-to-Many            | One user can create many comments. Each comment belongs to one user.                              |
| BlogPosts | Comments     | One-to-Many            | One blog post can have many comments. Each comment belongs to one blog post.                      |
| BlogPosts | PostViewLogs | One-to-Many            | One blog post can have many view log records.                                                     |
| Users     | PostViewLogs | One-to-Many (Optional) | A registered user may generate many view logs. Anonymous views are also allowed.                  |
