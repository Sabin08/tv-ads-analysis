-- ============================================================
-- Ad Campaign SQL Project
-- File: 01_schema_and_data.sql
-- Description: Schema and sample data for TV ad campaign domain
-- Author: Sabin Mainali
-- Platform: Oracle 23ai Free
-- ============================================================


-- ============================================================
-- SCHEMA
-- ============================================================

-- Clients: Advertisers running campaigns
CREATE TABLE Clients (
    ClientID   NUMBER PRIMARY KEY,
    ClientName VARCHAR2(100),
    Industry   VARCHAR2(50)
);

-- TV_Shows: Broadcast programs where ads are aired
CREATE TABLE TV_Shows (
    ShowID   NUMBER PRIMARY KEY,
    ShowName VARCHAR2(100),
    Network  VARCHAR2(50)
);

-- Campaigns: Marketing initiatives with allocated budgets
-- TotalBudget can be NULL for campaigns still in planning
CREATE TABLE Campaigns (
    CampaignID   NUMBER PRIMARY KEY,
    ClientID     NUMBER,
    CampaignName VARCHAR2(100),
    TotalBudget  NUMBER(10,2)
);

-- Ad_Logs: Transactional event log of every aired ad spot
-- This is the FACT table — all money and viewer metrics live here
CREATE TABLE Ad_Logs (
    LogID       NUMBER PRIMARY KEY,
    CampaignID  NUMBER,
    ShowID      NUMBER,
    AirDate     DATE,
    Viewers     NUMBER,
    CostPerSpot NUMBER(10,2)
);


-- ============================================================
-- SAMPLE DATA
-- ============================================================

INSERT INTO Clients VALUES (1, 'TechNova', 'Technology');
INSERT INTO Clients VALUES (2, 'AutoDrive', 'Automotive');
INSERT INTO Clients VALUES (3, 'FreshMart', 'Retail');
INSERT INTO Clients VALUES (4, 'HealthPlus', 'Healthcare');
INSERT INTO Clients VALUES (5, 'SkyTravel', 'Tourism');

INSERT INTO TV_Shows VALUES (1, 'Morning Buzz', 'NBC');
INSERT INTO TV_Shows VALUES (2, 'Sports Central', 'ESPN');
INSERT INTO TV_Shows VALUES (3, 'Prime Time News', 'CNN');
INSERT INTO TV_Shows VALUES (4, 'Tech Today', 'BBC');
INSERT INTO TV_Shows VALUES (5, 'Weekend Live', 'ABC');

-- Note: SkyTravel (ClientID 5) has no ad logs — tests LEFT JOIN behavior
INSERT INTO Campaigns VALUES (1, 1, 'TechNova Q1 Push', 50000);
INSERT INTO Campaigns VALUES (2, 1, 'TechNova Summer', 75000);
INSERT INTO Campaigns VALUES (3, 2, 'AutoDrive Launch', 120000);
INSERT INTO Campaigns VALUES (4, 3, 'FreshMart Sale', 30000);
INSERT INTO Campaigns VALUES (5, 4, 'HealthPlus Awareness', 45000);
INSERT INTO Campaigns VALUES (6, 5, 'SkyTravel Deals', NULL); -- NULL budget: still in planning

INSERT INTO Ad_Logs VALUES (1,  1, 2, DATE '2024-01-10', 45000, 1500);
INSERT INTO Ad_Logs VALUES (2,  1, 3, DATE '2024-01-15', 28000, 1200);
INSERT INTO Ad_Logs VALUES (3,  2, 1, DATE '2024-06-01', 52000, 2000);
INSERT INTO Ad_Logs VALUES (4,  2, 4, DATE '2024-06-10', 31000, 1800);
INSERT INTO Ad_Logs VALUES (5,  3, 2, DATE '2024-03-05', 67000, 3500);
INSERT INTO Ad_Logs VALUES (6,  3, 5, DATE '2024-03-12', 41000, 2800);
INSERT INTO Ad_Logs VALUES (7,  4, 1, DATE '2024-04-20', 29000,  900);
INSERT INTO Ad_Logs VALUES (8,  5, 3, DATE '2024-05-01', 38000, 1600);
INSERT INTO Ad_Logs VALUES (9,  5, 2, DATE '2024-05-15', 55000, 2200);
INSERT INTO Ad_Logs VALUES (10, 1, 5, DATE '2024-02-20', 22000, 1100);

COMMIT;
