from analytics_project.runner import build_database, run_quality_checks


def test_seeded_dataset_has_expected_grain():
    con = build_database()
    assert con.execute("SELECT COUNT(*) FROM customers").fetchone()[0] == 120
    assert con.execute("SELECT COUNT(*) FROM products").fetchone()[0] == 20
    assert con.execute("SELECT COUNT(*) FROM orders").fetchone()[0] == 600
    assert con.execute("SELECT COUNT(*) FROM payments").fetchone()[0] == 600


def test_completed_order_revenue_is_positive():
    con = build_database()
    count, minimum = con.execute(
        "SELECT COUNT(*), MIN(order_revenue) FROM order_revenue"
    ).fetchone()
    assert count > 0
    assert minimum > 0


def test_monthly_revenue_window_metrics():
    con = build_database()
    rows = con.execute(
        "SELECT month, revenue, cumulative_revenue FROM monthly_revenue ORDER BY month"
    ).fetchall()
    assert len(rows) >= 12
    assert all(row[1] > 0 for row in rows)
    assert all(rows[i][2] >= rows[i - 1][2] for i in range(1, len(rows)))
    assert rows[-1][2] == sum(row[1] for row in rows)


def test_product_ranking_is_valid():
    con = build_database()
    assert con.execute(
        "SELECT COUNT(*) FROM product_performance WHERE category_revenue_rank < 1"
    ).fetchone()[0] == 0
    assert con.execute("SELECT COUNT(DISTINCT product_id) FROM product_performance").fetchone()[0] == 20


def test_rfm_covers_all_customers():
    con = build_database()
    assert con.execute("SELECT COUNT(*) FROM customer_rfm").fetchone()[0] == 120
    segments = {row[0] for row in con.execute("SELECT DISTINCT customer_segment FROM customer_rfm").fetchall()}
    assert segments <= {"Champions", "Loyal", "At risk", "Developing"}
    assert segments


def test_cohort_retention_is_bounded():
    con = build_database()
    rows = con.execute("SELECT retention_pct FROM cohort_retention").fetchall()
    assert rows
    assert all(0 < row[0] <= 100 for row in rows)


def test_all_data_quality_checks_pass():
    con = build_database()
    assert run_quality_checks(con) == []
