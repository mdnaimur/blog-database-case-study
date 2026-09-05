# Phase 06 — Seed Data

## Objective

The objective of this phase is to populate the PostgreSQL blog database with a realistic dataset for development, SQL analysis, indexing, and query-performance testing.

Instead of manually writing thousands of `INSERT` statements, the project uses **Node.js and Faker.js** to generate synthetic data.

The seeding architecture is:

```text
Node.js
   ↓
Faker.js
   ↓
Generated Test Data
   ↓
PostgreSQL
   ↓
Blog Database
```

The seed script uses:

* Node.js
* `@faker-js/faker`
* `pg`
* PostgreSQL

---

# 6.1 Why Faker.js Is Used

The project requires a sufficiently large dataset to test realistic database queries and performance.

Manually creating thousands of records would be:

* Time-consuming
* Difficult to maintain
* Difficult to reproduce
* Poor for performance testing

Faker.js provides programmatically generated data such as:

```text
Usernames
Names
Emails
Biographies
Titles
Content
Comments
Dates
Images
```

This allows the project to generate a large synthetic dataset automatically.

---

# 6.2 Seed Dataset

The current seed script generates approximately:

| Data             | Quantity |
| ---------------- | -------: |
| Users            |   10,000 |
| Authors          |  10,000* |
| Categories       |        5 |
| Blog Posts       |  10,000* |
| Comments         |   30,000 |
| Post View Counts |  10,000* |
| Post View Logs   |   50,000 |

* These quantities are a consequence of the current implementation.

The important point is that the dataset is large enough to support later SQL analysis and performance experiments.

---

# 6.3 Seed Script Structure

The seed script is organized into separate functions.

```text
insertUsers()
     ↓
insertAuthors()
     ↓
insertCategories()
     ↓
insertPosts()
     ↓
insertPostCategories()
     ↓
insertComments()
     ↓
insertViewCounts()
     ↓
insertViewLogs()
```

The functions are exported so that a separate runner can execute them in the required order.

```js
module.exports = {
  insertUsers,
  insertAuthors,
  insertCategories,
  insertPosts,
  insertPostCategories,
  insertComments,
  insertViewCounts,
  insertViewLogs
};
```

---

# 6.4 Users

The first stage generates 10,000 users.

```js
async function insertUsers() {
  for (let i = 1; i <= 10000; i++) {
    const role =
      i <= 2
        ? "admin"
        : i <= 5
        ? "author"
        : "reader";

    await client.query(
      `INSERT INTO users (username, email, password, role)
       VALUES ($1, $2, $3, $4)`,
      [
        `${faker.internet.username()}_${i}`,
        `user${i}@example.com`,
        "hashed_password",
        role
      ]
    );
  }
}
```

The generated role distribution is:

```text
Users
├── 2 admins
├── 3 authors
└── 9,995 readers
```

The username is combined with the loop index:

```text
faker-generated-username_1
faker-generated-username_2
...
```

This helps maintain uniqueness.

The emails are deterministic:

```text
user1@example.com
user2@example.com
...
user10000@example.com
```

---

# 6.5 Authors

The author data is generated from existing users.

```js
async function insertAuthors() {
  const users = await client.query(
    `SELECT user_id FROM users`
  );

  for (const user of users.rows) {
    await client.query(
      `INSERT INTO authors
       (author_id, bio, first_name, last_name,
        profile_picture_url, author_status)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        user.user_id,
        faker.lorem.paragraph(),
        faker.person.firstName(),
        faker.person.lastName(),
        faker.image.avatar(),
        faker.helpers.arrayElement([
          "active",
          "inactive"
        ])
      ]
    );
  }
}
```

The important relationship is:

```text
users.user_id
      ↓
authors.author_id
```

Because the current implementation selects **all users**, every user receives an author record.

Therefore, although only three users have the `author` role, the current seed script creates approximately:

```text
10,000 users
10,000 authors
```

### Implementation Note

If the intended business rule is:

> Only users whose role is `author` should exist in the `authors` table.

then `insertAuthors()` should later be changed to select only author-role users.

That is a seed-script correction, not a database-model requirement.

---

# 6.6 Categories

Five categories are inserted into the database.

```js
const categories = [
  "Technology",
  "Programming",
  "Database",
  "Backend",
  "JavaScript"
];
```

Each category receives a Faker-generated description.

The resulting structure is:

```text
Technology
Programming
Database
Backend
JavaScript
```

These categories are later used to establish post-category relationships.

---

# 6.7 Blog Posts

Posts are generated from the existing authors.

```js
async function insertPosts() {
  const authors = await client.query(
    `SELECT author_id FROM authors`
  );

  for (const author of authors.rows) {
    await client.query(
      `INSERT INTO blog_posts
       (author_id, title, content, post_status, published_at)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        author.author_id,
        faker.lorem.sentence(),
        faker.lorem.paragraphs(3),
        faker.helpers.arrayElement([
          "published",
          "draft"
        ]),
        faker.date.recent()
      ]
    );
  }
}
```

Because the function creates one post for every author, the current seed process generates approximately:

```text
10,000 authors
      ↓
10,000 blog posts
```

Post status is randomly selected:

```text
published
draft
```

---

# 6.8 Publication Date Consideration

The current implementation generates `published_at` for both published and draft posts.

Conceptually:

```text
published
    → published_at = date

draft
    → published_at = NULL
```

would be more semantically consistent.

Therefore, the seed script could later be adjusted so that `published_at` is generated only when:

```text
post_status = 'published'
```

This is particularly important because Phase 07 contains queries that analyze published posts.

---

# 6.9 Post Categories

Posts are connected to categories through the junction table.

```js
async function insertPostCategories() {
  const posts = await client.query(
    `SELECT blog_post_id FROM blog_posts`
  );

  const categories = await client.query(
    `SELECT cat_id FROM categories`
  );

  for (const post of posts.rows) {
    const randomCategory =
      categories.rows[
        Math.floor(
          Math.random() * categories.rows.length
        )
      ];

    await client.query(
      `INSERT INTO post_categories
       (blog_post_id, cat_id)
       VALUES ($1, $2)`,
      [
        post.blog_post_id,
        randomCategory.cat_id
      ]
    );
  }
}
```

Each post receives one randomly selected category.

For example:

```text
Post 1 → Database
Post 2 → Backend
Post 3 → JavaScript
Post 4 → Technology
```

### Current Implementation

Although the database supports a many-to-many relationship, the current seed script creates only **one category relationship per post**.

Therefore, the seed data does not fully demonstrate multiple categories per post.

If the goal is to stress-test the M:N relationship, multiple categories per post could be generated later.

---

# 6.10 Comments

The script generates 30,000 comments.

```js
for (let i = 1; i <= 30000; i++) {
  const randomUser =
    users.rows[
      Math.floor(Math.random() * users.rows.length)
    ];

  const randomPost =
    posts.rows[
      Math.floor(Math.random() * posts.rows.length)
    ];

  await client.query(
    `INSERT INTO comments
     (content, blog_post_id, user_id)
     VALUES ($1, $2, $3)`,
    [
      faker.lorem.sentences(2),
      randomPost.blog_post_id,
      randomUser.user_id
    ]
  );
}
```

The user and post are selected randomly.

Therefore:

```text
30,000 comments
        ↓
random users
        +
random posts
```

This produces a varied distribution of comments across the blog posts.

---

# 6.11 View Count

The `post_view_count` table receives one record for each post.

```js
await client.query(
  `INSERT INTO post_view_count
   (blog_post_id, view_count)
   VALUES ($1, $2)`,
  [
    post.blog_post_id,
    faker.number.int({
      min: 0,
      max: 1000
    })
  ]
);
```

Each post receives a randomly generated view count between:

```text
0 → 1,000
```

The purpose is to provide a fast summary value for post-view analytics.

---

# 6.12 View Logs

The script generates 50,000 detailed view events.

```js
for (let i = 1; i <= 50000; i++) {
  const randomUser =
    users.rows[
      Math.floor(Math.random() * users.rows.length)
    ];

  const randomPost =
    posts.rows[
      Math.floor(Math.random() * posts.rows.length)
    ];

  await client.query(
    `INSERT INTO post_view_logs
     (blog_post_id, user_id)
     VALUES ($1, $2)`,
    [
      randomPost.blog_post_id,
      randomUser.user_id
    ]
  );
}
```

The resulting relationship is:

```text
50,000 view events
       ↓
Random User
       +
Random Post
```

This dataset supports later queries involving:

* Total views
* User activity
* Trending posts
* View aggregation
* Time-based analysis

---

# 6.13 Important View-Data Distinction

The project contains two different representations of views:

```text
post_view_logs
      │
      └── Individual events

post_view_count
      │
      └── Aggregated count
```

The current seed script generates these independently.

Therefore:

```text
post_view_count.view_count
```

does **not necessarily equal**:

```sql
COUNT(*)
FROM post_view_logs
WHERE blog_post_id = ...
```

This is acceptable if the counter table is being used as synthetic derived data for demonstrating denormalization.

However, if the project intends `post_view_count` to represent the exact total of the seeded view logs, the counter should instead be calculated from `post_view_logs`.

---

# 6.14 Referential Integrity

The seed process respects the dependency structure of the database.

```text
Users
  ↓
Authors
  ↓
Posts
  ↓
Post Categories
```

and:

```text
Users ──────────→ Comments
Posts ──────────→ Comments
```

and:

```text
Users ──────────→ View Logs
Posts ──────────→ View Logs
```

This ensures that generated foreign-key values correspond to existing records.

---

# 6.15 Seed Data Scale

The dataset provides a useful workload for the case study:

```text
10,000 users
10,000 authors
10,000 posts
30,000 comments
50,000 view logs
```

This gives the project enough data to demonstrate realistic relational operations.

For example:

```text
10K posts
   ↓
JOIN
   ↓
30K comments
   ↓
Aggregation
```

and:

```text
10K posts
   ↓
50K view logs
   ↓
Aggregation
   ↓
Ranking
```

This becomes particularly useful in Phase 08 and Phase 09.

---

# 6.16 Seed Data and SQL Analysis

The generated dataset directly supports the analytical queries from Phase 07.

| Analysis               | Seed Data                    |
| ---------------------- | ---------------------------- |
| Top viewed posts       | View data                    |
| Active authors         | Authors + posts              |
| Most commented posts   | Comments                     |
| User activity          | Users + comments + views     |
| Trending posts         | View logs                    |
| Category statistics    | Categories + post categories |
| Top posts per author   | Posts + authors              |
| Posts without comments | Posts + comments             |

The seed data therefore acts as the foundation for the SQL analysis phase.

---

# 6.17 Seed Data and Performance Analysis

The dataset also provides the workload required for:

```text
Index Testing
     ↓
EXPLAIN
     ↓
EXPLAIN ANALYZE
     ↓
Query Optimization
```

For example, the 50,000 view-log rows provide a larger table on which to analyze:

* Aggregation
* Filtering
* Index scans
* Sequential scans
* Composite indexes
* Time-based queries

The dataset is therefore not only sample data—it is also a **test workload for database performance analysis**.

---

# 6.18 Verification

After seeding, the dataset should be verified.

### Row Counts

```sql
SELECT 'users' AS table_name, COUNT(*) AS row_count
FROM users

UNION ALL

SELECT 'authors', COUNT(*)
FROM authors

UNION ALL

SELECT 'blog_posts', COUNT(*)
FROM blog_posts

UNION ALL

SELECT 'categories', COUNT(*)
FROM categories

UNION ALL

SELECT 'post_categories', COUNT(*)
FROM post_categories

UNION ALL

SELECT 'comments', COUNT(*)
FROM comments

UNION ALL

SELECT 'post_view_count', COUNT(*)
FROM post_view_count

UNION ALL

SELECT 'post_view_logs', COUNT(*)
FROM post_view_logs;
```

Expected approximate result:

```text
users              → 10,000
authors            → 10,000
blog_posts         → 10,000
categories         → 5
post_categories    → 10,000
comments           → 30,000
post_view_count    → 10,000
post_view_logs     → 50,000
```

---

# 6.19 Seed Process

The complete data-generation process is:

```text
Start
  ↓
Connect to PostgreSQL
  ↓
Insert 10,000 Users
  ↓
Insert Authors
  ↓
Insert 5 Categories
  ↓
Insert Blog Posts
  ↓
Assign Categories
  ↓
Insert 30,000 Comments
  ↓
Insert View Counts
  ↓
Insert 50,000 View Logs
  ↓
Verify Dataset
  ↓
Database Ready
```

---

# 6.20 Implementation Characteristics

The current seeding implementation intentionally uses a straightforward approach:

```text
Faker.js
+
for loop
+
Parameterized INSERT
+
PostgreSQL
```

Parameterized queries are used:

```sql
VALUES ($1, $2, $3, $4)
```

rather than constructing SQL strings directly from generated values.

This provides safer SQL construction and keeps the database interaction structured.

---

# 6.21 Performance Consideration of the Seeder

The current implementation performs individual database queries inside loops.

For example:

```text
10,000 users
→ 10,000 INSERT queries

30,000 comments
→ 30,000 INSERT queries

50,000 view logs
→ 50,000 INSERT queries
```

This makes the seeding implementation simple and easy to understand, but it is not the most efficient approach for very large datasets.

For a larger production-style data generator, possible improvements include:

```text
Batch INSERT
COPY
Transactions
Prepared Statements
Bulk Loading
```

These are optimization opportunities for the **seeding process itself**, not the database query optimization discussed in Phase 09.

---

# 6.22 Final Seed Architecture

The completed seed architecture is:

```text
                  Faker.js
                     │
                     ↓
                 Node.js
                     │
                     ↓
              PostgreSQL Client
                     │
                     ↓
        ┌──────────────────────────┐
        │      PostgreSQL DB       │
        ├──────────────────────────┤
        │ Users                    │
        │ Authors                  │
        │ Categories               │
        │ Blog Posts               │
        │ Post Categories          │
        │ Comments                 │
        │ Post View Count          │
        │ Post View Logs           │
        └──────────────────────────┘
                     │
                     ↓
             SQL Analysis
                     │
                     ↓
           Query Optimization
```

---

# 6.23 Phase 06 Summary

The project uses Faker.js to generate a large synthetic PostgreSQL dataset instead of manually creating records.

The current seed process generates approximately:

```text
10,000 Users
10,000 Authors
5 Categories
10,000 Blog Posts
10,000 Post-Category Relationships
30,000 Comments
10,000 View Counters
50,000 View Logs
```

The generated dataset provides the foundation for:

```text
Phase 07
SQL Analysis
      ↓
Phase 08
Indexing
      ↓
Phase 09
Query Optimization
```

The most important purpose of the seed phase is not merely populating the database—it is creating a **realistic and sufficiently large workload for analytical and performance evaluation**.

---

## Related Project Files

### Schema

➡️ [Tables](../sql/schema/01-tables-blog_system_case_study_schema.sql)

➡️ [Constraints](../sql/schema/02-constraints_blog_system.sql)

➡️ [Indexes](../sql/schema/03-index_blog_system.sql)

### Seed Implementation

➡️ `../seed/`

### Previous Phase

➡️ [Phase 05 — Schema Implementation](/chapters/phase-05-Schema%20Implementation.md)

### Next Phase

➡️ [Phase 07 — SQL Analysis](/chapters/phase-07-sql-analysis.md)

---

