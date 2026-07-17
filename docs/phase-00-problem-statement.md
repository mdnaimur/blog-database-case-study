# Software Requirements Specification (SRS) for Blog System

---

# 1. Introduction

## 1.1 Purpose

This document outlines the requirements for a simple blog system designed for users to create, manage, and view blog posts.

The system will provide a platform for authors to publish content and readers to browse and comment on posts.

## 1.2 Scope

The blog system will allow users to:

- Register and log in
- Manage their profiles
- Create, edit, and delete blog posts (Authors)
- Browse blog posts by category
- Leave comments
- Track post views

The system will support:

- Basic content management
- User interaction
- Derived state persistence for analytics

---

# 2. Functional Requirements

## 2.1 User Management

- **FR1:** The system shall allow users to register with an email, username, and password.
- **FR2:** The system shall allow users to log in using their credentials.
- **FR3:** The system shall allow users to update their profile information (e.g., username, bio).
- **FR4:** The system shall support role-based access, distinguishing between regular users and authors.

---

## 2.2 Blog Post Management

- **FR5:** Authors shall be able to create blog posts with a title, content, and publication date.
- **FR6:** Authors shall be able to edit or delete their own blog posts.
- **FR7:** The system shall allow blog posts to be assigned to one or more categories.
- **FR8:** The system shall display a list of blog posts with filters for:
  - Categories
  - Publication date
  - Post views

---

## 2.3 Commenting System

- **FR9:** Users shall be able to post comments on blog posts.
- **FR10:** Authors shall be able to moderate (approve or delete) comments on their blog posts.
- **FR11:** The system shall display comments in chronological order under each blog post.

---

## 2.4 Content Organization

- **FR12:** The system shall allow authors to create and manage categories for organizing blog posts.
- **FR13:** The system shall support searching blog posts by keywords in the title or content.

---

## 2.5 Derived State Tracking

- **FR14:** The system shall track and persist the number of post views for each blog post to display view counts.
- **FR15:** The system shall maintain post view logs to record each view event with:
  - Timestamp
  - User information (if available)
  - Analytics purposes
- **FR16:** The system shall provide a popular posts list based on aggregated post views over a specified time period (e.g., last 30 days).

---

# 3. Non-Functional Requirements

- **NFR1:** The system shall be accessible via a web browser.
- **NFR2:** The system shall handle up to **1,000 concurrent users**.
- **NFR3:** The system shall ensure data consistency for:
  - Blog posts
  - Comments
  - Post views
  - Post view logs
- **NFR4:** The system shall load a list of blog posts or popular posts within **2 seconds** under normal conditions.

---

# 4. Assumptions and Constraints

- The system will be built using **PostgreSQL** for data storage.
- The initial version will not include features such as:
  - Multimedia uploads
  - Social media integration
- All users must have a valid email address to register.

---

# 5. Data Requirements

The following entities require persistent storage and are likely candidates for database tables.

| Entity | Description |
|---------|-------------|
| **Users** | Store user information such as email, username, password, and bio. |
| **Authors** | Store author-specific information or roles, potentially linked to users. |
| **Blog Posts** | Store post details such as title, content, publication date, and author. |
| **Categories** | Store category names and descriptions for organizing posts. |
| **Comments** | Store user comments linked to blog posts and users. |
| **Post Views** | Store the total view count for each blog post. |
| **Post View Logs** | Store detailed view events, including timestamps and optional user information. |
| **Popular Posts** | Store aggregated view data for ranking posts by popularity over a specified time period (e.g., using a materialized view). |

---