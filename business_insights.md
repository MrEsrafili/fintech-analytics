# Business Insights

> **Platform context:** This analysis covers a digital gold trading app where users register, deposit funds, and buy/sell gold by weight. Key metrics are trading volume (grams), order value, fee revenue, and user retention across weekly cohorts.

---

## 1. Cohort Retention Analysis (`01_cohort_retention.sql`)

### What the query measures
Each user is assigned to the calendar week of their **first ever order**. We then track how many of those users placed *any* additional order 1, 2, 3… weeks later. The output is a classic retention grid — rows are cohort weeks, columns are week offsets.

### How to read it
- **`week_offset = 0`** — the cohort's founding week. Retention rate is always 100%.
- **`week_offset = 1`** — what share traded again the very next week.
- **`week_offset = 4`** — one-month retention.

### Business decisions it informs
| Finding | Action |
|---|---|
| Retention drops sharply after week 1 | Launch a Day-7 re-engagement push (email / push notification) |
| Certain cohort weeks retain better | Dig into what marketing or product change happened that week |
| High `net_fee_revenue` on retained users | Prioritise retention spend — retained traders are the profit engine |
| Low `total_weight_grams` in later weeks | Retained users may be placing micro-orders; introduce upsell prompts |

### Typical pattern to look for
> A healthy gold trading app sees Week-1 retention of **25–40%** and Week-4 retention of **15–25%**. If your numbers are lower, the product or onboarding experience needs attention before you increase acquisition spend.

---

## 2. Funnel Conversion Analysis (`02_funnel_analysis.sql`)

### What the query measures
The classic **Registration → First Order → Repeat Order** funnel, broken out by acquisition channel. It also captures verification rate and average time-to-first-order.

### Funnel stages
```
Registered users
    └── Activated (≥ 1 order)         ← activation_rate
            └── Repeat buyers (≥ 2)   ← repeat_rate
                    └── Verified       ← verification_rate
```

### Business decisions it informs
| Finding | Action |
|---|---|
| Low activation rate (< 30%) | Improve onboarding — users register but never trade |
| Long `avg_days_to_first_order` | Add urgency mechanic (welcome bonus, first-trade reward) |
| High activation but low repeat rate | Post-first-order experience is broken; add second-trade nudge |
| Channel A converts at 2× Channel B | Shift budget towards Channel A; review Channel B targeting |
| Low verification rate | KYC flow has friction; simplify or add incentive to verify |

### Key metric to highlight in interviews
> **Activation rate** is the single most actionable metric here. A 10-point improvement in activation rate — moving from 30% to 40% — means 33% more paying users from the same acquisition budget.

---

## 3. Revenue Analysis (`03_revenue_analysis.sql`)

### What the query measures
Three views of revenue:
- **Monthly trend** — are we growing? Is there seasonality?
- **By channel** — which traffic sources produce the highest-value traders?
- **User value tiers** — does the 80/20 rule hold? (Top 20% of users = 80% of revenue)

### Key metrics explained
| Column | Meaning |
|---|---|
| `gross_revenue` | Total trading value (all order amounts) |
| `net_fee_revenue` | Platform's actual earnings (order value × fee rate) |
| `avg_order_value` | Typical trade size — proxy for user wealth/intent |
| `revenue_per_user` | Channel efficiency metric — revenue divided by unique traders |

### Business decisions it informs
| Finding | Action |
|---|---|
| Revenue spikes in certain months | Align campaign timing with high-intent periods |
| One channel dominates revenue | Protect it — ensure budget allocation reflects its value |
| Top 20% drive 80%+ of revenue | Build a VIP / high-value user programme |
| `avg_order_value` declining over time | Product issue or market shift; investigate with cohort lens |

---

## 4. User Behavior Analysis (`04_user_behavior.sql`)

### What the query measures
An RFM-style segmentation (Recency, Frequency, Monetary) that labels each user as a Power Trader, Regular Trader, Occasional Trader, or One-Time Buyer — and overlays a recency tag (Active / Warm / At Risk / Churned).

### Segment definitions
| Segment | Orders | Business meaning |
|---|---|---|
| Power Trader | ≥ 10 | Core revenue base; protect with loyalty perks |
| Regular Trader | 4–9 | Growth candidates; nudge towards Power status |
| Occasional Trader | 2–3 | Engagement campaigns needed |
| One-Time Buyer | 1 | Failed retention; re-activation opportunity |

| Recency tag | Last order | Business meaning |
|---|---|---|
| Active (≤ 30d) | Within a month | Healthy; focus on upsell |
| Warm (31–90d) | 1–3 months ago | Send win-back before they cool further |
| At Risk (91–180d) | 3–6 months ago | Urgent re-engagement |
| Churned (> 180d) | 6+ months ago | Low ROI to chase; focus on lookalike acquisition |

### Business decisions it informs
| Finding | Action |
|---|---|
| Many One-Time Buyers in "At Risk" segment | Run a targeted re-activation campaign with a fee discount |
| Power Traders trending from Active → Warm | Assign account management or premium support |
| Verified users show much higher frequency | Make verification easier or incentivise it earlier |
| Female users under-represented vs. market | Explore creative or channel adjustments for female-skewed audiences |

---

## Summary: The analyst's north-star view

```
Acquire better users  →  Activate them faster  →  Retain them longer  →  Grow their value
      (Funnel)               (Funnel: days_to_first_order)   (Cohort)          (RFM)
```

The four SQL analyses map directly to this framework. In an interview, this is the narrative thread: every query exists to answer a specific business question, not just to demonstrate SQL skill.
