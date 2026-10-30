from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[2]
SQL_DIR = ROOT / "sql"


def build_database() -> duckdb.DuckDBPyConnection:
    """Build and populate an in-memory database from the versioned SQL scripts."""
    connection = duckdb.connect(":memory:")
    for script in ("01_schema.sql", "02_seed.sql", "03_analytics.sql"):
        connection.execute((SQL_DIR / script).read_text(encoding="utf-8"))
    return connection


def run_quality_checks(connection: duckdb.DuckDBPyConnection) -> list[tuple]:
    """Return any data-quality violations; an empty list means all checks passed."""
    results = []
    for statement in (SQL_DIR / "04_data_quality.sql").read_text(encoding="utf-8").split(";"):
        if statement.strip():
            results.extend(connection.execute(statement).fetchall())
    return results


def main() -> int:
    connection = build_database()
    print("SQL Advanced Analytics — synthetic e-commerce case study")
    print("\nMonthly revenue:")
    print(connection.execute("SELECT * FROM monthly_revenue ORDER BY month").df().to_string(index=False))
    print("\nTop 5 products:")
    print(connection.execute(
        "SELECT product_name, category, units_sold, revenue FROM product_performance "
        "ORDER BY revenue DESC LIMIT 5"
    ).df().to_string(index=False))
    print("\nCustomer segments:")
    print(connection.execute(
        "SELECT customer_segment, COUNT(*) AS customers FROM customer_rfm "
        "GROUP BY 1 ORDER BY 2 DESC"
    ).df().to_string(index=False))
    violations = run_quality_checks(connection)
    print(f"\nData-quality checks: {'PASS' if not violations else 'FAIL'}")
    if violations:
        for violation in violations:
            print(violation)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
