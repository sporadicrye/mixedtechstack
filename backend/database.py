"""
database.py — MariaDB connection using env vars.
Connects to MariaDB running inside same container via localhost.
"""

import os
from datetime import date, datetime
from sqlalchemy import (
    create_engine, Column, Integer, String, Text,
    Float, Date, DateTime, ForeignKey, DECIMAL, SmallInteger
)
from sqlalchemy.orm import declarative_base, relationship, sessionmaker
from dotenv import load_dotenv

load_dotenv()

# MariaDB runs inside same container — connect via localhost

DB_USER = os.getenv("DB_USER",     "")
DB_PASS = os.getenv("DB_PASSWORD", "")
DB_HOST = os.getenv("DB_HOST",     "")
DB_PORT = os.getenv("DB_PORT",     "")
DB_NAME = os.getenv("DB_NAME",     "")

DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

engine = create_engine(
    DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_recycle=3600,
    pool_pre_ping=True,
    echo=False
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    """Yields DB session per request, always closes on exit."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ── ORM Models (unchanged from previous — all preserved) ─────────────────────

class Category(Base):
    __tablename__ = "categories"
    category_id   = Column(Integer, primary_key=True, autoincrement=True)
    category_name = Column(String(100), nullable=False)
    description   = Column(Text)
    products      = relationship("Product", back_populates="category")


class Supplier(Base):
    __tablename__ = "suppliers"
    supplier_id  = Column(Integer, primary_key=True, autoincrement=True)
    company_name = Column(String(100), nullable=False)
    contact_name = Column(String(100))
    country      = Column(String(50))
    products     = relationship("Product", back_populates="supplier")


class Shipper(Base):
    __tablename__ = "shippers"
    shipper_id   = Column(Integer, primary_key=True, autoincrement=True)
    company_name = Column(String(100), nullable=False)
    phone        = Column(String(30))
    orders       = relationship("Order", back_populates="shipper")


class Employee(Base):
    __tablename__ = "employees"
    employee_id = Column(Integer, primary_key=True, autoincrement=True)
    last_name   = Column(String(50), nullable=False)
    first_name  = Column(String(50), nullable=False)
    title       = Column(String(100))
    hire_date   = Column(Date)
    country     = Column(String(50))
    orders      = relationship("Order", back_populates="employee")


class Customer(Base):
    __tablename__ = "customers"
    customer_id  = Column(String(10), primary_key=True)
    company_name = Column(String(100), nullable=False)
    contact_name = Column(String(100))
    country      = Column(String(50))
    city         = Column(String(50))
    phone        = Column(String(30))
    orders       = relationship("Order", back_populates="customer")


class Product(Base):
    __tablename__ = "products"
    product_id        = Column(Integer, primary_key=True, autoincrement=True)
    product_name      = Column(String(150), nullable=False)
    supplier_id       = Column(Integer, ForeignKey("suppliers.supplier_id"))
    category_id       = Column(Integer, ForeignKey("categories.category_id"))
    quantity_per_unit = Column(String(50))
    unit_price        = Column(DECIMAL(10, 2), default=0)
    units_in_stock    = Column(Integer, default=0)
    units_on_order    = Column(Integer, default=0)
    reorder_level     = Column(Integer, default=0)
    discontinued      = Column(SmallInteger, default=0)
    supplier          = relationship("Supplier",  back_populates="products")
    category          = relationship("Category",  back_populates="products")
    order_details     = relationship("OrderDetail", back_populates="product")


class Order(Base):
    __tablename__ = "orders"
    order_id      = Column(Integer, primary_key=True, autoincrement=True)
    customer_id   = Column(String(10), ForeignKey("customers.customer_id"))
    employee_id   = Column(Integer,    ForeignKey("employees.employee_id"))
    order_date    = Column(Date)
    required_date = Column(Date)
    shipped_date  = Column(Date)
    ship_via      = Column(Integer,    ForeignKey("shippers.shipper_id"))
    freight       = Column(DECIMAL(10, 2), default=0)
    ship_name     = Column(String(100))
    ship_country  = Column(String(50))
    customer      = relationship("Customer",    back_populates="orders")
    employee      = relationship("Employee",    back_populates="orders")
    shipper       = relationship("Shipper",     back_populates="orders")
    order_details = relationship("OrderDetail", back_populates="order")


class OrderDetail(Base):
    __tablename__ = "order_details"
    order_id   = Column(Integer, ForeignKey("orders.order_id"),    primary_key=True)
    product_id = Column(Integer, ForeignKey("products.product_id"), primary_key=True)
    unit_price = Column(DECIMAL(10, 2), nullable=False)
    quantity   = Column(Integer, nullable=False)
    discount   = Column(Float, default=0)
    order      = relationship("Order",   back_populates="order_details")
    product    = relationship("Product", back_populates="order_details")


class AiInsight(Base):
    __tablename__ = "ai_insights"
    id            = Column(Integer,     primary_key=True, autoincrement=True)
    question_hash = Column(String(64),  nullable=False, index=True)
    question_text = Column(Text,        nullable=False)
    insight_type  = Column(String(50),  nullable=False)
    insight_text  = Column(Text,        nullable=False)
    sql_context   = Column(Text)
    tokens_used   = Column(Integer,     default=0)
    created_at    = Column(DateTime,    default=datetime.utcnow)
    expires_at    = Column(DateTime,    nullable=True)
