# Doing the same steps in Microsoft Access

The Python and SQLite pipeline can also be done by hand in Microsoft Access.

1. **Import** each CSV: External Data > New Data Source > From File > Text File. Name the tables `crm`, `sales`, `support`.
2. **Combine** the sources with a Union query (use the common column names):
```sql
SELECT "CRM" AS source_system, crm_id AS source_id, name AS full_name, email, phone, city, country, created_on AS created_date
FROM crm
UNION ALL
SELECT "SALES", cust_no, customer_name, email_address, mobile, town, country_code, signup_date FROM sales
UNION ALL
SELECT "SUPPORT", ticket_user_id, user_name, contact_email, contact_phone, location, nation, first_seen FROM support;
```
Save it as `qry_all_customers`, then make a table from it (Make-Table query) called `stg_customers`.

3. **Standardise** with an Update query:
```sql
UPDATE stg_customers
SET full_name = StrConv(Trim(full_name), 3),      -- 3 = Proper Case
    email     = LCase(Trim(email)),
    phone     = Right(Replace(Replace(Replace(Replace(Replace(phone, " ", ""), "-", ""), "+", ""), "(", ""), ")", ""), 10),
    country   = IIf(LCase(Trim(country)) IN ("india", "in", "ind"), "India", country);
```

4. **Find duplicates** with the Find Duplicates Query Wizard on `email`, or:
```sql
SELECT email, COUNT(*) AS times_used
FROM stg_customers
WHERE email IS NOT NULL AND email <> ""
GROUP BY email
HAVING COUNT(*) > 1;
```

5. **Build the master table** by keeping one record per email (most trusted source first), then fill missing phone or city from the other records. Access has no window functions, so this is the reason the full pipeline uses SQL and Python.
