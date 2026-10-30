# SQL Advanced Analytics

A reproducible business-intelligence case study built with SQL, DuckDB and Python. It models an e-commerce business and answers commercial questions with joins, CTEs, window functions, cohort analysis, RFM segmentation and data-quality checks.

## What this project demonstrates

- Relational modelling with primary/foreign keys and realistic transactional grain.
- SQL transformations using multi-table joins, CTEs, conditional aggregation and window functions.
- Revenue, average order value, monthly growth, product rankings, customer lifetime value and cohort retention.
- Explicit data-quality checks and automated regression tests.
- A one-command local execution path and CI validation.

## Requirements

- Python 3.11+
- Dependencies in `requirements.txt`

DuckDB is used as an embedded analytical database, so no database server or Docker is required. SQL is written for DuckDB; syntax may need small changes for PostgreSQL or other engines.

## Run

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
python -m analytics_project
pytest
```

The runner creates an in-memory database, applies schema, loads deterministic synthetic data and executes the analytics and quality-check scripts. It prints key result sets. No external API, credentials or real customer data are used.

## Project structure

- `sql/01_schema.sql`: tables, constraints and types.
- `sql/02_seed.sql`: deterministic synthetic data.
- `sql/03_analytics.sql`: analytical views and business queries.
- `sql/04_data_quality.sql`: exception-oriented quality checks.
- `src/analytics_project/runner.py`: reproducible execution.
- `tests/`: functional and analytical assertions.

## Business questions answered

1. How does monthly revenue and month-over-month growth evolve?
2. Which products and categories generate the most revenue?
3. Who are the highest-value customers, and how are they segmented using RFM?
4. How do customer cohorts retain and generate repeat purchases?
5. Are there orphaned records, invalid amounts, duplicate business keys or inconsistent payment totals?

## Data model

`customers → orders → order_items ← products`, with one payment record per order. The seed script creates 120 customers, 20 products, 600 orders, line items and payments using fixed formulas and dates.

## Quality and limitations

The data is synthetic and designed for repeatable portfolio demonstration, not forecasting or production financial reporting. Revenue is calculated from order-item quantities and unit prices; payment reconciliation is checked separately. Tests validate expected record counts, referential integrity, non-negative amounts, analytical outputs and quality-check results.

## CI

GitHub Actions tests Python 3.11, 3.12 and 3.13. The workflow installs dependencies, runs pytest and checks the command-line entry point.

## License

MIT. See [LICENSE](LICENSE).
