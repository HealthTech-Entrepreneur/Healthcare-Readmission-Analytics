# Healthcare Readmission Analytics Pipeline & Executive Dashboards

An end-to-end data engineering and business intelligence solution that transforms raw patient encounter data into protected, structured SQL views and interactive executive dashboards.

---

## 1. Project Overview & Executive Summary

Hospital readmissions within 30 days of discharge are a critical focus area for modern healthcare systems. Unplanned readmissions stretch facility capacity, increase operating costs, and can indicate gaps in outpatient care quality. Furthermore, regulatory frameworks penalize hospitals financially when readmission rates exceed target thresholds.

This project implements a complete, multi-stage analytics pipeline connecting **Python**, **Snowflake**, and **Power BI**:
* **Data Privacy:** Raw patient encounter records are processed in Python using cryptographic hashing to meet **HIPAA Safe Harbor** de-identification standards.
* **Data Warehousing:** De-identified records are staged in **Snowflake**, where four modular SQL views encapsulate complex analytical queries.
* **Executive Dashboards:** **Power BI** connects directly to Snowflake to render four interactive dashboard pages covering clinical quality, operational bottlenecks, revenue risk, and patient demographics.

---

## 2. Problem Statement & Business Value

### The Challenge
Healthcare leaders often struggle to extract actionable operational intelligence from raw Electronic Health Record (EHR) logs. Raw data is siloed, contains protected health information (PHI), and lacks unified metric definitions across clinical and financial departments.

### The Solution
Using a synthetic dataset of **55,000+ patient records** sourced from Kaggle, this project demonstrates how to securely process sensitive health data and deliver real-time, interactive decision-making tools for hospital executives, clinical directors, and financial managers.

---

## 3. Architecture & Tech Stack

```
[ Kaggle Synthetic Dataset (55,000+ Records) ]
                       │
                       ▼
[ 1. Python Environment (pandas, hashlib) ]
  └── Clean data & apply HIPAA Safe Harbor hashing (SHA-256)
                       │
                       ▼
[ 2. Snowflake Cloud Data Warehouse (HEALTHCARE_DB) ]
  ├── Staging Table: STG_HEALTHCARE_READMISSIONS
  └── 4 Modular SQL Views (CLINICAL_ANALYTICS)
        ├── VW_CARE_QUALITY
        ├── VW_PILLAR2_OPERATIONS
        ├── VW_PILLAR3_REVENUE_CYCLE
        └── VW_PILLAR4_DEMOGRAPHICS
                       │
                       ▼
[ 3. Power BI Desktop Executive Dashboards ]
  ├── Connect via Native Snowflake Server Connector
  ├── Power Query Validation & Custom DAX Modeling
  └── 4 Interactive Report Pages
```

### Tech Stack Summary
* **Language & Libraries:** Python (`pandas`, `hashlib`)
* **Privacy Standard:** HIPAA Safe Harbor De-identification Method (SHA-256)
* **Data Warehouse:** Snowflake Cloud DW (`HEALTHCARE_DB`, `CLINICAL_ANALYTICS` schema, `COMPUTE_WH`)
* **SQL Dialect:** Snowflake SQL (DDL, DML, View Materialization, Conditional Aggregations)
* **Business Intelligence:** Power BI Desktop (Power Query Engine, DAX Measures, Canvas Layouts)

---

## 4. Step-by-Step Technical Process

### Step 1: Data Acquisition & HIPAA Compliance (Python)
Raw healthcare records contain sensitive Patient Health Information (PHI). Before loading data into cloud environments, privacy protection is legally mandatory under HIPAA.
* Processed raw records in Python using `pandas` and `hashlib`.
* Applied the **Safe Harbor Method** by stripping direct personal identifiers.
* Generated deterministic, non-reversible SHA-256 cryptographic hashes for patient identifiers to allow longitudinal visit tracking without exposing real identity.

```python
import hashlib

def deidentify_patient_id(patient_id: str, salt: str = "HealthcareSalt123") -> str:
    """Hashes direct identifiers using SHA-256 for HIPAA Safe Harbor compliance."""
    salted_input = f"{patient_id}{salt}".encode('utf-8')
    return hashlib.sha256(salted_input).hexdigest()
```

### Step 2: Staging & SQL Data Modeling (Snowflake)
Data was ingested into Snowflake to establish a performant data warehouse structure:
* **Database & Schema Creation:** Created `HEALTHCARE_DB` and schema `CLINICAL_ANALYTICS`.
* **Data Staging:** Loaded 55,000+ rows into the staging table `STG_HEALTHCARE_READMISSIONS`.
* **Modular View Architecture:** Created four pre-aggregated SQL views to optimize query performance and isolate business logic from the reporting layer:
  1. `VW_CARE_QUALITY`: Encapsulates encounter counts, readmission tallies, and revenue risk grouped by medical condition, test result, and medication.
  2. `VW_PILLAR2_OPERATIONS`: Summarizes average length of stay (LOS), provider volume, and admission pathway dynamics by hospital facility.
  3. `VW_PILLAR3_REVENUE_CYCLE`: Aggregates total billed revenue, average per-patient billing, and financial risk across insurance carriers.
  4. `VW_PILLAR4_DEMOGRAPHICS`: Categorizes patient encounter volumes and readmission counts across age brackets and gender splits.

#### Example SQL View Definition (Care Quality)
```sql
CREATE OR REPLACE VIEW HEALTHCARE_DB.CLINICAL_ANALYTICS.VW_CARE_QUALITY AS
SELECT 
    MEDICAL_CONDITION,
    TEST_RESULTS,
    MEDICATION,
    COUNT(*) AS TOTAL_ENCOUNTERS,
    SUM(CASE WHEN READMITTED = 'Yes' THEN 1 ELSE 0 END) AS TOTAL_READMISSIONS,
    SUM(BILLING_AMOUNT) AS TOTAL_REVENUE_AT_RISK
FROM HEALTHCARE_DB.CLINICAL_ANALYTICS.STG_HEALTHCARE_READMISSIONS
GROUP BY MEDICAL_CONDITION, TEST_RESULTS, MEDICATION;
```

### Step 3: Business Intelligence (Power BI)
Power BI Desktop was connected directly to the Snowflake host identifier (`xslentv-uv80810.snowflakecomputing.com`).
* **Power Query Import:** Validated schema data types and column structures for each imported view.
* **DAX Modeling:** Implemented custom DAX measures to prevent invalid mathematical summation of pre-aggregated percentages:

```dax
// Dynamically calculates accurate readmission percentage across filtered visual contexts
Care Quality Readmission Rate % = 
DIVIDE(
    SUM(VW_CARE_QUALITY[TOTAL_READMISSIONS]), 
    SUM(VW_CARE_QUALITY[TOTAL_ENCOUNTERS]), 
    0
)

// Measures average length of stay across operational groups
Avg Length of Stay = 
AVERAGE(VW_PILLAR2_OPERATIONS[AVG_LENGTH_OF_STAY_DAYS])
```

---

## 5. Executive Dashboard Breakdown

The final Power BI solution features four dedicated pages structured around a consistent executive layout (Top KPI Banner $\rightarrow$ Global Slicers $\rightarrow$ Comparative Visuals $\rightarrow$ Granular Tables):

### Page 1: Care Quality & 30-Day Readmission Risk
* **Focus:** Clinical risk factors driving 30-day readmissions.
* **KPI Banner:** Total Encounters (56K), Total Revenue at Risk ($161.92M), Overall Readmission Rate (11.51%).
* **Visuals:** Horizontal bar chart comparing readmission volume across medical conditions; granular risk matrix mapping medications and test outcomes.

### Page 2: Provider & Operational Bottlenecks
* **Focus:** Hospital bed turnover, length of stay, and admission pathways.
* **KPI Banner:** Avg Length of Stay (15.50 days), Readmission Rate % (11.51%), Total Readmissions (6K).
* **Visuals:** Filtered horizontal bar chart benchmarking hospital stay durations (Top 20 providers); donut chart breaking down revenue at risk by admission type (Emergency, Elective, Urgent).

### Page 3: Revenue Cycle & Payer Analytics
* **Focus:** Financial exposure across insurance carriers.
* **KPI Banner:** Total Billed Amount ($1.42B), Average Billing per Patient ($25.54K), Readmission Financial Risk ($161.92M).
* **Visuals:** Revenue comparison bar chart across primary payers (Cigna, Medicare, Blue Cross, UnitedHealthcare, Aetna); financial risk pie chart.

### Page 4: Patient Demographics & Clinical Risk
* **Focus:** Demographic profiling across age brackets and gender splits.
* **KPI Banner:** Total Encounters (56K), Total Readmissions (6K), Demographic Readmission Rate % (11.51%).
* **Visuals:** Clustered column chart analyzing male vs. female encounters across age brackets (Senior 65+, 18–35, 51–65, 36–50, Under 18); Treemap mapping readmission density by medical condition.

---

## 6. Key Business Findings

1. **Baseline Readmission Uniformity:** Readmission rates hold consistently near **11.51%** across all insurance providers and demographic groups, indicating that readmission risk is driven by broad systemic processes rather than specific demographic segments.
2. **Substantial Financial Risk:** Out of **$1.42 Billion** in total gross billing, **$161.92 Million** is tied to patients readmitted within 30 days, representing significant exposure to regulatory penalty programs (e.g., HRRP).
3. **Operational Bottleneck:** The average length of stay across facilities is **15.50 days**, establishing a clear operational target for discharge optimization and post-discharge follow-up programs.

---

## 7. How to Run & Replicate This Project

### Prerequisites
* Python 3.8 or higher (`pandas`, `hashlib`)
* Snowflake Account with `ACCOUNTADMIN` or database creation privileges
* Power BI Desktop

### Execution Steps
1. **Data Processing:** Run the Python script to de-identify and hash direct patient identifiers from the raw Kaggle dataset.
2. **Data Warehousing:** Open a Snowflake Worksheet, execute the DDL/DML scripts to build `HEALTHCARE_DB` and `CLINICAL_ANALYTICS`, load the staging data, and deploy the four view queries.
3. **Power BI Dashboard:** Open Power BI Desktop, connect to Snowflake using your server hostname, load the four views, verify the DAX measures, and publish the report.