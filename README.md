# Ad Campaign SQL Project

A real-world SQL project built around a **TV advertising and campaign management domain** — simulating the kind of data environment found at media technology companies like Imagine Communications, where ad scheduling, broadcast analytics, and revenue reporting are core business functions.

## Business Context

TV advertising operations generate large volumes of transactional data — every ad spot aired, every campaign budget allocated, every viewer reached. The data team's job is to transform that raw event data into actionable insights for marketing directors, finance teams, and regional sales managers.

This project simulates that environment using four related tables and eight progressive business problems — from basic joins to advanced window functions and CTEs.

## Database Schema

| Table | Rows | Description |
|---|---|---|
| `Clients` | 5 | Advertisers running campaigns (TechNova, AutoDrive, etc.) |
| `TV_Shows` | 5 | Broadcast programs where ads are aired |
| `Campaigns` | 6 | Marketing initiatives with allocated budgets |
| `Ad_Logs` | 10 | Transactional event log of every aired ad spot |

### Entity Relationship

```
Clients (1) ──→ (*) Campaigns (1) ──→ (*) Ad_Logs (*) ←── (1) TV_Shows
```

### Schema

```sql
CREATE TABLE Clients (
    ClientID   NUMBER PRIMARY KEY,
    ClientName VARCHAR2(100),
    Industry   VARCHAR2(50)
);

CREATE TABLE TV_Shows (
    ShowID   NUMBER PRIMARY KEY,
    ShowName VARCHAR2(100),
    Network  VARCHAR2(50)
);

CREATE TABLE Campaigns (
    CampaignID   NUMBER PRIMARY KEY,
    ClientID     NUMBER,
    CampaignName VARCHAR2(100),
    TotalBudget  NUMBER(10,2)
);

CREATE TABLE Ad_Logs (
    LogID       NUMBER PRIMARY KEY,
    CampaignID  NUMBER,
    ShowID      NUMBER,
    AirDate     DATE,
    Viewers     NUMBER,
    CostPerSpot NUMBER(10,2)
);
```

## Business Problems Solved

### Level 1 — Core Relational Logic (JOINs)

**Problem 1 — Client Mapping**
List all Campaign Names alongside the Client Name of the company that owns them.
Tested Skill: `INNER JOIN` traversing foreign keys.

**Problem 2 — Multi-Hop Filter**
Find the Show Name and Air Date for every ad spot purchased specifically by the client "TechNova".
Tested Skill: Traversing three tables (`Clients → Campaigns → Ad_Logs → TV_Shows`) with a specific `WHERE` filter.

---

### Level 2 — BI Data Prep (Aggregations & Missing Data)

**Problem 3 — Roster Check**
The sales team needs a list of all clients, including those who have never run a campaign, showing NULL if no campaign exists.
Tested Skill: `LEFT JOIN` to prevent data loss for inactive dimensional records.

**Problem 4 — Dashboard Formatting**
List all Campaign Names and their Total Budgets, ensuring any missing budgets display as 0.00 instead of NULL.
Tested Skill: Defensive coding using `COALESCE()` / `NVL()` to prevent breaking downstream Power BI visuals.

**Problem 5 — Spend Summary**
Calculate the total amount of money spent across all aired ads for each Campaign.
Tested Skill: Standard aggregations using `SUM()`, `GROUP BY`, multi-table `JOIN`.

**Problem 6 — Audience Threshold**
Identify the specific Networks that generated more than 30,000 total viewers across all their ads.
Tested Skill: Using the `HAVING` clause to filter aggregated totals.

---

### Level 3 — Advanced Data Warehousing (CTEs & Window Functions)

**Problem 7 — Benchmark Analysis**
Find the Campaign Names and Budgets for campaigns that have a budget strictly greater than the overall average budget.
Tested Skill: Modularizing logic using a CTE (`WITH` clause) and comparing row data against a scalar aggregate using `CROSS JOIN`.

**Problem 8 — Top Event Tracker**
Find the single most expensive ad spot purchased for each individual campaign.
Tested Skill: Advanced Window Functions using `DENSE_RANK() OVER (PARTITION BY CampaignName ORDER BY CostPerSpot DESC NULLS LAST)` to rank events without losing row-level granularity.

## Key SQL Concepts Demonstrated

- Multi-table JOINs (INNER, LEFT, multi-hop 4-table traversal)
- Aggregate functions with GROUP BY (SUM, COUNT, AVG)
- NULL handling with COALESCE — differentiating SUM vs AVG NULL behavior
- HAVING clause for post-aggregation filtering
- Common Table Expressions (CTEs) for modular, readable logic
- Window Functions (DENSE_RANK with PARTITION BY)
- CROSS JOIN for scalar aggregate comparisons
- CASE WHEN for business-readable output categorization
- Budget vs Actual Spend analysis (planned vs transactional data)

## Key Concepts — Data Warehousing

**Star Schema**
Power BI performs best with a Star Schema. Highly normalized OLTP tables must be transformed into wide, text-heavy Dimension tables (e.g., `Dim_Campaign`) and narrow, number-heavy Fact tables (e.g., `Fact_AdBroadcasts`) to optimize memory and dashboard speed.

**Slowly Changing Dimensions (SCD Type 2)**
When a business attribute changes (e.g., a TV show changes networks), historical truth must be preserved. The strategy involves expiring the old record, inserting a new active record, and generating a unique Surrogate Key so that historical Fact table data remains linked to the correct past state.

**Downstream Empathy**
A good data warehouse developer anticipates BI needs. This includes replacing NULLs with meaningful defaults, ensuring granular accuracy before aggregating, and including descriptive text names alongside IDs for business user readability.

**Budget vs Actual Spend**
- `TotalBudget` = planned spend (Campaigns table)
- `SUM(CostPerSpot)` = actual spend (Ad_Logs table)
Never use budget figures to report actual spend — always trace money to the transactional event table.

## Files

| File | Description |
|---|---|
| `01_schema_and_data.sql` | CREATE TABLE statements and INSERT data |
| `02_business_queries.sql` | 8 business problem solutions with comments |

## Platform

- **Database:** Oracle 23ai Free (Docker) / Snowflake
- **Client:** DBeaver
- **BI Layer:** Power BI

## Author

**Sabin Mainali**
SQL Developer & Data Analyst | Toronto, ON
[LinkedIn](https://www.linkedin.com/in/sabinmainali) | [GitHub](https://github.com/sabinmainali)
