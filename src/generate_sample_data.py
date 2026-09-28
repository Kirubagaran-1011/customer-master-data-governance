"""
Generates SYNTHETIC customer data for three source systems (CRM, Sales, Support)
with realistic problems: duplicates, mixed casing, extra spaces, different phone
formats, city aliases and missing values.

Replace the files in data/raw/ with your own data to use the pipeline on real records.
"""
import random
from pathlib import Path
import pandas as pd

random.seed(42)
RAW = Path(__file__).resolve().parent.parent / "data" / "raw"
RAW.mkdir(parents=True, exist_ok=True)

FIRST = ["Arun", "Bala", "Charan", "Divya", "Elango", "Farida", "Gowri", "Hari",
         "Indhu", "Jeeva", "Kavin", "Lakshmi", "Manoj", "Nisha", "Om"]
LAST = ["Kumar", "Raj", "Selvam", "Priya", "Murugan", "Devi", "Nathan", "Sundar",
        "Ramesh", "Karthik", "Anand", "Mohan", "Vel", "Prakash", "Sekar"]
DOMAINS = ["gmail.com", "yahoo.com", "outlook.com"]
CITY_VARIANTS = {
    "Chennai": ["Chennai", "chennai", "CHENNAI ", "Madras"],
    "Tiruchirappalli": ["Tiruchirappalli", "Trichy", "trichy", "TRICHY "],
    "Madurai": ["Madurai", "madurai", " MADURAI"],
    "Coimbatore": ["Coimbatore", "coimbatore", "COIMBATORE"],
    "Bengaluru": ["Bengaluru", "Bangalore", "bangalore "],
}
COUNTRY_VARIANTS = ["India", "india", "IN", "INDIA ", "IND"]

# ---- true (hidden) customers ----
combos = [(f, l) for f in FIRST for l in LAST]
random.shuffle(combos)
customers = []
for i in range(60):
    f, l = combos[i]
    customers.append({
        "first": f, "last": l,
        "email": f"{f}.{l}@{random.choice(DOMAINS)}".lower(),
        "alt_email": f"{f}{l}{random.randint(1, 99)}@{random.choice(DOMAINS)}".lower(),
        "phone": "9" + "".join(random.choices("0123456789", k=9)),
        "city": random.choice(list(CITY_VARIANTS)),
        "created": f"{random.randint(2021, 2025)}-{random.randint(1, 12):02d}-{random.randint(1, 28):02d}",
    })


def dirty_name(c):
    name = f"{c['first']} {c['last']}"
    return random.choice([name, name.lower(), name.upper(), f"  {name} ", name.replace(" ", "  ")])


def dirty_phone(p):
    return random.choice([p, f"{p[:5]} {p[5:]}", f"+91 {p[:5]} {p[5:]}", f"+91-{p}", f"({p[:3]}) {p[3:6]}-{p[6:]}", f"0{p}"])


def dirty_email(e, miss=0.08):
    if random.random() < miss:
        return ""
    return random.choice([e, e.upper(), f" {e} ", e.capitalize()])


def record(c, use_alt=False):
    return {
        "name": dirty_name(c),
        "email": dirty_email(c["alt_email"] if use_alt else c["email"]),
        "phone": dirty_phone(c["phone"]) if random.random() > 0.07 else "",
        "city": random.choice(CITY_VARIANTS[c["city"]]),
        "country": random.choice(COUNTRY_VARIANTS) if random.random() > 0.05 else "",
        "date": c["created"],
    }


crm, sales, support = [], [], []
for i, c in enumerate(customers):
    r = record(c)
    crm.append({"crm_id": f"C{1000 + len(crm)}", "name": r["name"], "email": r["email"], "phone": r["phone"],
                "city": r["city"], "country": r["country"], "created_on": r["date"]})
    if random.random() < 0.6:
        r = record(c, use_alt=random.random() < 0.15)
        sales.append({"cust_no": f"S{5000 + len(sales)}", "customer_name": r["name"], "email_address": r["email"],
                      "mobile": r["phone"], "town": r["city"], "country_code": r["country"], "signup_date": r["date"]})
    if random.random() < 0.4:
        r = record(c)
        support.append({"ticket_user_id": f"U{9000 + len(support)}", "user_name": r["name"], "contact_email": r["email"],
                        "contact_phone": r["phone"], "location": r["city"], "nation": r["country"], "first_seen": r["date"]})

# duplicates inside CRM itself (same person entered twice)
for c in random.sample(customers, 6):
    r = record(c)
    crm.append({"crm_id": f"C{1000 + len(crm)}", "name": r["name"], "email": r["email"], "phone": r["phone"],
                "city": r["city"], "country": r["country"], "created_on": r["date"]})

pd.DataFrame(crm).to_csv(RAW / "crm_customers.csv", index=False)
pd.DataFrame(sales).to_csv(RAW / "sales_customers.csv", index=False)
pd.DataFrame(support).to_csv(RAW / "support_customers.csv", index=False)
print(f"CRM: {len(crm)}  Sales: {len(sales)}  Support: {len(support)}  (60 real people underneath)")
