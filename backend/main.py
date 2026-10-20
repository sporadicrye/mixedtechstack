"""
main.py — FastAPI application entry point.
All routes defined here. Follows DRY: shared logic lives in ai_service.py
and database.py. Routes are thin wrappers around DB queries and AI service.
"""

import logging
from typing import Optional
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db, engine, Base
from ai_service import ask_claude

logging.basicConfig(level=logging.INFO)

# Create all tables on startup if they don't exist
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Ryan Carlo's POC E-Commerce Sales Dashboard API",
    description="AI-augmented sales analytics with Claude RAG integration",
    version="1.0.0")

# CORS — allow Vite dev server and production frontend
#    allow_origins=["http://localhost:5173", "http://localhost:3000"],
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)


# ── Reusable query helper ─────────────────────────────────────────────────────
def run_query(db: Session, sql: str, params: dict = {}) -> list[dict]:
    """
    Execute raw SQL and return list of dicts.
    Reused by all GET routes — DRY principle.
    """
    result = db.execute(text(sql), params)
    return [dict(row._mapping) for row in result]


# ── Health check ──────────────────────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "ok", "service": "mypoc_ecommerce"}


# ── Orders ────────────────────────────────────────────────────────────────────
@app.get("/getOrder/order_id/{order_id}")
def get_order(order_id: str, db: Session = Depends(get_db)):
    """
    GET /getOrder/order_id/7   — single order with full detail
    GET /getOrder/order_id/all — all orders with full detail
    Joins orders + order_details + customers + employees + shippers
    """
    base_sql = """
        SELECT
            o.order_id,
            o.order_date,
            o.required_date,
            o.shipped_date,
            o.freight,
            o.ship_name,
            o.ship_country,
            c.company_name      AS customer_name,
            c.country           AS customer_country,
            e.first_name        AS employee_first,
            e.last_name         AS employee_last,
            sh.company_name     AS shipper_name,
            od.product_id,
            p.product_name,
            od.unit_price,
            od.quantity,
            od.discount,
            ROUND(od.unit_price * od.quantity * (1 - od.discount), 2) AS line_total
        FROM orders o
        JOIN customers   c  ON o.customer_id = c.customer_id
        JOIN employees   e  ON o.employee_id = e.employee_id
        JOIN shippers    sh ON o.ship_via    = sh.shipper_id
        JOIN order_details od ON o.order_id  = od.order_id
        JOIN products    p  ON od.product_id = p.product_id
    """
    if order_id == "all":
        rows = run_query(db, base_sql + " ORDER BY o.order_id")
    else:
        if not order_id.isdigit():
            raise HTTPException(status_code=400, detail="order_id must be numeric or 'all'")
        rows = run_query(db, base_sql + " WHERE o.order_id = :oid ORDER BY od.product_id",
                         {"oid": int(order_id)})
        if not rows:
            raise HTTPException(status_code=404, detail=f"Order {order_id} not found")
    return rows


# ── Employees ─────────────────────────────────────────────────────────────────
@app.get("/getEmployee/employee_id/{employee_id}")
def get_employee(employee_id: str, db: Session = Depends(get_db)):
    """
    GET /getEmployee/employee_id/7   — single employee with order stats
    GET /getEmployee/employee_id/all — all employees with order stats
    """
    base_sql = """
        SELECT
            e.employee_id,
            e.first_name,
            e.last_name,
            e.title,
            e.hire_date,
            e.country,
            COUNT(DISTINCT o.order_id)                                        AS total_orders,
            ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount)), 2)    AS total_sales
        FROM employees e
        LEFT JOIN orders       o  ON e.employee_id = o.employee_id
        LEFT JOIN order_details od ON o.order_id   = od.order_id
    """
    group_sql = " GROUP BY e.employee_id, e.first_name, e.last_name, e.title, e.hire_date, e.country"

    if employee_id == "all":
        rows = run_query(db, base_sql + group_sql + " ORDER BY total_sales DESC")
    else:
        if not employee_id.isdigit():
            raise HTTPException(status_code=400, detail="employee_id must be numeric or 'all'")
        rows = run_query(db, base_sql + " WHERE e.employee_id = :eid" + group_sql,
                         {"eid": int(employee_id)})
        if not rows:
            raise HTTPException(status_code=404, detail=f"Employee {employee_id} not found")
    return rows


# ── Customers ─────────────────────────────────────────────────────────────────
@app.get("/getCustomer/customer_id/{customer_id}")
def get_customer(customer_id: str, db: Session = Depends(get_db)):
    """
    GET /getCustomer/customer_id/ALFKI — single customer with spend summary
    GET /getCustomer/customer_id/all   — all customers with spend summary
    """
    base_sql = """
        SELECT
            c.customer_id,
            c.company_name,
            c.contact_name,
            c.country,
            c.city,
            c.phone,
            COUNT(DISTINCT o.order_id)                                        AS total_orders,
            ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount)), 2)    AS total_spent,
            MIN(o.order_date)                                                  AS first_order,
            MAX(o.order_date)                                                  AS last_order
        FROM customers c
        LEFT JOIN orders       o  ON c.customer_id = o.customer_id
        LEFT JOIN order_details od ON o.order_id   = od.order_id
    """
    group_sql = """
        GROUP BY c.customer_id, c.company_name, c.contact_name,
                 c.country, c.city, c.phone
    """

    if customer_id == "all":
        rows = run_query(db, base_sql + group_sql + " ORDER BY total_spent DESC")
    else:
        rows = run_query(db, base_sql + " WHERE c.customer_id = :cid" + group_sql,
                         {"cid": customer_id.upper()})
        if not rows:
            raise HTTPException(status_code=404, detail=f"Customer {customer_id} not found")
    return rows


# ── Shippers ──────────────────────────────────────────────────────────────────
@app.get("/getShip/ship_via/{ship_via}")
def get_ship(ship_via: str, db: Session = Depends(get_db)):
    """
    GET /getShip/ship_via/3   — all orders shipped via shipper_id=3
    GET /getShip/ship_via/all — all orders with shipper info
    """
    base_sql = """
        SELECT
            sh.shipper_id,
            sh.company_name     AS shipper_name,
            sh.phone            AS shipper_phone,
            o.order_id,
            o.order_date,
            o.shipped_date,
            o.freight,
            o.ship_country,
            c.company_name      AS customer_name,
            ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount)), 2) AS order_value
        FROM shippers sh
        JOIN orders       o  ON sh.shipper_id = o.ship_via
        JOIN customers    c  ON o.customer_id = c.customer_id
        JOIN order_details od ON o.order_id   = od.order_id
    """
    group_sql = """
        GROUP BY sh.shipper_id, sh.company_name, sh.phone,
                 o.order_id, o.order_date, o.shipped_date,
                 o.freight, o.ship_country, c.company_name
    """

    if ship_via == "all":
        rows = run_query(db, base_sql + group_sql + " ORDER BY sh.shipper_id, o.order_id")
    else:
        if not ship_via.isdigit():
            raise HTTPException(status_code=400, detail="ship_via must be numeric or 'all'")
        rows = run_query(db, base_sql + " WHERE sh.shipper_id = :sid" + group_sql +
                         " ORDER BY o.order_id", {"sid": int(ship_via)})
        if not rows:
            raise HTTPException(status_code=404, detail=f"Shipper {ship_via} not found")
    return rows


# ── Dashboard Summary ─────────────────────────────────────────────────────────
@app.get("/getDashboard/summary")
def get_dashboard_summary(db: Session = Depends(get_db)):
    """
    GET /getDashboard/summary
    Returns KPI cards data for frontend dashboard.
    All aggregates done in SQL — no AI needed for deterministic numbers.
    """
    summary = run_query(db, """
        SELECT
            COUNT(DISTINCT o.order_id)                                         AS total_orders,
            COUNT(DISTINCT o.customer_id)                                      AS total_customers,
            ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount)), 2)     AS total_revenue,
            ROUND(AVG(od.unit_price * od.quantity * (1 - od.discount)), 2)     AS avg_order_value,
            COUNT(DISTINCT od.product_id)                                      AS products_sold
        FROM orders o
        JOIN order_details od ON o.order_id = od.order_id
    """)

    top_products = run_query(db, """
        SELECT
            p.product_name,
            cat.category_name,
            SUM(od.quantity)                                                   AS units_sold,
            ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount)), 2)     AS revenue
        FROM order_details od
        JOIN products   p   ON od.product_id = p.product_id
        JOIN categories cat ON p.category_id = cat.category_id
        GROUP BY p.product_name, cat.category_name
        ORDER BY revenue DESC
        LIMIT 10
    """)

    monthly_revenue = run_query(db, """
        SELECT
            DATE_FORMAT(o.order_date, '%Y-%m')                                 AS month,
            ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount)), 2)     AS revenue,
            COUNT(DISTINCT o.order_id)                                         AS orders
        FROM orders o
        JOIN order_details od ON o.order_id = od.order_id
        GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
        ORDER BY month ASC
    """)

    return {
        "summary":         summary[0] if summary else {},
        "top_products":    top_products,
        "monthly_revenue": monthly_revenue
    }


# ── AI Insight ────────────────────────────────────────────────────────────────
@app.post("/ai/ask")
def ai_ask(payload: dict, db: Session = Depends(get_db)):
    """
    POST /ai/ask
    Body: {"question": "Which customer spent the most in Q3?"}
    Returns Claude's/Deepseek's insight with cache metadata.
    RAG flow: cache check → SQL context → Claude → cache save
    RAG flow: cache check → SQL context → DeepSeek Ollama → cache save
    """
    question = payload.get("question", "").strip()
    if not question:
        raise HTTPException(status_code=400, detail="question field is required")
    if len(question) > 500:
        raise HTTPException(status_code=400, detail="question too long, max 500 chars")
    return ask_claude(question, db)


@app.get("/ai/insights")
def get_all_insights(db: Session = Depends(get_db)):
    """
    GET /ai/insights
    Returns all cached AI insights for display in dashboard archive table.
    """
    return run_query(db, """
        SELECT id, question_text, insight_type, insight_text,
               tokens_used, created_at, expires_at
        FROM ai_insights
        ORDER BY created_at DESC
        LIMIT 100
    """)
