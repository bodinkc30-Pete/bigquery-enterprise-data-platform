from __future__ import annotations

import hashlib
import json
import os
from datetime import date, datetime
from pathlib import Path

import numpy as np
import pandas as pd

PROJECT = Path(__file__).resolve().parents[2]
_workshop = os.environ.get("P08_PRIVATE_WORKSHOP")
WORKSHOP = Path(_workshop) if _workshop else None

def _workshop_root() -> Path:
    if WORKSHOP is None:
        raise RuntimeError("Set P08_PRIVATE_WORKSHOP to the local private workshop path.")
    return WORKSHOP
OUT = PROJECT / "data" / "portfolio_safe"
REGISTRY = PROJECT / "data_contracts" / "phase_01_source_registry.csv"
SEED = 20260909


def _registry() -> pd.DataFrame:
    df = pd.read_csv(REGISTRY, encoding="utf-8-sig")
    df["canonical_source"] = df["canonical_source"].astype(str).str.lower().eq("true")
    return df


def source_path(role: str) -> Path:
    row = _registry().query("canonical_source and project_role == @role").iloc[0]
    return _workshop_root() / str(row["relative_path"])


def rng() -> np.random.Generator:
    return np.random.default_rng(SEED)


def sample_categories(series: pd.Series, n: int, fallback: str = "UNKNOWN") -> np.ndarray:
    s = series.dropna().astype(str).str.strip()
    s = s[s.ne("")]
    if s.empty:
        return np.array([fallback] * n, dtype=object)
    vc = s.value_counts(normalize=True)
    return rng().choice(vc.index.to_numpy(), size=n, p=vc.to_numpy())


def synth_positive(series: pd.Series, n: int, decimals: int = 2, minimum: float = 0.0) -> np.ndarray:
    s = pd.to_numeric(series, errors="coerce").dropna().astype(float)
    s = s[s >= minimum]
    if s.empty:
        return np.zeros(n)
    zero_rate = float((s <= minimum).mean())
    positive = s[s > minimum]
    if positive.empty:
        return np.full(n, minimum)
    logs = np.log1p(positive)
    mu = float(logs.median())
    q25, q75 = logs.quantile([0.25, 0.75])
    sigma = max(float((q75 - q25) / 1.349), 0.08)
    vals = np.expm1(rng().normal(mu, sigma, n))
    lo = max(float(positive.quantile(0.01)), minimum)
    hi = max(float(positive.quantile(0.99)), lo + 1)
    vals = np.clip(vals, lo, hi)
    if zero_rate > 0:
        vals[rng().random(n) < zero_rate] = minimum
    return np.round(vals, decimals)

def synth_ratio(series: pd.Series, n: int) -> np.ndarray:
    s = pd.to_numeric(series, errors="coerce").dropna().astype(float)
    s = s[(s >= 0) & (s <= 1)]
    if s.empty:
        return np.round(rng().uniform(0.01, 0.2, n), 6)
    vals = rng().normal(float(s.mean()), max(float(s.std(ddof=0)), 0.005), n)
    return np.round(np.clip(vals, 0, 1), 6)


def write_csv(name: str, df: pd.DataFrame) -> dict:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    df.to_csv(path, index=False, encoding="utf-8")
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    return {"dataset": name, "rows": len(df), "columns": len(df.columns), "sha256": digest}


def build_product_sku() -> tuple[pd.DataFrame, list[dict]]:
    raw = pd.read_excel(source_path("PRODUCT_SKU_MASTER"), header=2)
    n = len(raw)
    product_count = int(raw.iloc[:, 1].nunique(dropna=True))
    product_ids = [f"PRD-{i:04d}" for i in range(1, product_count + 1)]
    sku_product = [product_ids[i % product_count] for i in range(n)]
    df = pd.DataFrame({
        "sku_id": [f"SKU-{i:05d}" for i in range(1, n + 1)],
        "product_id": sku_product,
        "product_name": [f"SYN_PRODUCT_{(i % product_count) + 1:03d}" for i in range(n)],
        "status": sample_categories(raw.iloc[:, 3], n, "ACTIVE"),
        "gmv": synth_positive(raw.iloc[:, 4], n),
        "sku_orders": synth_positive(raw.iloc[:, 5], n, decimals=0).astype(int),
        "units_sold": synth_positive(raw.iloc[:, 6], n, decimals=0).astype(int),
    })
    return df, [write_csv("product_sku_synthetic.csv", df)]


def build_creator() -> tuple[pd.DataFrame, list[dict]]:
    raw = pd.read_csv(source_path("CREATOR_MASTER"))
    valid = raw[raw.iloc[:, 1].notna()].copy()
    n = int(valid.iloc[:, 1].nunique())
    followers = synth_positive(valid.iloc[:, 2], n, decimals=0).astype(int)
    engagement = pd.to_numeric(valid.iloc[:, 3], errors="coerce")
    eng = synth_positive(engagement, n, decimals=4)
    budget = synth_positive(valid.iloc[:, 4], n, decimals=2)
    df = pd.DataFrame({
        "creator_token": [f"CRT-{i:05d}" for i in range(1, n + 1)],
        "follower_count": followers,
        "engagement_rate": eng,
        "synthetic_budget": budget,
        "historical_sales_band": rng().choice(["LOW", "MEDIUM", "HIGH"], n, p=[0.45, 0.4, 0.15]),
        "audience_gender_segment": rng().choice(["FEMALE_SKEW", "MALE_SKEW", "BALANCED"], n),
        "audience_age_segment": rng().choice(["18_24", "25_34", "35_44", "45_PLUS"], n),
        "pet_segment": rng().choice(["DOG", "CAT", "MIXED", "UNKNOWN"], n),
    })
    return df, [write_csv("creator_synthetic.csv", df)]


def _generated_order_ids(rows: int, unique_orders: int) -> list[str]:
    base = [f"ORD-{i:07d}" for i in range(1, unique_orders + 1)]
    extra = rows - unique_orders
    ids = base + base[:extra]
    return list(rng().permutation(ids))


def build_orders(product_sku: pd.DataFrame, creators: pd.DataFrame) -> tuple[pd.DataFrame, list[dict]]:
    raw = pd.read_csv(source_path("ORDERS_TRANSACTIONS"))
    n = len(raw)
    unique_orders = int(raw["Order ID"].nunique())
    order_ids = _generated_order_ids(n, unique_orders)
    sku_values = product_sku["sku_id"].tolist()
    sku_ids = []
    seen: dict[str, set[str]] = {}
    for oid in order_ids:
        used = seen.setdefault(oid, set())
        choices = [s for s in sku_values if s not in used] or sku_values
        sku = str(rng().choice(choices))
        used.add(sku)
        sku_ids.append(sku)
    sku_map = product_sku.set_index("sku_id")
    created = pd.to_datetime(raw["Created Time"], dayfirst=True, errors="coerce")
    start = created.min().normalize()
    end = created.max().normalize()
    day_span = max((end - start).days, 1)
    offsets = rng().integers(0, day_span + 1, n)
    hours = rng().integers(0, 24, n)
    created_at = start + pd.to_timedelta(offsets, unit="D") + pd.to_timedelta(hours, unit="h")
    order_amount = synth_positive(raw["Order Amount"], n)
    refund_rate = float((pd.to_numeric(raw["Order Refund Amount"], errors="coerce").fillna(0) > 0).mean())
    refund_flag = rng().random(n) < refund_rate
    refund_amount = np.where(refund_flag, np.round(order_amount * rng().uniform(0.2, 1.0, n), 2), 0.0)
    def lifecycle(v: object) -> str:
        s = str(v).lower()
        if "cancel" in s:
            return "CANCELLED"
        if "refund" in s or "return" in s:
            return "RETURNED"
        if "deliver" in s or "complete" in s:
            return "COMPLETED"
        if "ship" in s:
            return "SHIPPED"
        if "unpaid" in s:
            return "UNPAID"
        if "ready" in s or "process" in s:
            return "PROCESSING"
        return "OTHER"
    mapped_status = raw["Order Status"].map(lifecycle)
    status = sample_categories(mapped_status, n, "OTHER")
    creator_tokens = creators["creator_token"].tolist()
    creator_presence = float(raw["Creator Handle"].notna().mean())
    creator_values = np.where(
        rng().random(n) < creator_presence,
        rng().choice(creator_tokens, n),
        "",
    )
    products = [str(sku_map.loc[s, "product_name"]) for s in sku_ids]
    product_ids = [str(sku_map.loc[s, "product_id"]) for s in sku_ids]
    quantity = np.maximum(synth_positive(raw["Quantity"], n, decimals=0).astype(int), 1)
    unit_price = synth_positive(raw["SKU Unit Original Price"], n)
    gross = np.round(quantity * unit_price, 2)
    discount = np.round(gross * rng().uniform(0.0, 0.25, n), 2)
    subtotal = np.maximum(np.round(gross - discount, 2), 0)
    df = pd.DataFrame({
        "order_id": order_ids,
        "order_status": status,
        "sku_id": sku_ids,
        "product_id": product_ids,
        "product_name": products,
        "quantity": quantity,
        "unit_original_price": unit_price,
        "subtotal_before_discount": gross,
        "total_discount": discount,
        "subtotal_after_discount": subtotal,
        "order_amount": order_amount,
        "refund_amount": refund_amount,
        "created_at": pd.Series(created_at).dt.strftime("%Y-%m-%d %H:%M:%S"),
        "payment_method": rng().choice(["PAYMENT_METHOD_01", "PAYMENT_METHOD_02", "PAYMENT_METHOD_03"], n),
        "fulfillment_type": rng().choice(["PLATFORM", "SELLER"], n, p=[0.8, 0.2]),
        "shipping_provider": rng().choice(["CARRIER_01", "CARRIER_02", "CARRIER_03"], n),
        "order_channel": rng().choice(["SHOP", "LIVE", "VIDEO", "AFFILIATE"], n),
        "creator_token": creator_values,
        "buyer_token": [f"BUY-{i:07d}" for i in rng().integers(1, max(unique_orders, 2), n)],
        "region_code": rng().choice([f"REGION_{i:02d}" for i in range(1, 9)], n),
        "package_token": [f"PKG-{i:07d}" for i in range(1, n + 1)],
    })
    return df, [write_csv("orders_synthetic.csv", df)]


def _daily_metric(raw: pd.DataFrame, idx: int, n: int, ratio: bool = False, integer: bool = False) -> np.ndarray:
    s = raw.iloc[:, idx] if idx < raw.shape[1] else pd.Series(dtype=float)
    if ratio:
        return synth_ratio(s, n)
    values = synth_positive(s, n, decimals=0 if integer else 2)
    return values.astype(int) if integer else values


def build_shop() -> tuple[pd.DataFrame, list[dict]]:
    raw = pd.read_excel(source_path("SHOP_ANALYTICS"), header=8)
    dates = pd.to_datetime(raw.iloc[:, 0], dayfirst=True, errors="coerce")
    raw = raw.loc[dates.notna()].reset_index(drop=True)
    dates = dates[dates.notna()].reset_index(drop=True)
    n = len(raw)
    df = pd.DataFrame({
        "date": dates.dt.strftime("%Y-%m-%d"),
        "gmv": _daily_metric(raw, 1, n),
        "orders": _daily_metric(raw, 2, n, integer=True),
        "customers": _daily_metric(raw, 3, n, integer=True),
        "units_sold": _daily_metric(raw, 4, n, integer=True),
        "refund_amount": _daily_metric(raw, 5, n),
        "sku_orders": _daily_metric(raw, 6, n, integer=True),
        "revenue": _daily_metric(raw, 7, n),
        "page_views": _daily_metric(raw, 8, n, integer=True),
        "visitors": _daily_metric(raw, 9, n, integer=True),
        "conversion_rate": _daily_metric(raw, 10, n, ratio=True),
        "product_impressions": _daily_metric(raw, 11, n, integer=True),
        "unique_product_impressions": _daily_metric(raw, 12, n, integer=True),
        "product_clicks": _daily_metric(raw, 13, n, integer=True),
        "unique_product_clicks": _daily_metric(raw, 14, n, integer=True),
        "aov": _daily_metric(raw, 15, n),
        "live_creator_gmv": _daily_metric(raw, 16, n),
        "video_affiliate_gmv": _daily_metric(raw, 22, n),
    })
    return df, [write_csv("shop_daily_synthetic.csv", df)]


def build_campaign() -> tuple[pd.DataFrame, list[dict]]:
    raw = pd.read_excel(source_path("CAMPAIGN_ANALYTICS"), header=0)
    dates = pd.to_datetime(raw.iloc[:, 0], format="mixed", dayfirst=False, errors="coerce")
    raw = raw.loc[dates.notna()].reset_index(drop=True)
    dates = dates[dates.notna()].reset_index(drop=True)
    n = len(raw)
    spend = _daily_metric(raw, 1, n)
    orders = np.maximum(_daily_metric(raw, 2, n, integer=True), 1)
    revenue = _daily_metric(raw, 4, n)
    df = pd.DataFrame({
        "date": dates.dt.strftime("%Y-%m-%d"),
        "ad_spend": spend,
        "sku_orders": orders,
        "cost_per_order": np.round(spend / orders, 2),
        "gross_revenue": revenue,
        "roi": np.round(np.divide(revenue, np.maximum(spend, 0.01)), 4),
        "currency": "THB",
    })
    return df, [write_csv("campaign_daily_synthetic.csv", df)]


def build_live() -> tuple[pd.DataFrame, list[dict]]:
    raw0 = pd.read_excel(source_path("LIVE_COMMERCE"), header=None)
    headers = raw0.iloc[2].tolist()
    raw = raw0.iloc[3:].copy()
    raw.columns = headers
    dates = pd.to_datetime(raw.iloc[:, 0], format="mixed", dayfirst=False, errors="coerce")
    raw = raw.loc[dates.notna()].reset_index(drop=True)
    dates = dates[dates.notna()].reset_index(drop=True)
    n = len(raw)
    direct_gmv = _daily_metric(raw, 2, n)
    indirect_gmv = _daily_metric(raw, 3, n)
    df = pd.DataFrame({
        "date": dates.dt.strftime("%Y-%m-%d"),
        "live_gmv": np.round(direct_gmv + indirect_gmv, 2),
        "direct_live_gmv": direct_gmv,
        "indirect_live_gmv": indirect_gmv,
        "display_gpm": _daily_metric(raw, 4, n),
        "live_streams": _daily_metric(raw, 5, n, integer=True),
        "gmv_live_streams": _daily_metric(raw, 6, n, integer=True),
        "attributed_units": _daily_metric(raw, 7, n, integer=True),
        "direct_units": _daily_metric(raw, 8, n, integer=True),
        "indirect_units": _daily_metric(raw, 9, n, integer=True),
        "attributed_sku_orders": _daily_metric(raw, 10, n, integer=True),
        "direct_sku_orders": _daily_metric(raw, 11, n, integer=True),
        "indirect_sku_orders": _daily_metric(raw, 12, n, integer=True),
        "customers": _daily_metric(raw, 13, n, integer=True),
        "live_ctr": _daily_metric(raw, 14, n, ratio=True),
        "live_ctor": _daily_metric(raw, 15, n, ratio=True),
        "live_views": _daily_metric(raw, 16, n, integer=True),
        "avg_watch_duration": _daily_metric(raw, 17, n),
    })
    return df, [write_csv("live_daily_synthetic.csv", df)]


def build_product_card() -> tuple[pd.DataFrame, list[dict]]:
    raw0 = pd.read_excel(source_path("PRODUCT_CARD_TRAFFIC"), header=None)
    headers = raw0.iloc[2].tolist()
    raw = raw0.iloc[3:].copy()
    raw.columns = headers
    dates = pd.to_datetime(raw.iloc[:, 0], format="mixed", dayfirst=False, errors="coerce")
    raw = raw.loc[dates.notna()].reset_index(drop=True)
    dates = dates[dates.notna()].reset_index(drop=True)
    n = len(raw)
    views = np.maximum(_daily_metric(raw, 1, n, integer=True), 1)
    clicks = np.minimum(_daily_metric(raw, 2, n, integer=True), views)
    carts = np.minimum(_daily_metric(raw, 8, n, integer=True), clicks)
    orders = np.minimum(_daily_metric(raw, 4, n, integer=True), np.maximum(clicks, 1))
    df = pd.DataFrame({
        "date": dates.dt.strftime("%Y-%m-%d"),
        "views": views,
        "clicks": clicks,
        "customers": _daily_metric(raw, 3, n, integer=True),
        "sku_orders": orders,
        "product_card_gmv": _daily_metric(raw, 5, n),
        "checkout_cart_rate": _daily_metric(raw, 6, n, ratio=True),
        "viewers": _daily_metric(raw, 7, n, integer=True),
        "add_to_cart_clicks": carts,
        "unique_clicks": np.minimum(_daily_metric(raw, 9, n, integer=True), clicks),
        "cart_customers": _daily_metric(raw, 10, n, integer=True),
        "click_to_cart_rate": _daily_metric(raw, 11, n, ratio=True),
        "view_to_click_rate": np.round(clicks / views, 6),
        "view_to_checkout_rate": _daily_metric(raw, 13, n, ratio=True),
        "click_to_checkout_rate": _daily_metric(raw, 14, n, ratio=True),
        "content_gmv": _daily_metric(raw, 15, n),
    })
    return df, [write_csv("product_card_daily_synthetic.csv", df)]


def build_creator_payment(creators: pd.DataFrame) -> tuple[pd.DataFrame, list[dict]]:
    raw0 = pd.read_excel(source_path("CREATOR_LIVE_PAYMENT"), sheet_name="สรุปรอบจ่าย", header=None)
    headers = raw0.iloc[18].tolist()
    raw = raw0.iloc[19:].copy()
    raw.columns = headers
    raw = raw[raw.iloc[:, 0].notna()].reset_index(drop=True)
    n = len(raw)
    amount = synth_positive(raw.iloc[:, 2], n)
    creator_tokens = creators["creator_token"].tolist()
    def normalize_reliable_date(value: object) -> pd.Timestamp:
        if isinstance(value, (pd.Timestamp, datetime, date)):
            year = value.year - 543 if value.year > 2400 else value.year
            try:
                return pd.Timestamp(year=year, month=value.month, day=value.day)
            except (ValueError, OverflowError):
                return pd.NaT
        return pd.NaT

    post_dates = raw.iloc[:, 3].map(normalize_reliable_date)
    min_date = post_dates.min() if post_dates.notna().any() else pd.Timestamp("2026-01-01")
    max_date = post_dates.max() if post_dates.notna().any() else pd.Timestamp("2026-08-31")
    span = max((max_date.normalize() - min_date.normalize()).days, 1)
    synthetic_dates = min_date.normalize() + pd.to_timedelta(rng().integers(0, span + 1, n), unit="D")
    df = pd.DataFrame({
        "payment_id": [f"PAY-{i:07d}" for i in range(1, n + 1)],
        "creator_token": rng().choice(creator_tokens, n),
        "payment_amount": amount,
        "post_date": pd.Series(synthetic_dates).dt.strftime("%Y-%m-%d"),
        "settlement_account_token": [f"SYNBANK-{i:06d}" for i in rng().integers(1, 1000000, n)],
        "payment_cycle": rng().choice(["DAY_16", "MONTH_END"], n, p=[0.5, 0.5]),
        "payment_status": rng().choice(["PAID", "PENDING", "REVIEW"], n, p=[0.78, 0.17, 0.05]),
        "payment_type": rng().choice(["CREATOR_CONTENT", "LIVE_HOST", "OTHER_SERVICE"], n, p=[0.65, 0.25, 0.10]),
        "source_reference_token": [f"SRCREF-{i:07d}" for i in range(1, n + 1)],
    })
    return df, [write_csv("creator_payment_synthetic.csv", df)]


def build_all() -> dict:
    OUT.mkdir(parents=True, exist_ok=True)
    manifest: list[dict] = []
    product_sku, m = build_product_sku(); manifest += m
    creators, m = build_creator(); manifest += m
    _, m = build_orders(product_sku, creators); manifest += m
    _, m = build_shop(); manifest += m
    _, m = build_campaign(); manifest += m
    _, m = build_live(); manifest += m
    _, m = build_product_card(); manifest += m
    _, m = build_creator_payment(creators); manifest += m
    manifest = sorted(manifest, key=lambda x: x["dataset"])
    payload = {
        "phase": 3,
        "generation_mode": "DETERMINISTIC_SYNTHETIC_FROM_LOCAL_AGGREGATE_PATTERNS",
        "seed": SEED,
        "raw_identity_preserved": "NO",
        "cloud_upload_performed": "NO",
        "datasets": manifest,
    }
    (OUT / "phase_03_manifest.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    return payload


if __name__ == "__main__":
    result = build_all()
    print(json.dumps({
        "status": "GENERATED",
        "datasets": len(result["datasets"]),
        "rows": {x["dataset"]: x["rows"] for x in result["datasets"]},
        "output": str(OUT),
    }, ensure_ascii=False))
