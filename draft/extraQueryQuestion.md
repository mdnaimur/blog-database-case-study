


01. 🟢 General SQL
02. 🟢 JOIN & Aggregation
03. 🟡 Subqueries & CTE
04. 🟠 Window Functions
05. 🟠 Advanced Blog Analytics
06. 🟣 PostgreSQL Features
07. 🔴 Performance & Optimization
08. ⚫ Large-Scale Blog Analytics
09. 🛡️ Transactions & Concurrency
10. 🚀 Production Blog Database

---

| Level           | Questions | Focus                                                             |
| --------------- | --------: | ----------------------------------------------------------------- |
| 🟢 General SQL  |      1–30 | SELECT, JOIN, GROUP BY, subqueries, DML                           |
| 🟠 Advanced SQL |     31–70 | CTE, window functions, recursive SQL, JSONB, PostgreSQL features  |
| 🔴 Performance  |    71–100 | Indexes, EXPLAIN, query optimization, concurrency, large datasets |

### Add these General topics

61. Find the second-highest post view count.

62. Find the third-highest view count **without using `LIMIT/OFFSET`**.

63. Find users who have never created a post.

64. Find users who have created posts but never received a comment.

65. Find posts whose view count is greater than the **average post view count**.

66. Find authors whose post count is greater than the **average author post count**.

67. Find posts that have more comments than the **average number of comments per post**.

68. Find duplicate users based on email.

69. Find duplicate posts based on title and author.

70. Find the latest post created by every user **without window functions**.

### Add these Advanced topics

71. Find the first post created by every author.

72. Find the latest post created by every author.

73. Find authors whose latest post was created within the last 7 days.

74. Calculate each author's percentage contribution to total views.

75. Calculate each post's percentage contribution to its author's total views.

76. Calculate month-over-month post growth.

77. Calculate day-over-day view growth.

78. Find posts whose views increased compared with the previous day.

79. Find consecutive days on which a user was active.

80. Find the longest user activity streak.

81. Find the first and last activity date for every user.

82. Find users who were active in consecutive months.

83. Find the top 3 authors in every category.

84. Find posts that belong to multiple categories.

85. Find categories containing no posts.

86. Find users who commented on their own posts.

87. Find users who commented on every post in a specific category.

88. Find users who viewed but never commented on a post.

89. Find users who commented but never viewed a post.

90. Build a recursive query to represent a hierarchical category structure.

### Add PostgreSQL-specific Advanced Questions

91. Query nested data stored in a `JSONB` column.

92. Find users based on a value inside a JSONB document.

93. Update a specific nested JSONB property.

94. Find posts containing a specific value inside a PostgreSQL array.

95. Find rows where an array contains multiple required values.

96. Use `LATERAL JOIN` to retrieve the top posts for every author.

97. Solve a top-N-per-group problem using `DISTINCT ON`.

98. Compare `DISTINCT ON` with `ROW_NUMBER()` for the same problem.

99. Use `FILTER` to calculate multiple conditional aggregates in one query.

100. Use `generate_series()` to generate a complete date range and identify days with zero activity.

### One important addition

For **database engineering**, I would actually create a **separate practice section** instead of mixing everything into SQL analytics:

