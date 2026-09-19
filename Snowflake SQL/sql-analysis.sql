-- 1. Create Analytics Environment
CREATE DATABASE IF NOT EXISTS HEALTHCARE_DB;
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_DB.CLINICAL_ANALYTICS;

USE DATABASE HEALTHCARE_DB;
USE SCHEMA CLINICAL_ANALYTICS;

-- 1. Create staging table matched to updated Pandas schema
CREATE OR REPLACE TABLE STG_HEALTHCARE_READMISSIONS (
    "Record_ID" INT PRIMARY KEY,
    "Encounter_ID" VARCHAR(50),
    "Patient_ID" VARCHAR(50),
    "Provider_ID" VARCHAR(50),
    "Age" INT,
    "Gender" VARCHAR(20),
    "Blood Type" VARCHAR(10),
    "Medical Condition" VARCHAR(100),
    "Date of Admission" DATE,
    "Hospital" VARCHAR(150),
    "Insurance Provider" VARCHAR(100),
    "Billing Amount" NUMBER(12, 2),
    "Admission Type" VARCHAR(50),
    "Discharge Date" DATE,
    "Medication" VARCHAR(100),
    "Test Results" VARCHAR(50),
    "Length_of_Stay" INT,
    "Age_Group" VARCHAR(20),
    "Days_Since_Prior_Discharge" FLOAT NULL,
    "Is_Readmitted_30_Days" INT
);

-- 
select * from STG_HEALTHCARE_READMISSIONS 

-- What is the baseline 30-day readmission rate across all hospital admissions, 
-- and what is the total billing amount tied to readmitted encounters?


SELECT 
    -- 1. Total Admissions across the entire hospital
    COUNT(*) AS TOTAL_ADMISSIONS,
    
    -- 2. Total 30-Day Readmitted Encounters
    SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) AS TOTAL_READMISSIONS,
    
    -- 3. Overall 30-Day Readmission Rate (%)
    ROUND(
        (SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS READMISSION_RATE_PCT,
    
    -- 4. Total Billed Amount across ALL patients
    ROUND(SUM("Billing Amount"), 2) AS TOTAL_BILLED_AMOUNT,
    
    -- 5. Total Billed Amount tied ONLY to 30-Day Readmissions (Financial Risk)
    ROUND(
        SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN "Billing Amount" ELSE 0 END), 
        2
    ) AS READMISSION_FINANCIAL_RISK
FROM STG_HEALTHCARE_READMISSIONS;


-- Which Medical Condition (e.g., Diabetes, Hypertension) experiences the highest 30-day readmission percentage?

Select 
    "Medical Condition",
    Count(*) as Total_Admissions,
    SUM("Billing Amount") as Total_Billed_Amount,
     ROUND(
        SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN "Billing Amount" ELSE 0 END), 
        2
    ) AS READMISSION_FINANCIAL_RISK,
    SUM(Case when "Is_Readmitted_30_Days" = 1 then 1 else 0 end) as Total_Readmissions,
    ROUND(SUM((Case when "Is_Readmitted_30_Days" = 1 then 1 else 0 end) * 100) / Total_Admissions,2) as Readmission_PCT
from STG_HEALTHCARE_READMISSIONS
GROUP BY "Medical Condition"
Order by Readmission_PCT DESC


-- How do Test Results (Abnormal, Inconclusive, Normal) combined with specific Medication types impact readmission likelihood?

SELECT 
    "Test Results",
    "Medication",
    
    -- 1. Total Admissions per combination
    COUNT(*) AS TOTAL_ADMISSIONS,
    
    -- 2. Total Readmissions per combination
    SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) AS READMITTED_COUNT,
    
    -- 3. Readmission Rate (%)
    ROUND(
        (SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS READMISSION_RATE_PCT

FROM STG_HEALTHCARE_READMISSIONS
GROUP BY "Test Results", "Medication"
ORDER BY READMISSION_RATE_PCT DESC;


-- What is the average Length_of_Stay (LOS) by Admission Type (Emergency, Elective, Urgent) across different Hospital branches?

SELECT 
    "Hospital",
    "Admission Type",
    COUNT(*) AS TOTAL_ADMISSIONS,
    ROUND(AVG("Length_of_Stay"), 1) AS AVG_LENGTH_OF_STAY_DAYS,
    SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) AS TOTAL_READMISSIONS,
    ROUND((SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS READMISSION_RATE_PCT
FROM STG_HEALTHCARE_READMISSIONS
GROUP BY "Hospital", "Admission Type"
ORDER BY AVG_LENGTH_OF_STAY_DAYS DESC;

--- Which Doctor (or Provider) has treated the highest volume of patients, and what is their corresponding 30-day readmission rate and total billing generated?

select * from STG_HEALTHCARE_READMISSIONS

SELECT 
    "Provider_ID",
    
    COUNT(*) AS TOTAL_ENCOUNTERS,
    
    SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) AS TOTAL_READMISSIONS,
    
    ROUND(
        (SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS READMISSION_RATE_PCT,
    
    ROUND(SUM("Billing Amount"), 2) AS TOTAL_BILLED_AMOUNT

FROM STG_HEALTHCARE_READMISSIONS
GROUP BY "Provider_ID"
ORDER BY TOTAL_ENCOUNTERS DESC
Limit 50;


-- Does Admission Type (Emergency vs. Elective vs. Urgent) drive higher financial risk and longer lengths of stay overall across the health system?

SELECT 
    "Admission Type",
    
    -- 1. Total Volume
    COUNT(*) AS TOTAL_ADMISSIONS,
    
    -- 2. Bed Utilization (Average Length of Stay in Days)
    ROUND(AVG("Length_of_Stay"), 1) AS AVG_LENGTH_OF_STAY_DAYS,
    
    -- 3. Readmission Rate (%)
    ROUND(
        (SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS READMISSION_RATE_PCT,
    
    -- 4. Total Revenue Generated ($)
    ROUND(SUM("Billing Amount"), 2) AS TOTAL_BILLED_AMOUNT,
    
    -- 5. Financial Exposure from Readmissions ($)
    ROUND(
        SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN "Billing Amount" ELSE 0 END), 
        2
    ) AS READMISSION_FINANCIAL_RISK

FROM STG_HEALTHCARE_READMISSIONS
GROUP BY "Admission Type"
ORDER BY READMISSION_FINANCIAL_RISK DESC;


--  Which Insurance Provider (e.g., Medicare, Medicaid, Private) generates the highest total billing volume, and what is their corresponding 30-day    readmission rate and total financial risk?

SELECT 
    "Insurance Provider",
    
    -- 1. Total Encounters
    COUNT(*) AS TOTAL_ENCOUNTERS,
    
    -- 2. Total Billed Volume ($)
    ROUND(SUM("Billing Amount"), 2) AS TOTAL_BILLED_AMOUNT,
    
    -- 3. Average Billing Amount per Patient ($)
    ROUND(AVG("Billing Amount"), 2) AS AVG_BILLING_PER_PATIENT,
    
    -- 4. Readmission Volume & Percentage (%)
    SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) AS READMITTED_COUNT,
    ROUND(
        (SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS READMISSION_RATE_PCT,
    
    -- 5. Readmission Financial Risk ($)
    ROUND(
        SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN "Billing Amount" ELSE 0 END), 
        2
    ) AS READMISSION_FINANCIAL_RISK

FROM STG_HEALTHCARE_READMISSIONS
GROUP BY "Insurance Provider"
ORDER BY TOTAL_BILLED_AMOUNT DESC;

-- How does Billing Amount vary when cross-analyzing Insurance Provider against Admission Type (Emergency vs. Elective vs. Urgent)?

SELECT 
    "Insurance Provider",
    "Admission Type",
    
    -- 1. Patient Volume
    COUNT(*) AS TOTAL_ENCOUNTERS,
    
    -- 2. Financial Metrics
    ROUND(SUM("Billing Amount"), 2) AS TOTAL_BILLED_AMOUNT,
    ROUND(AVG("Billing Amount"), 2) AS AVG_BILLING_PER_PATIENT,
    
    -- 3. Readmission Impact
    SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) AS READMITTED_COUNT,
    ROUND(
        (SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS READMISSION_RATE_PCT,
    ROUND(
        SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN "Billing Amount" ELSE 0 END), 
        2
    ) AS READMISSION_FINANCIAL_RISK

FROM STG_HEALTHCARE_READMISSIONS
GROUP BY "Insurance Provider", "Admission Type"
ORDER BY "Insurance Provider", TOTAL_BILLED_AMOUNT DESC;


-- How does readmission risk and total billing vary across different patient age brackets or demographic groups?

SELECT 
    -- 1. Categorize patients into standard clinical age groups
    CASE 
        WHEN "Age" < 18 THEN '1. Under 18'
        WHEN "Age" BETWEEN 18 AND 35 THEN '2. 18-35'
        WHEN "Age" BETWEEN 36 AND 50 THEN '3. 36-50'
        WHEN "Age" BETWEEN 51 AND 65 THEN '4. 51-65'
        ELSE '5. 65+ (Senior)'
    END AS AGE_GROUP,
    
    -- 2. Patient Volume
    COUNT(*) AS TOTAL_ENCOUNTERS,
    
    -- 3. Readmission Volume & Percentage (%)
    SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) AS READMITTED_COUNT,
    ROUND(
        (SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS READMISSION_RATE_PCT,
    
    -- 4. Financial Impact
    ROUND(SUM("Billing Amount"), 2) AS TOTAL_BILLED_AMOUNT,
    ROUND(AVG("Billing Amount"), 2) AS AVG_BILLING_PER_PATIENT,
    ROUND(
        SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN "Billing Amount" ELSE 0 END), 
        2
    ) AS READMISSION_FINANCIAL_RISK

FROM STG_HEALTHCARE_READMISSIONS
GROUP BY 
    CASE 
        WHEN "Age" < 18 THEN '1. Under 18'
        WHEN "Age" BETWEEN 18 AND 35 THEN '2. 18-35'
        WHEN "Age" BETWEEN 36 AND 50 THEN '3. 36-50'
        WHEN "Age" BETWEEN 51 AND 65 THEN '4. 51-65'
        ELSE '5. 65+ (Senior)'
    END
ORDER BY AGE_GROUP;

-- How does readmission risk differ when cross-analyzing Gender against primary Medical Condition?

SELECT 
    "Medical Condition",
    "Gender",
    
    -- 1. Patient Volume
    COUNT(*) AS TOTAL_ENCOUNTERS,
    
    -- 2. Readmission Metrics
    SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) AS READMITTED_COUNT,
    ROUND(
        (SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS READMISSION_RATE_PCT,
    
    -- 3. Financial Metrics
    ROUND(SUM("Billing Amount"), 2) AS TOTAL_BILLED_AMOUNT,
    ROUND(AVG("Billing Amount"), 2) AS AVG_BILLING_PER_PATIENT,
    ROUND(
        SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN "Billing Amount" ELSE 0 END), 
        2
    ) AS READMISSION_FINANCIAL_RISK

FROM STG_HEALTHCARE_READMISSIONS
GROUP BY "Medical Condition", "Gender"
ORDER BY "Medical Condition", READMISSION_RATE_PCT DESC;


-- SQL VIEWS CREATION FOR INTERACTIVE DASHBOARDS

-- View 1: Care Quality & Readmission Risk
CREATE OR REPLACE VIEW VW_CARE_QUALITY AS
SELECT 
    "Medical Condition",
    "Test Results",
    "Medication",
    
    -- Volume & Readmission Metrics
    COUNT(*) AS TOTAL_ENCOUNTERS,
    SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) AS TOTAL_READMISSIONS,
    ROUND(
        (SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS READMISSION_RATE_PCT,
    
    -- Financial Exposure
    ROUND(SUM("Billing Amount"), 2) AS TOTAL_BILLED_AMOUNT,
    ROUND(
        SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN "Billing Amount" ELSE 0 END), 
        2
    ) AS TOTAL_REVENUE_AT_RISK

FROM STG_HEALTHCARE_READMISSIONS
GROUP BY "Medical Condition", "Test Results", "Medication";


-- View 2: Operational Bottlenecks & Provider Metrics

CREATE OR REPLACE VIEW VW_PILLAR2_OPERATIONS AS
SELECT 
    "Hospital",
    "Admission Type",
    "Provider_ID",
    
    -- Bed Utilization & Volume Metrics
    COUNT(*) AS TOTAL_ENCOUNTERS,
    ROUND(AVG("Length_of_Stay"), 1) AS AVG_LENGTH_OF_STAY_DAYS,
    
    -- Readmission Metrics
    SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) AS TOTAL_READMISSIONS,
    ROUND(
        (SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS READMISSION_RATE_PCT,
    
    -- Financial Metrics
    ROUND(SUM("Billing Amount"), 2) AS TOTAL_BILLED_AMOUNT,
    ROUND(
        SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN "Billing Amount" ELSE 0 END), 
        2
    ) AS TOTAL_REVENUE_AT_RISK

FROM STG_HEALTHCARE_READMISSIONS
GROUP BY "Hospital", "Admission Type", "Provider_ID";


-- View 3: Revenue Cycle & Payer Analytics

CREATE OR REPLACE VIEW VW_PILLAR3_REVENUE_CYCLE AS
SELECT 
    "Insurance Provider",
    "Admission Type",
    
    -- Encounter Volume
    COUNT(*) AS TOTAL_ENCOUNTERS,
    
    -- Revenue & Risk Breakdown
    ROUND(SUM("Billing Amount"), 2) AS TOTAL_BILLED_AMOUNT,
    ROUND(AVG("Billing Amount"), 2) AS AVG_BILLING_PER_PATIENT,
    SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) AS READMITTED_COUNT,
    ROUND(
        (SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS READMISSION_RATE_PCT,
    ROUND(
        SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN "Billing Amount" ELSE 0 END), 
        2
    ) AS READMISSION_FINANCIAL_RISK

FROM STG_HEALTHCARE_READMISSIONS
GROUP BY "Insurance Provider", "Admission Type";

-- View 4: Patient Demographics & Clinical Risk

CREATE OR REPLACE VIEW VW_PILLAR4_DEMOGRAPHICS AS
SELECT 
    CASE 
        WHEN "Age" < 18 THEN '1. Under 18'
        WHEN "Age" BETWEEN 18 AND 35 THEN '2. 18-35'
        WHEN "Age" BETWEEN 36 AND 50 THEN '3. 36-50'
        WHEN "Age" BETWEEN 51 AND 65 THEN '4. 51-65'
        ELSE '5. 65+ (Senior)'
    END AS AGE_GROUP,
    "Gender",
    "Medical Condition",
    
    -- Volume & Risk Profile
    COUNT(*) AS TOTAL_ENCOUNTERS,
    SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) AS READMITTED_COUNT,
    ROUND(
        (SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS READMISSION_RATE_PCT,
    
    -- Financial Profiling
    ROUND(SUM("Billing Amount"), 2) AS TOTAL_BILLED_AMOUNT,
    ROUND(AVG("Billing Amount"), 2) AS AVG_BILLING_PER_PATIENT,
    ROUND(
        SUM(CASE WHEN "Is_Readmitted_30_Days" = 1 THEN "Billing Amount" ELSE 0 END), 
        2
    ) AS READMISSION_FINANCIAL_RISK

FROM STG_HEALTHCARE_READMISSIONS
GROUP BY 
    CASE 
        WHEN "Age" < 18 THEN '1. Under 18'
        WHEN "Age" BETWEEN 18 AND 35 THEN '2. 18-35'
        WHEN "Age" BETWEEN 36 AND 50 THEN '3. 36-50'
        WHEN "Age" BETWEEN 51 AND 65 THEN '4. 51-65'
        ELSE '5. 65+ (Senior)'
    END,
    "Gender",
    "Medical Condition";

SELECT * FROM VW_CARE_QUALITY LIMIT 5;
SELECT * FROM VW_PILLAR2_OPERATIONS LIMIT 5;
SELECT * FROM VW_PILLAR3_REVENUE_CYCLE LIMIT 5;
SELECT * FROM VW_PILLAR4_DEMOGRAPHICS LIMIT 5;

