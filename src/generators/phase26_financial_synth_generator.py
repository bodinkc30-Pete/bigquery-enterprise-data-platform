from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "data" / "financial_ops_synth"
SEED = 20260914
CURRENCIES = np.array(["THB", "USD", "SGD"], dtype=object)
START = pd.Timestamp("2026-01-01 00:00:00")
TX_DAYS = 60


def rng() -> np.random.Generator:
    return np.random.default_rng(SEED)


def write_csv(name: str, df: pd.DataFrame) -> dict:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{name}.csv"
    df.to_csv(path, index=False, encoding="utf-8", lineterminator="\n")
    return {
        "table": name,
        "rows": int(len(df)),
        "columns": int(len(df.columns)),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def build_customers(g: np.random.Generator) -> pd.DataFrame:
    n = 300
    created = START - pd.to_timedelta(g.integers(30, 365, n), unit="D")
    return pd.DataFrame({
        "customer_id": [f"CUS-{i:06d}" for i in range(1, n + 1)],
        "customer_token": [f"SYN-CUSTOMER-{i:06d}" for i in range(1, n + 1)],
        "risk_tier": g.choice(["LOW", "MEDIUM", "HIGH"], n, p=[0.65, 0.28, 0.07]),
        "segment": g.choice(["RETAIL", "SME_OWNER", "PREMIUM"], n, p=[0.75, 0.15, 0.10]),
        "country_code": g.choice(["TH", "SG", "US"], n, p=[0.72, 0.18, 0.10]),
        "created_at": pd.Series(created).dt.strftime("%Y-%m-%d %H:%M:%S"),
    })


def build_accounts(g: np.random.Generator, customers: pd.DataFrame) -> pd.DataFrame:
    n = 450
    customer_ids = customers["customer_id"].to_numpy()
    opened = START - pd.to_timedelta(g.integers(7, 300, n), unit="D")
    currencies = np.resize(CURRENCIES, n)
    g.shuffle(currencies)
    return pd.DataFrame({
        "account_id": [f"ACC-{i:06d}" for i in range(1, n + 1)],
        "customer_id": g.choice(customer_ids, n, replace=True),
        "account_token": [f"SYN-ACCOUNT-{i:06d}" for i in range(1, n + 1)],
        "currency": currencies,
        "account_status": g.choice(["ACTIVE", "REVIEW", "SUSPENDED"], n, p=[0.94, 0.04, 0.02]),
        "opened_at": pd.Series(opened).dt.strftime("%Y-%m-%d %H:%M:%S"),
    })


def build_merchants(g: np.random.Generator) -> pd.DataFrame:
    n = 80
    currencies = np.resize(CURRENCIES, n)
    g.shuffle(currencies)
    return pd.DataFrame({
        "merchant_id": [f"MER-{i:05d}" for i in range(1, n + 1)],
        "merchant_token": [f"SYN-MERCHANT-{i:05d}" for i in range(1, n + 1)],
        "merchant_category": g.choice(["RETAIL", "FOOD", "TRAVEL", "DIGITAL", "SERVICES"], n),
        "country_code": g.choice(["TH", "SG", "US"], n, p=[0.70, 0.20, 0.10]),
        "settlement_currency": currencies,
        "merchant_status": g.choice(["ACTIVE", "REVIEW"], n, p=[0.96, 0.04]),
    })


def build_transactions(g: np.random.Generator, accounts: pd.DataFrame, merchants: pd.DataFrame) -> pd.DataFrame:
    n = 5000
    account_idx = g.integers(0, len(accounts), n)
    merchant_idx = g.integers(0, len(merchants), n)
    amounts = np.clip(np.rint(np.exp(g.normal(8.5, 1.0, n))), 100, 500000).astype("int64")
    initiated = START + pd.to_timedelta(g.integers(0, TX_DAYS * 86400, n), unit="s")
    status = g.choice(["COMPLETED", "DECLINED", "PENDING", "CANCELLED"], n, p=[0.78, 0.08, 0.08, 0.06])
    terminal_delay = pd.to_timedelta(g.integers(1, 600, n), unit="s")
    completed = pd.Series(initiated + terminal_delay)
    completed.loc[status == "PENDING"] = pd.NaT
    return pd.DataFrame({
        "transaction_id": [f"TXN-{i:08d}" for i in range(1, n + 1)],
        "account_id": accounts.iloc[account_idx]["account_id"].to_numpy(),
        "merchant_id": merchants.iloc[merchant_idx]["merchant_id"].to_numpy(),
        "idempotency_key": [f"IDEMP-{i:08d}" for i in range(1, n + 1)],
        "currency": accounts.iloc[account_idx]["currency"].to_numpy(),
        "transaction_amount_minor": amounts,
        "status": status,
        "initiated_at": pd.Series(initiated).dt.strftime("%Y-%m-%d %H:%M:%S"),
        "completed_at": completed.dt.strftime("%Y-%m-%d %H:%M:%S").fillna(""),
    })


def build_payment_events(transactions: pd.DataFrame) -> pd.DataFrame:
    lifecycle = {
        "COMPLETED": ["INITIATED", "AUTHORIZED", "CAPTURED"],
        "DECLINED": ["INITIATED", "DECLINED"],
        "PENDING": ["INITIATED", "AUTHORIZED"],
        "CANCELLED": ["INITIATED", "AUTHORIZED", "CANCELLED"],
    }
    rows = []
    event_id = 1
    for r in transactions.itertuples(index=False):
        base = pd.Timestamp(r.initiated_at)
        for seq, event_type in enumerate(lifecycle[r.status], start=1):
            rows.append({
                "payment_event_id": f"PEV-{event_id:09d}",
                "transaction_id": r.transaction_id,
                "event_sequence": seq,
                "event_type": event_type,
                "status": "RECORDED",
                "currency": r.currency,
                "event_amount_minor": int(r.transaction_amount_minor),
                "event_time": (base + pd.Timedelta(seconds=(seq - 1) * 45)).strftime("%Y-%m-%d %H:%M:%S"),
            })
            event_id += 1
    return pd.DataFrame(rows)


def build_refunds_reversals(g: np.random.Generator, transactions: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    completed = transactions.loc[transactions["status"].eq("COMPLETED")].copy()
    refund_idx = g.choice(completed.index.to_numpy(), size=300, replace=False)
    remaining = completed.loc[~completed.index.isin(refund_idx)]
    reversal_idx = g.choice(remaining.index.to_numpy(), size=120, replace=False)
    refund_tx = completed.loc[refund_idx].reset_index(drop=True)
    reversal_tx = completed.loc[reversal_idx].reset_index(drop=True)
    refund_amounts = np.maximum(
        1,
        np.minimum(
            refund_tx["transaction_amount_minor"].to_numpy(),
            np.rint(refund_tx["transaction_amount_minor"].to_numpy() * g.uniform(0.15, 1.0, len(refund_tx))).astype("int64"),
        ),
    )
    refund_requested = pd.to_datetime(refund_tx["initiated_at"]) + pd.to_timedelta(g.integers(1, 8, len(refund_tx)), unit="D")
    refunds = pd.DataFrame({
        "refund_id": [f"RFD-{i:07d}" for i in range(1, len(refund_tx) + 1)],
        "transaction_id": refund_tx["transaction_id"],
        "currency": refund_tx["currency"],
        "refund_amount_minor": refund_amounts,
        "status": "COMPLETED",
        "requested_at": refund_requested.dt.strftime("%Y-%m-%d %H:%M:%S"),
        "completed_at": (refund_requested + pd.Timedelta(minutes=10)).dt.strftime("%Y-%m-%d %H:%M:%S"),
    })
    reversal_created = pd.to_datetime(reversal_tx["initiated_at"]) + pd.to_timedelta(g.integers(1, 5, len(reversal_tx)), unit="D")
    reversals = pd.DataFrame({
        "reversal_id": [f"REV-{i:07d}" for i in range(1, len(reversal_tx) + 1)],
        "transaction_id": reversal_tx["transaction_id"],
        "currency": reversal_tx["currency"],
        "reversal_amount_minor": reversal_tx["transaction_amount_minor"].astype("int64"),
        "reason_code": g.choice(["POST_AUTH_REVERSAL", "DUPLICATE_RECOVERY", "NETWORK_RECOVERY"], len(reversal_tx)),
        "status": "COMPLETED",
        "created_at": reversal_created.dt.strftime("%Y-%m-%d %H:%M:%S"),
    })
    return refunds, reversals


def build_settlements(transactions: pd.DataFrame, refunds: pd.DataFrame, reversals: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    tx = transactions.loc[transactions["status"].eq("COMPLETED")].copy().reset_index(drop=True)
    refund_map = refunds.set_index("transaction_id")["refund_amount_minor"].to_dict()
    reversal_map = reversals.set_index("transaction_id")["reversal_amount_minor"].to_dict()
    tx["settlement_date"] = (pd.to_datetime(tx["initiated_at"]).dt.normalize() + pd.Timedelta(days=2)).dt.strftime("%Y-%m-%d")
    tx["refund_amount_minor"] = tx["transaction_id"].map(refund_map).fillna(0).astype("int64")
    tx["reversal_amount_minor"] = tx["transaction_id"].map(reversal_map).fillna(0).astype("int64")
    tx["net_amount_minor"] = (
        tx["transaction_amount_minor"] - tx["refund_amount_minor"] - tx["reversal_amount_minor"]
    ).astype("int64")
    keys = sorted(tx[["settlement_date", "currency"]].drop_duplicates().itertuples(index=False, name=None))
    batch_lookup = {key: f"STB-{i:06d}" for i, key in enumerate(keys, start=1)}
    tx["settlement_batch_id"] = [batch_lookup[(d, c)] for d, c in zip(tx["settlement_date"], tx["currency"])]
    items = pd.DataFrame({
        "settlement_item_id": [f"STI-{i:09d}" for i in range(1, len(tx) + 1)],
        "settlement_batch_id": tx["settlement_batch_id"],
        "transaction_id": tx["transaction_id"],
        "settlement_date": tx["settlement_date"],
        "currency": tx["currency"],
        "gross_amount_minor": tx["transaction_amount_minor"].astype("int64"),
        "refund_amount_minor": tx["refund_amount_minor"],
        "reversal_amount_minor": tx["reversal_amount_minor"],
        "net_amount_minor": tx["net_amount_minor"],
        "status": "SETTLED",
    })
    batch_agg = items.groupby(["settlement_batch_id", "settlement_date", "currency"], as_index=False).agg(
        item_count=("settlement_item_id", "count"),
        gross_amount_minor=("gross_amount_minor", "sum"),
        refund_amount_minor=("refund_amount_minor", "sum"),
        reversal_amount_minor=("reversal_amount_minor", "sum"),
        net_amount_minor=("net_amount_minor", "sum"),
    )
    batch_agg["batch_status"] = "SETTLED"
    batches = batch_agg[[
        "settlement_batch_id", "settlement_date", "currency", "batch_status", "item_count",
        "gross_amount_minor", "refund_amount_minor", "reversal_amount_minor", "net_amount_minor"
    ]].sort_values(["settlement_date", "currency"]).reset_index(drop=True)
    return batches, items.sort_values("settlement_item_id").reset_index(drop=True)


def _group_metrics(df: pd.DataFrame, date_col: str, count_name: str, amount_col: str, amount_name: str) -> pd.DataFrame:
    if df.empty:
        return pd.DataFrame(columns=["business_date", "currency", count_name, amount_name])
    x = df.copy()
    x["business_date"] = pd.to_datetime(x[date_col]).dt.strftime("%Y-%m-%d")
    return x.groupby(["business_date", "currency"], as_index=False).agg(
        **{count_name: (amount_col, "size"), amount_name: (amount_col, "sum")}
    )


def build_daily_controls(
    transactions: pd.DataFrame,
    refunds: pd.DataFrame,
    reversals: pd.DataFrame,
    settlement_items: pd.DataFrame,
) -> pd.DataFrame:
    completed = transactions.loc[transactions["status"].eq("COMPLETED")].copy()
    tx = _group_metrics(completed, "initiated_at", "transaction_count", "transaction_amount_minor", "transaction_amount_minor")
    rf = _group_metrics(refunds, "requested_at", "refund_count", "refund_amount_minor", "refund_amount_minor")
    rv = _group_metrics(reversals, "created_at", "reversal_count", "reversal_amount_minor", "reversal_amount_minor")
    st = _group_metrics(settlement_items, "settlement_date", "settlement_item_count", "net_amount_minor", "settlement_net_amount_minor")
    frames = [tx, rf, rv, st]
    result = frames[0]
    for frame in frames[1:]:
        result = result.merge(frame, on=["business_date", "currency"], how="outer")
    metric_cols = [
        "transaction_count", "transaction_amount_minor", "refund_count", "refund_amount_minor",
        "reversal_count", "reversal_amount_minor", "settlement_item_count", "settlement_net_amount_minor"
    ]
    for col in metric_cols:
        result[col] = result[col].fillna(0).astype("int64")
    result["control_status"] = "MATCHED"
    return result.sort_values(["business_date", "currency"]).reset_index(drop=True)


def build_all() -> dict:
    g = rng()
    customers = build_customers(g)
    accounts = build_accounts(g, customers)
    merchants = build_merchants(g)
    transactions = build_transactions(g, accounts, merchants)
    payment_events = build_payment_events(transactions)
    refunds, reversals = build_refunds_reversals(g, transactions)
    settlement_batches, settlement_items = build_settlements(transactions, refunds, reversals)
    daily_control_totals = build_daily_controls(transactions, refunds, reversals, settlement_items)
    tables = {
        "customers": customers,
        "accounts": accounts,
        "merchants": merchants,
        "transactions": transactions,
        "payment_events": payment_events,
        "refunds": refunds,
        "reversals": reversals,
        "settlement_batches": settlement_batches,
        "settlement_items": settlement_items,
        "daily_control_totals": daily_control_totals,
    }
    manifest = [write_csv(name, df) for name, df in tables.items()]
    payload = {
        "phase": 26,
        "generation_mode": "FULLY_SYNTHETIC_NO_COMPANY_SOURCE",
        "seed": SEED,
        "source_dependencies": [],
        "raw_company_identity_preserved": "NO",
        "cloud_upload_performed": "NO",
        "table_count": len(tables),
        "total_rows": int(sum(len(df) for df in tables.values())),
        "tables": manifest,
    }
    OUT.mkdir(parents=True, exist_ok=True)
    manifest_path = OUT / "phase_26_manifest.json"
    manifest_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    payload["manifest_sha256"] = hashlib.sha256(manifest_path.read_bytes()).hexdigest()
    return payload


if __name__ == "__main__":
    result = build_all()
    print(json.dumps({
        "status": "GENERATED",
        "phase": 26,
        "tables": result["table_count"],
        "total_rows": result["total_rows"],
        "output": str(OUT),
    }, ensure_ascii=False))
