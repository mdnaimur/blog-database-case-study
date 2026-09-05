chapters/
├── phase-00-problem-statement.md
├── phase-01-requirement-analysis.md
├── phase-02-logical-data-modeling.md
├── phase-03-physical-data-modeling.md
├── phase-04-database-design.md
├── phase-05-schema-implementation.md
├── phase-06-seed-data.md
├── phase-07-sql-analysis.md
├── phase-08-indexing.md
├── phase-09-query-optimization.md
└── phase-10-final-analysis.md


# Phase 09 — Query Optimization

This is where you **prove that something was slow and improved**.

`chapters/phase-09-query-optimization.md`

````md
# Phase 09 — Query Optimization

## Objective

Identify expensive queries and improve their execution performance.

## Case Study — Most Viewed Posts

### Before Optimization

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ...
````

### Problem

The query performed a sequential scan on
`post_view_logs`.

### Optimization

Added:

```sql
CREATE INDEX idx_post_view_logs_post_id
ON post_view_logs(post_id);
```

### After Optimization

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ...
```

### Result

| Metric         |   Before |      After |
| -------------- | -------: | ---------: |
| Execution Time |   850 ms |     120 ms |
| Scan           | Seq Scan | Index Scan |

````

Actual EXPLAIN output goes in:

```text
analysis/
└── execution-plans/
    ├── most-viewed-before.txt
    └── most-viewed-after.txt
````

This is your **strongest performance section**.

---

# Phase 10 — Final Analysis

This is **not another SQL section**.

It's the conclusion of the case study.

`chapters/phase-10-final-analysis.md`

```md
# Phase 10 — Final Analysis

## Final Architecture

[Physical ERD]

## Performance Summary

| Query | Before | After | Improvement |
|---|---:|---:|---:|
| Most viewed posts | 850 ms | 120 ms | 85.9% |
| Popular posts | 620 ms | 95 ms | 84.7% |

## Key Decisions

- Normalized core transactional data
- Added indexes based on query patterns
- Used PostgreSQL full-text search
- Used aggregation/materialization where appropriate

## Trade-offs

Indexes improve read performance but increase storage
and write overhead.

## Limitations

- Moderate traffic assumption
- Single PostgreSQL instance
- External media storage

## Conclusion

The final database satisfies the defined functional,
consistency, and performance requirements.
```

---

# So your complete project flow is

```text
Phase 04 — Database Design
        │
        │  "What should the database look like?"
        ↓
Phase 05 — Schema Implementation
        │
        │  "Build it in PostgreSQL"
        ↓
Phase 06 — Seed Data
        │
        │  "Put realistic data into it"
        ↓
Phase 07 — SQL Analysis
        │
        │  "Can we answer business questions?"
        ↓
Phase 08 — Indexing
        │
        │  "What indexes do our queries need?"
        ↓
Phase 09 — Query Optimization
        │
        │  "Can we make expensive queries faster?"
        ↓
Phase 10 — Final Analysis
        │
        │  "What did we achieve?"
        ↓
       DONE
```

### The most important rule

**Don't duplicate your SQL in the Markdown chapters.**

Use:

```text
chapters/
    → explanation
    → decisions
    → selected SQL examples
    → results
    → links

sql/
    → complete executable SQL

analysis/
    → EXPLAIN ANALYZE output
    → benchmarks
    → performance evidence
```

That will make the GitHub repository look like a **professional database case study**, rather than a collection of Markdown files.
