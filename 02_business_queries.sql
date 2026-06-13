-- ============================================================
-- Ad Campaign SQL Project
-- File: 02_business_queries.sql
-- Description: 8 business problem solutions — Basic to Advanced
-- Author: Sabin Mainali
-- Platform: Oracle 23ai Free
-- ============================================================


-- ============================================================
-- LEVEL 1: CORE RELATIONAL LOGIC (JOINs)
-- ============================================================

-- ------------------------------------------------------------
-- PROBLEM 1: Client Mapping
-- Business Need: List all Campaign Names alongside the Client
-- Name of the company that owns them.
-- Used by: Marketing team to verify campaign ownership
-- Tested Skill: INNER JOIN traversing foreign keys
-- ------------------------------------------------------------

SELECT
    c.CampaignName,
    cl.ClientName
FROM Campaigns c
INNER JOIN Clients cl ON c.ClientID = cl.ClientID;

-- Note: INNER JOIN ensures we only return records where a strict
-- match exists between both tables. Campaigns without a matching
-- client will be excluded.


-- ------------------------------------------------------------
-- PROBLEM 2: Multi-Hop Filter
-- Business Need: Find the Show Name and Air Date for every ad
-- spot purchased specifically by the client "TechNova".
-- Used by: Account managers reviewing TechNova's media plan
-- Tested Skill: Traversing 4 tables with specific WHERE filter
-- ------------------------------------------------------------

SELECT
    s.ShowName,
    a.AirDate
FROM Ad_Logs a
JOIN Campaigns c  ON a.CampaignID = c.CampaignID
JOIN Clients cl   ON c.ClientID   = cl.ClientID
JOIN TV_Shows s   ON a.ShowID     = s.ShowID
WHERE cl.ClientName = 'TechNova';

-- Note: This traverses the entire schema from the transactional
-- event (Ad_Logs) all the way to the top-level dimension (Clients).
-- The join path follows the foreign key chain:
-- Ad_Logs → Campaigns → Clients and Ad_Logs → TV_Shows


-- ============================================================
-- LEVEL 2: BI DATA PREP (Aggregations & Missing Data)
-- ============================================================

-- ------------------------------------------------------------
-- PROBLEM 3: Roster Check
-- Business Need: Sales team needs a list of ALL clients,
-- including those who have never run a campaign.
-- Used by: Sales team to identify inactive clients
-- Tested Skill: LEFT JOIN to preserve all dimensional records
-- ------------------------------------------------------------

SELECT
    cl.ClientName,
    c.CampaignName
FROM Clients cl
LEFT JOIN Campaigns c ON cl.ClientID = c.ClientID;

-- Note: Clients table must be on the LEFT side so no client is
-- dropped if the Campaigns match fails. SkyTravel will appear
-- with NULL in CampaignName since they have no campaigns yet.


-- ------------------------------------------------------------
-- PROBLEM 4: Dashboard Formatting
-- Business Need: List Campaign Names and Total Budgets ensuring
-- missing budgets display as 0.00 instead of NULL.
-- Used by: Power BI dashboard consumers (non-technical users)
-- Tested Skill: COALESCE / NVL for NULL-safe BI output
-- ------------------------------------------------------------

SELECT
    CampaignName,
    COALESCE(TotalBudget, 0.00) AS TotalBudget_Cleaned
FROM Campaigns;

-- Note: NVL() is the Oracle-specific equivalent of COALESCE().
-- Both work in Oracle but COALESCE() is ANSI standard and
-- works across Snowflake, PostgreSQL, and SQL Server as well.
-- Always sanitize NULLs before data reaches Power BI visuals
-- to prevent breaking measures and calculated columns.


-- ------------------------------------------------------------
-- PROBLEM 5: Spend Summary
-- Business Need: Calculate total money spent per campaign
-- across all aired ad spots.
-- Used by: Finance team for campaign spend reconciliation
-- Tested Skill: SUM aggregation, GROUP BY, multi-table JOIN
-- ------------------------------------------------------------

SELECT
    c.CampaignName,
    SUM(COALESCE(a.CostPerSpot, 0)) AS Total_Spend
FROM Ad_Logs a
JOIN Campaigns c ON a.CampaignID = c.CampaignID
GROUP BY c.CampaignName
ORDER BY Total_Spend DESC;

-- Note: Always join to get the descriptive name (CampaignName)
-- rather than just the ID. Business users reading dashboards
-- need names, not surrogate keys.
-- Important distinction: TotalBudget = planned spend (Campaigns)
--                        CostPerSpot = actual spend (Ad_Logs)
-- Always trace actual money to the transactional event table.


-- ------------------------------------------------------------
-- PROBLEM 6: Audience Threshold
-- Business Need: Identify networks that generated more than
-- 30,000 total viewers across all their ads.
-- Used by: Media buyers evaluating network performance
-- Tested Skill: HAVING clause to filter aggregated totals
-- ------------------------------------------------------------

SELECT
    COALESCE(t.Network, 'Unknown') AS Network,
    COUNT(a.LogID)                 AS Total_Ads,
    SUM(COALESCE(a.Viewers, 0))    AS Total_Viewers
FROM TV_Shows t
JOIN Ad_Logs a ON t.ShowID = a.ShowID
GROUP BY COALESCE(t.Network, 'Unknown')
HAVING SUM(COALESCE(a.Viewers, 0)) > 30000
ORDER BY Total_Viewers DESC;

-- Note: WHERE filters individual rows BEFORE aggregation.
--       HAVING filters results AFTER GROUP BY math is completed.
-- Rule: If you need to filter on an aggregate (SUM, COUNT, AVG)
-- you must use HAVING, not WHERE.
-- NULL networks are handled with COALESCE to prevent a NULL
-- group appearing in the output — important for BI cleanliness.


-- ============================================================
-- LEVEL 3: ADVANCED DATA WAREHOUSING (CTEs & Window Functions)
-- ============================================================

-- ------------------------------------------------------------
-- PROBLEM 7: Benchmark Analysis
-- Business Need: Find campaigns with budget strictly greater
-- than the overall average budget.
-- Used by: Marketing director to identify high-investment campaigns
-- Tested Skill: CTE + CROSS JOIN for scalar aggregate comparison
-- ------------------------------------------------------------

WITH AvgBudget AS (
    SELECT AVG(COALESCE(TotalBudget, 0)) AS Avg_Total_Budget
    FROM Campaigns
)
SELECT
    c.CampaignName,
    c.TotalBudget
FROM Campaigns c
CROSS JOIN AvgBudget a
WHERE c.TotalBudget > a.Avg_Total_Budget;

-- Note: The CTE calculates a single scalar value (average budget).
-- CROSS JOIN attaches that single value to every row in Campaigns
-- so the WHERE clause can compare each campaign's budget against it.
-- This CTE + CROSS JOIN pattern is more performant than a correlated
-- subquery in columnar data warehouses like Snowflake because the
-- average is computed only once, not once per row.
-- COALESCE inside AVG treats NULL budgets as 0, including them
-- in the average calculation rather than ignoring them.


-- ------------------------------------------------------------
-- PROBLEM 8: Top Event Tracker
-- Business Need: Find the single most expensive ad spot
-- purchased for each individual campaign.
-- Used by: Operations team to audit premium ad placements
-- Tested Skill: DENSE_RANK window function with PARTITION BY
-- ------------------------------------------------------------

WITH RankedAds AS (
    SELECT
        c.CampaignName,
        a.AirDate,
        a.ShowID,
        a.CostPerSpot,
        DENSE_RANK() OVER (
            PARTITION BY c.CampaignName
            ORDER BY a.CostPerSpot DESC NULLS LAST
        ) AS cost_rank
    FROM Ad_Logs a
    JOIN Campaigns c ON a.CampaignID = c.CampaignID
)
SELECT
    CampaignName,
    AirDate,
    ShowID,
    CostPerSpot
FROM RankedAds
WHERE cost_rank = 1;

-- Note: DENSE_RANK() vs ROW_NUMBER() — why DENSE_RANK here?
-- If two ad spots have identical CostPerSpot, ROW_NUMBER would
-- arbitrarily pick one and drop the other. DENSE_RANK assigns
-- the same rank to ties, preserving all tied records.
-- This is the correct business behavior — we want ALL the most
-- expensive spots, not just one of them.
-- NULLS LAST ensures NULL CostPerSpot values are ranked at the
-- bottom rather than treated as the highest value.
-- PARTITION BY CampaignName resets the ranking for each campaign
-- so we get the top spot per campaign, not overall.


-- ============================================================
-- BONUS: Budget vs Actual Spend Report
-- Business Need: CFO wants budget accountability — compare
-- allocated budget against actual spend per campaign.
-- Show overspend/underspend categorization.
-- Used by: CFO and Finance leadership
-- ============================================================

SELECT
    c.CampaignName,
    COALESCE(c.TotalBudget, 0)        AS Total_Budget,
    SUM(COALESCE(a.CostPerSpot, 0))   AS Actual_Spend,
    COALESCE(c.TotalBudget, 0)
        - SUM(COALESCE(a.CostPerSpot, 0)) AS Budget_Difference,
    CASE
        WHEN COALESCE(c.TotalBudget, 0)
             - SUM(COALESCE(a.CostPerSpot, 0)) > 0 THEN 'Underspend'
        WHEN COALESCE(c.TotalBudget, 0)
             - SUM(COALESCE(a.CostPerSpot, 0)) < 0 THEN 'Overspend'
        WHEN COALESCE(c.TotalBudget, 0)
             - SUM(COALESCE(a.CostPerSpot, 0)) = 0 THEN 'On Budget'
    END AS Budget_Status
FROM Campaigns c
LEFT JOIN Ad_Logs a ON c.CampaignID = a.CampaignID
GROUP BY c.CampaignName, c.TotalBudget
ORDER BY Budget_Difference ASC; -- Most overspent (negative) first

-- Note: LEFT JOIN ensures campaigns with no ad logs still appear
-- with 0 actual spend rather than being excluded from the report.
-- The CASE statement converts raw numbers into business-readable
-- labels — CFOs understand "Overspend" faster than "-25000".
-- This is called Downstream Empathy: anticipating what the
-- business user needs before they ask for it.
