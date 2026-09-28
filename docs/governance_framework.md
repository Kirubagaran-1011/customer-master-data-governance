# Customer Data Governance Framework

## 1. Purpose and scope
Customer data lives in three systems (CRM, Sales, Support) with different column names, formats and duplicate records. This framework defines **who owns the data, what "good" looks like, and how records are merged** into one trusted customer master.

**Scope:** customer name, email, phone, city, country, created date.

## 2. Roles and responsibilities
| Role | Who | Responsibilities |
|------|-----|------------------|
| Data Owner | Head of Sales / Customer Success | Accountable for customer data quality; approves rules and survivorship |
| Data Steward | Analyst / Data Quality lead | Reviews DQ reports, resolves match exceptions, maintains the rules |
| Data Custodian | IT / Database team | Runs the pipeline, backups, access control |
| Data Consumers | Marketing, Finance, Support | Use master data, report issues to the steward |

## 3. Data quality rules
| ID | Dimension | Rule | Fix applied |
|----|-----------|------|-------------|
| DQ01 | Completeness | Full name must be present | Route to steward |
| DQ02 | Completeness | Email should be present | Fill from other source records |
| DQ03 | Validity | Email is lower case, no spaces, valid format | `LOWER(TRIM(email))` |
| DQ04 | Completeness | Phone should be present | Fill from other source records |
| DQ05 | Validity | Phone is a 10-digit number | Strip spaces, `+91`, `-`, brackets; keep last 10 digits |
| DQ06 | Consistency | City uses a standard name in proper case | Alias map (Madras to Chennai, Bangalore to Bengaluru, Trichy to Tiruchirappalli) |
| DQ07 | Consistency | Country uses standard name | IN / IND / india to India |
| DQ08 | Uniqueness | One record per real customer | Match and merge (section 5) |

## 4. Standardisation rules
- Names: trim, collapse extra spaces, Proper Case.
- Email: trim and lower case; empty string becomes NULL.
- Phone: digits only, last 10 digits.
- City and country: alias mapping plus proper case.

## 5. Matching rules (MDM)
Two records belong to the same customer if **any** rule fires (rules are chained, so A=B and B=C makes A, B and C one customer):

| Rule | Condition | Confidence |
|------|-----------|-----------|
| M1 | Same standardised email | High |
| M2 | Same 10-digit phone | High (family members can share a phone, so the steward reviews) |
| M3 | Same name and same city | Medium |

## 6. Survivorship rules (golden record)
| Attribute | Rule |
|-----------|------|
| Full name | Longest (most complete) name |
| Email, phone, city, country | First non-null value from the most trusted source: **CRM > Sales > Support**; newest record wins ties |
| Customer since | Earliest created date across sources |

The `source_records` column keeps a link back to every original record for auditing.

## 7. Issue management
1. Pipeline publishes `dq_report.csv` after each run.
2. Steward reviews rules whose pass rate is below the 95% target.
3. Exceptions (missing name, doubtful matches) are corrected at the **source system**.
4. Rule changes are approved by the Data Owner and versioned in Git.

## 8. KPIs
- Duplicate rate before vs after
- Pass rate per rule (target 95% or above)
- Records with complete contact details
- Number of customers present in more than one system

## 9. Known limitations and next steps
- Matching is rule-based. Misspelled names (for example "Arun" and "Arunn") would need fuzzy matching such as Levenshtein or Jaro-Winkler.
- Shared phone numbers can cause false merges; add a review queue for M2-only matches.
- The sample data is synthetic. Tune the rules on real data before relying on them.

## 10. Master table data dictionary
| Column | Description |
|--------|-------------|
| master_id | Unique customer ID (M0001...) |
| full_name | Standardised name |
| email | Standardised email |
| phone | 10-digit phone |
| city / country | Standardised location |
| customer_since | Earliest created date |
| source_record_count | Number of source records merged |
| source_records | List of `SYSTEM:ID` for traceability |
