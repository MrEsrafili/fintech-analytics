# Gold Trading Analytics — SQL & Cohort Analysis Portfolio

> A marketing analytics project built on anonymised data from a digital gold trading platform.  
> Demonstrates SQL querying, cohort retention modelling, funnel analysis, and user segmentation.

---

## Project Overview

This project analyses user behaviour on a fintech app where customers buy and sell physical gold by weight. The analysis answers four core marketing questions:

1. **Do users come back?** — Weekly cohort retention analysis
2. **Where do we lose users?** — Registration-to-trade funnel by acquisition channel
3. **Where does revenue come from?** — Monthly trends and channel-level revenue breakdown
4. **Who are our users?** — RFM-style behavioural segmentation

All analysis is written in plain SQL against a local SQLite database, making the project fully reproducible with no external dependencies.

---

## Dataset Schema

Two tables loaded into `data/processed/analytics.db`:

### `orders`
| Column | Type | Description |
|---|---|---|
| `id` | TEXT | Unique order identifier |
| `user` | TEXT | User identifier (FK → users) |
| `createdat` | DATETIME | Order timestamp |
| `totalvalue` | REAL | Total transaction value |
| `requestprice` | REAL | Gold price per gram at order time |
| `requestvolume` | REAL | Gold weight in grams |
| `fee` | REAL | Fee rate applied to the order |
| `comefrom` | TEXT | Acquisition channel / traffic source |

### `users`
| Column | Type | Description |
|---|---|---|
| `id` | TEXT | Unique user identifier |
| `createdat` | DATETIME | Registration date |
| `source` | TEXT | Registration channel |
| `gender` | TEXT | User gender |
| `verificationstatus` | INT | KYC verification level (0 = none) |
| `ordercount` | INT | Lifetime orders placed |
| `totaldeposit` | REAL | Lifetime deposit amount |
| `totalwithdraw` | REAL | Lifetime withdrawal amount |
| `totalwithdrawgoldenvalue` | REAL | Lifetime gold withdrawal value |

---

## Project Structure

```
gold-analytics-portfolio/
│
├── data/
│   ├── raw/
│   │   ├── orders/          ← Place your orders CSV files here
│   │   └── users/           ← Place your users CSV files here
│   └── processed/
│       └── analytics.db     ← Generated SQLite database
│
├── scripts/
│   ├── 01_append_orders.py  ← Merges all orders CSVs, saves to DB
│   ├── 02_append_users.py   ← Merges all users CSVs, saves to DB
│   └── 03_run_analysis.py   ← Runs all SQL files, prints results
│
├── sql/
│   ├── cohort_retention.sql   ← Weekly cohort retention grid
│   ├── funnel_analysis.sql    ← Registration → activation → repeat funnel
│   ├── revenue_analysis.sql   ← Monthly trend + channel breakdown
│   └── user_behavior.sql      ← RFM segmentation
│
├── insights/
│   └── business_insights.md      ← Plain-English findings and actions
│
├── requirements.txt
└── README.md
```

---

## How to Run

### 1. Install dependencies
```bash
pip install -r requirements.txt
```

### 2. Add your data files
```
data/raw/orders/   ← drop all orders CSV files here
data/raw/users/    ← drop all users CSV files here
```

### 3. Build the database
```bash
python scripts/01_append_orders.py
python scripts/02_append_users.py
```

### 4. Run the analysis
```bash
python scripts/03_run_analysis.py
```

Or open the SQL files directly in any SQLite client (e.g. DB Browser for SQLite, DBeaver, or VS Code with the SQLite extension).

---

## Key Analyses

### Cohort Retention
Assigns users to the week of their first order and measures the percentage who return each subsequent week. Identifies whether product-market fit exists and where in the user lifecycle churn accelerates.

```sql
-- Sample output shape
cohort_week | week_offset | cohort_size | retained_users | retention_rate
2025-01     |      0      |     142     |      142       |    1.0000
2025-01     |      1      |     142     |       49       |    0.3451
2025-01     |      4      |     142     |       31       |    0.2183
```

### Funnel Analysis
Measures conversion at each stage — registration, first order, repeat order, verification — broken down by acquisition channel. Surfaces which channels produce the highest-quality users.

```sql
-- Sample output shape
channel   | registered | activated | activation_rate | repeat_buyers | repeat_rate
organic   |    3,200   |   1,120   |     0.3500      |      448      |   0.4000
paid_ads  |    1,800   |     504   |     0.2800      |      151      |   0.3000
referral  |      650   |     293   |     0.4500      |      132      |   0.4500
```

### Revenue Analysis
Monthly gross revenue and fee revenue trend, plus a channel-level breakdown of revenue per unique trader — a key signal for campaign ROI.

### User Behavior (RFM Segments)
Each user is tagged by recency (days since last order) and frequency (total orders). The resulting matrix guides retention campaigns: Power Traders get VIP treatment, At-Risk users get win-back offers.

---

## Dashboard Ideas

The following views would complement this SQL analysis in Looker Studio / Tableau / Metabase:

| Dashboard | Key Charts |
|---|---|
| **Cohort Grid** | Heatmap: cohort week (rows) × week offset (cols), coloured by retention rate |
| **Funnel** | Horizontal bar chart showing drop-off at each stage, per channel |
| **Revenue** | Line chart: monthly gross revenue + fee revenue; bar: revenue by channel |
| **User Segments** | Bubble chart: frequency vs. recency, sized by avg order value |

---

## Skills Demonstrated

- **SQL** — CTEs, window functions (NTILE, OVER), aggregations, date arithmetic
- **Cohort analysis** — weekly retention modelling from raw transaction data
- **Funnel analysis** — multi-stage conversion with channel attribution
- **User segmentation** — RFM framework applied to trading behaviour
- **Marketing thinking** — every query tied to a concrete business question and recommended action
- **Python** — pandas data wrangling, SQLite integration, multi-file append logic

---

## About

Built as a portfolio project to showcase SQL and marketing analytics skills.  
Data is anonymised. No personally identifiable information is included.
