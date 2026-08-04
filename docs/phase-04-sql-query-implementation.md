

# 📘 PostgreSQL SQL Practice Questions

## 🟢 1. GENERAL SQL

### Basic Analytics

1. Find the **top 10 most viewed posts**.

2. Find the **top 10 most viewed posts** along with the author's name and post title.

3. Find the **most active authors** based on the number of posts they have published.

4. Find the posts with the **highest number of comments**.

5. Calculate a **viral score** for each post using:

   * Views = 1 point
   * Comments = 3 points

   Return the top 10 posts.

### Feed & Content

6. Retrieve the **10 latest posts** for a homepage feed.

7. Retrieve the **20 most recently published posts** where the post status is `published`.

8. Build a homepage feed showing:

   * Post ID
   * Title
   * Creation date
   * Author username
   * View count
   * Comment count

### User Analytics

9. Find the **most active users** based on their total views and comments.

10. Find each user's:

* Total comments
* Total views
* Activity score

### Trending

11. Find the **top 10 trending posts from the last 7 days**, based on views.

12. Create a **trend score** using:

* Views = 1 point
* Comments = 3 points

Return the top 10 posts from the last 7 days.

### Content Gap

13. Find all posts that **have no comments**.

14. Solve the same problem using `NOT EXISTS`.

### Category Analytics

15. Find the **number of posts in each category**, including categories with zero posts.

### Author Dashboard

16. Build an **author directory** showing:

* User ID
* Username
* Bio
* Profile picture
* Author status
* Creation date

17. Find all **banned authors**.

---

# 🟠 2. ADVANCED SQL

## Window Functions & Ranking

18. Rank all posts by their **view count** using `ROW_NUMBER()`.

19. Find the **most viewed post for each author**.

20. Find the **top 3 most viewed posts for each author**.

21. Find the **most popular post in each category** based on views.

22. Create a **user engagement leaderboard** by ranking users according to their total comments and views.

23. Calculate the **daily ranking of posts** based on the number of views received each day.

24. Calculate the **running number of views for each post over time**.

25. Create an **A/B testing ranking comparison** showing:

* Old ranking using `RANK()`
* New ranking using `DENSE_RANK()`

---

# 🔴 3. PERFORMANCE & OPTIMIZATION

## Query Optimization

26. Find the **top 10 most viewed posts** and determine which indexes would improve this query.

27. Optimize a query that retrieves **recent published posts ordered by `published_at`**.

28. Optimize a query that retrieves posts together with their **view counts and comment counts**.

29. Analyze a query that joins `posts`, `comments`, and `post_view_counts` and determine whether it can produce **row multiplication**.

30. Rewrite a query that uses multiple joins and aggregations to avoid **unnecessary duplicate rows**.

### Indexing

31. Determine which indexes should be created for a query filtering posts by `post_status` and ordering by `published_at`.

32. Determine the appropriate indexes for finding **recent posts from the last 7 days**.

33. Determine which indexes would improve queries filtering `comments` by `post_id`.

34. Determine which indexes would improve queries filtering `post_view_logs` by:

* `post_id`
* `user_id`
* `viewed_at`

35. Design indexes for efficiently retrieving the **top posts per author**.

### Execution Plans

36. Use `EXPLAIN` to analyze a query that retrieves the latest 20 published posts.

37. Use `EXPLAIN ANALYZE` to identify the expensive operations in a multi-table analytics query.

38. Compare the execution plans of:

* `LEFT JOIN ... IS NULL`
* `NOT EXISTS`

39. Compare the performance of:

* Correlated subquery
* CTE
* JOIN

40. Determine whether PostgreSQL is using an **Index Scan, Bitmap Index Scan, or Sequential Scan**, and explain why.

### Aggregation Performance

41. Optimize a query that calculates **comment counts for every post**.

42. Optimize a query that calculates **view counts for every user**.

43. Optimize a query that calculates both **views and comments per user** without creating a Cartesian multiplication effect.

44. Compare the performance of calculating aggregates using:

* Multiple joins
* Separate CTEs
* Pre-aggregated subqueries

### Window Function Performance

45. Analyze the performance of ranking millions of posts using `ROW_NUMBER()`.

46. Determine how indexing can help a query using:

`PARTITION BY user_id ORDER BY view_count DESC`

47. Optimize a query that finds the **top 3 posts per author** from a very large posts table.

48. Compare the performance of:

* Window functions
* `DISTINCT ON`
* `LATERAL JOIN`

for finding the top post per author.

### Large-Scale Analytics

49. Design a query capable of calculating **daily post rankings** efficiently when `post_view_logs` contains millions of rows.

50. Optimize a **7-day trending-post query** when the view-log table contains hundreds of millions of records.

51. Design an efficient strategy for calculating **running views** over a very large view-log table.

52. Determine when a **materialized view** would be better than calculating analytics directly from transactional tables.

53. Design a materialized-view strategy for **trending posts**.

54. Determine when a **summary table / counter table** should be used instead of `COUNT(*)` on a large log table.

### Advanced PostgreSQL Performance

55. Identify queries that could benefit from **partial indexes**.

56. Identify queries that could benefit from **covering indexes using `INCLUDE`**.

57. Determine when **BRIN indexes** would be more appropriate than B-tree indexes for `post_view_logs`.

58. Analyze whether partitioning `post_view_logs` by date would improve the 7-day analytics queries.

59. Design a partitioning strategy for a view-log table containing **billions of records**.

60. Determine how **table statistics and `ANALYZE`** can affect PostgreSQL query planning.

---

# 🎯 Practice Progression

| Level          | Questions | Main Focus                                             |
| -------------- | --------: | ------------------------------------------------------ |
| 🟢 General     |      1–17 | SELECT, JOIN, GROUP BY, filtering, aggregation         |
| 🟠 Advanced    |     18–25 | CTEs, Window Functions, Ranking                        |
| 🔴 Performance |     26–60 | Indexing, EXPLAIN, optimization, large-scale analytics |

**Recommended order:**
**General → Advanced → Performance**

Don't look for the answer first. For each question, try to write the query yourself, then test it against PostgreSQL and inspect the execution plan where appropriate.
