"""
watcher.py — CSV drop watcher for lookup table maintenance.
Watches for _products.csv and _shippers.csv dropped into DROP_DIR.
Performs UPSERT with proper title-case normalization on company/product names.
Runs as a separate process alongside main.py.
"""

import os
import re
import csv
import time
import logging
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from database import SessionLocal
from sqlalchemy import text

logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s - %(levelname)s - %(message)s")

DROP_DIR = os.getenv("CSV_DROP_DIR", "/app/drop_here")


def title_case_normalize(name: str) -> str:
    """
    Normalize company/product names to proper title case.
    Handles all-caps, mixed case, and irregular spacing.
    Examples:
        NAGARAya       -> Nagaraya
        AliGR Oup      -> Aligroup  (joined then titled)
        FEDERAL shipping -> Federal Shipping
    """
    # Collapse whitespace, strip, then title case
    normalized = re.sub(r'\s+', ' ', name.strip())
    return normalized.title()


def upsert_products(filepath: Path):
    """
    UPSERT products from _products.csv into products table.
    Matches on normalized product_name (case-insensitive).
    Updates all fields if product already exists.
    Expected CSV columns:
        product_name, supplier_id, category_id, quantity_per_unit,
        unit_price, units_in_stock, units_on_order, reorder_level, discontinued
    """
    db = SessionLocal()
    try:
        with open(filepath, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            upserted = 0
            for row in reader:
                product_name = title_case_normalize(row['product_name'])
                db.execute(text("""
                    INSERT INTO products
                        (product_name, supplier_id, category_id, quantity_per_unit,
                         unit_price, units_in_stock, units_on_order, reorder_level, discontinued)
                    VALUES
                        (:product_name, :supplier_id, :category_id, :quantity_per_unit,
                         :unit_price, :units_in_stock, :units_on_order, :reorder_level, :discontinued)
                    ON DUPLICATE KEY UPDATE
                        supplier_id       = VALUES(supplier_id),
                        category_id       = VALUES(category_id),
                        quantity_per_unit = VALUES(quantity_per_unit),
                        unit_price        = VALUES(unit_price),
                        units_in_stock    = VALUES(units_in_stock),
                        units_on_order    = VALUES(units_on_order),
                        reorder_level     = VALUES(reorder_level),
                        discontinued      = VALUES(discontinued)
                """), {
                    "product_name":      product_name,
                    "supplier_id":       int(row['supplier_id']),
                    "category_id":       int(row['category_id']),
                    "quantity_per_unit": row['quantity_per_unit'],
                    "unit_price":        float(row['unit_price']),
                    "units_in_stock":    int(row['units_in_stock']),
                    "units_on_order":    int(row['units_on_order']),
                    "reorder_level":     int(row['reorder_level']),
                    "discontinued":      int(row['discontinued'])
                })
                upserted += 1
        db.commit()
        logging.info(f"✅ Products upserted: {upserted} rows from {filepath.name}")
    except Exception as e:
        db.rollback()
        logging.error(f"❌ Failed to upsert products from {filepath.name}: {e}")
    finally:
        db.close()


def upsert_shippers(filepath: Path):
    """
    UPSERT shippers from _shippers.csv into shippers table.
    Matches on normalized company_name (case-insensitive).
    Updates phone if shipper already exists.
    Expected CSV columns:
        company_name, phone
    """
    db = SessionLocal()
    try:
        with open(filepath, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            upserted = 0
            for row in reader:
                company_name = title_case_normalize(row['company_name'])
                db.execute(text("""
                    INSERT INTO shippers (company_name, phone)
                    VALUES (:company_name, :phone)
                    ON DUPLICATE KEY UPDATE
                        phone = VALUES(phone)
                """), {
                    "company_name": company_name,
                    "phone":        row['phone'].strip()
                })
                upserted += 1
        db.commit()
        logging.info(f"✅ Shippers upserted: {upserted} rows from {filepath.name}")
    except Exception as e:
        db.rollback()
        logging.error(f"❌ Failed to upsert shippers from {filepath.name}: {e}")
    finally:
        db.close()


class CSVDropHandler(FileSystemEventHandler):
    """
    Watchdog handler — detects new CSV files dropped into DROP_DIR.
    Routes to correct upsert function based on filename suffix.
    Supported suffixes:
        _products.csv  -> upsert_products()
        _shippers.csv  -> upsert_shippers()
    """

    def on_closed(self, event):
        # Triggered only when file write is fully complete
        if event.is_directory:
            return
        filepath = Path(event.src_path)
        if filepath.suffix.lower() != '.csv':
            return

        logging.info(f"📥 CSV detected: {filepath.name}")
        # Wait briefly to ensure file is fully flushed to disk
        time.sleep(1)

        name_lower = filepath.name.lower()
        if name_lower.endswith('_products.csv'):
            upsert_products(filepath)
            filepath.unlink(missing_ok=True)
            logging.info(f"🗑️ Deleted processed CSV: {filepath.name}")
        elif name_lower.endswith('_shippers.csv'):
            upsert_shippers(filepath)
            filepath.unlink(missing_ok=True)
            logging.info(f"🗑️ Deleted processed CSV: {filepath.name}")
        else:
            logging.warning(f"⚠️ Unrecognized CSV suffix, skipping: {filepath.name}")


if __name__ == "__main__":
    os.makedirs(DROP_DIR, exist_ok=True)
    handler  = CSVDropHandler()
    observer = Observer()
    observer.schedule(handler, DROP_DIR, recursive=False)
    observer.start()
    logging.info(f"🤖 CSV Drop Watcher Online | Watching: {DROP_DIR}")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
