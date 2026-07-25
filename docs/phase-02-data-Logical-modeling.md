Data modeling is the process of converting **business requirements → database structure** before writing SQL.

In this project we are following below format:

```
Requirements
      ↓
Identify Entities
      ↓
Identify Attributes
      ↓
Define Keys
      ↓
Define Relationships
      ↓
Define Cardinality
      ↓
Resolve Many-to-Many
      ↓
Create ER Diagram
      ↓
Normalize Model
      ↓
Validate Model
```

Let's do it for  **Blog Database Case Study**.

---

# Step 1: Identify Entities



Requirement:

> Users can create accounts, authors can publish posts, readers can comment, posts belong to categories.

Find nouns:

```
User
Author
Blog Post
Category
Comment
Post View
Post View Log
```

These become entities.

Initial entity list:

```
Users

Authors

BlogPosts

Categories

Comments

PostViews

PostViewLogs
```

---

# Step 2: Identify Attributes

Now ask:

> What information do we need to store about each entity?

## Users

```
Users

id
username
email
password
role
created_at
```

---

## Authors

```
Authors

id
user_id
author_name
description
created_at
image_url
```

---

## BlogPosts

```
BlogPosts

post_id
author_id
title
content
post_status
published_at
created_at,
updated_at
```

---

## Categories

```
Categories

id
name
description
created_at
```

---

## Comments

```
Comments

comment_id
user_id
post_id
comment_text
status
created_at
```

---

## PostViewLogs

```
PostViewLogs

id
post_id
user_id
viewed_at
ip_address
```

---

# Step 3: Identify Keys

Every entity needs an identifier.

## Primary Keys

A primary key uniquely identifies a row.

```
Users
-----
id PK


BlogPosts
---------
id PK


Comments
--------
id PK
```

---

# Step 4: Identify Foreign Keys

Foreign keys connect tables.

Example:

An author writes posts.

Question:

"Where should author information live?"

Not inside post:

```
BlogPosts

id
title
author_name ❌
```

Instead:

```
Authors

id
user_id


BlogPosts

id
author_id FK
title
```

Relationship:

```
Authors.id

        ↓

BlogPosts.author_id
```

---

# Step 5: Define Relationships

Now describe how entities connect.

## User - Author

Requirement:

> One user can have one author profile.

```
Users

1 -------- 1

Authors
```

Relationship:

One-to-One

---

## Author - BlogPost

Requirement:

> One author can create many posts.

```
Author

1
 |
 |
 N

BlogPost
```

Relationship:

One-to-Many

Foreign key:

```
BlogPosts.author_id
```

---

## User - Comments

Requirement:

> One user can write many comments.

```
User

1
 |
 |
 N

Comments
```

Foreign key:

```
Comments.user_id
```

---

## BlogPost - Comments

Requirement:

> One post can have many comments.

```
BlogPost

1
 |
 |
 N

Comments
```

Foreign key:

```
Comments.post_id
```


---

## BlogPost,Users - PostViewLogs

Requirement:

> One post can have many Views.
> One user can have many Views.

```
BlogPost , Users

1
 |
 |
 N

Views
```

Foreign key:

```
user.post_view_log_id
Blogpost.post_view_log_id
```

---

# Step 6: Resolve Many-to-Many

Important step.

Requirement:

> A blog post can belong to multiple categories.

Problem:

One post:

```
Post A

Category:
Technology
Programming
Database
```

Cannot store:

```
BlogPosts

id
title
category_id
```

because one column cannot hold multiple categories.

Solution:

Create a bridge table.

Before:

```
BlogPosts

      M:N

Categories
```

After:

```
BlogPosts

1
 |
 |
 N

PostCategories

N
 |
 |
 1

Categories
```

New entity:

```
PostCategories

blog_post_id FK

category_id FK
```
 

 ---

Important step.

Requirement:

> A BlogPosts need to count, for count cost we need to separate count name as post_view_count for better aggregate, read/write performance.

new Entity
```
post_view_count
view_count_id
count
```
Problem:

One post:

---

# Step 7: Create Relationship Matrix

Now document it.

| Entity A  | Relationship | Entity B     |
| --------- | ------------ | ------------ |
| Users     | 1:1          | Authors      |
| Authors   | 1:N          | BlogPosts    |
| Users     | 1:N          | Comments     |
| BlogPosts | 1:N          | Comments     |
| BlogPosts | M:N          | Categories   |
| BlogPosts | 1:N          | PostViewLogs |
| Users     | 1:N          | PostViewLogs |

---

# Step 8: Create ER Diagram

Now draw.

```
Users
 |
 | 1:1
 |
Authors
 |
 | 1:N
 |
BlogPosts
 |
 | 1:N
 |
Comments


BlogPosts
 |
 | 1:N
 |
PostViewLogs


BlogPosts
 |
 | M:N
 |
PostCategories
 |
 | M:N
 |
Categories
```

---

# Step 9: Normalize

Check data duplication.

Bad:

```
BlogPosts

id
title
author_name
author_email
```

Problem:

Same author data repeats.

Normalize:

```
Authors

id
name
email


BlogPosts

id
author_id
title
```

Now data is separated.

---

# Step 10: Final Data Model

Final entities:

```
Users
 └── Authors
       └── BlogPosts
              ├── Comments
              ├── PostViewLogs
              └── PostCategories
                       └── Categories
```

This is the complete **data modeling process**.


