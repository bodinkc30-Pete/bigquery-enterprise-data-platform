from __future__ import annotations

import hashlib
import importlib.util
import json
import re
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "data" / "financial_ops_synth"
EVIDENCE = ROOT / "evidence" / "phase_26_generator_validation.json"
SCHEMA = json.loads((ROOT / "data_contracts" / "phase_26_financial_table_contracts.json").read_text(encoding="utf-8-sig"))
DESIGN = json.loads((ROOT / "evidence" / "phase_26_design_validation.json").read_text(encoding="utf-8-sig"))
TABLE_NAMES = list(SCHEMA["tables"].keys())


def load_tables() -> dict[str, pd.DataFrame]:
    return {name: pd.read_csv(OUT / f"{name}.csv", keep_default_na=False) for name in TABLE_NAMES}


def file_hashes() -> dict[str, str]:
    return {name: hashlib.sha256((OUT / f"{name}.csv").read_bytes()).hexdigest() for name in TABLE_NAMES}


def generator_module():
    path = ROOT / "src" / "generators" / "phase26_financial_synth_generator.py"
    spec = importlib.util.spec_from_file_location("phase26_generator", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module

import yaml
CONTRACT = yaml.safe_load((ROOT / "data_contracts" / "phase_26_bank_grade_synthetic_extension_contract.yml").read_text(encoding="utf-8-sig"))


def _grain_unique(df: pd.DataFrame, grain: list[str]) -> bool:
    return not df.duplicated(grain).any()


def _fk_subset(child: pd.DataFrame, child_col: str, parent: pd.DataFrame, parent_col: str) -> bool:
    return set(child[child_col]).issubset(set(parent[parent_col]))


def _schema_exact(tables: dict[str, pd.DataFrame]) -> bool:
    return all(list(tables[name].columns) == spec["columns"] for name, spec in SCHEMA["tables"].items())


def _all_grains_unique(tables: dict[str, pd.DataFrame]) -> bool:
    return all(_grain_unique(tables[name], spec["grain"]) for name, spec in SCHEMA["tables"].items())


def _all_fks_valid(tables: dict[str, pd.DataFrame]) -> bool:
    for name, spec in SCHEMA["tables"].items():
        for child_col, target in spec.get("foreign_keys", {}).items():
            parent_name, parent_col = target.split(".")
            if not _fk_subset(tables[name], child_col, tables[parent_name], parent_col):
                return False
    return True


def _money_integer_nonnegative(tables: dict[str, pd.DataFrame]) -> bool:
    for df in tables.values():
        for col in [c for c in df.columns if c.endswith("_amount_minor")]:
            numeric = pd.to_numeric(df[col], errors="coerce")
            if numeric.isna().any() or (numeric < 0).any() or not ((numeric % 1) == 0).all():
                return False
    return True


def _transaction_account_currency_match(tables: dict[str, pd.DataFrame]) -> bool:
    tx = tables["transactions"]
    acc = tables["accounts"][["account_id", "currency"]].rename(columns={"currency": "account_currency"})
    joined = tx.merge(acc, on="account_id", how="left")
    return joined["account_currency"].notna().all() and joined["currency"].eq(joined["account_currency"]).all()


def _event_lifecycle_valid(tables: dict[str, pd.DataFrame]) -> bool:
    tx = tables["transactions"].set_index("transaction_id")
    ev = tables["payment_events"].copy()
    ev["event_time"] = pd.to_datetime(ev["event_time"], errors="coerce")
    rules = SCHEMA["lifecycle_rules"]
    for transaction_id, group in ev.groupby("transaction_id", sort=False):
        if transaction_id not in tx.index:
            return False
        g = group.sort_values("event_sequence")
        expected = rules[str(tx.loc[transaction_id, "status"])]
        if g["event_type"].tolist() != expected:
            return False
        if g["event_sequence"].tolist() != list(range(1, len(expected) + 1)):
            return False
        if not g["event_time"].is_monotonic_increasing:
            return False
        if not g["currency"].eq(tx.loc[transaction_id, "currency"]).all():
            return False
        if not g["event_amount_minor"].eq(tx.loc[transaction_id, "transaction_amount_minor"]).all():
            return False
    return ev["transaction_id"].nunique() == len(tx)


def _refund_reversal_valid(tables: dict[str, pd.DataFrame]) -> bool:
    tx = tables["transactions"].set_index("transaction_id")
    refunds = tables["refunds"]
    reversals = tables["reversals"]
    if set(refunds["transaction_id"]) & set(reversals["transaction_id"]):
        return False
    for r in refunds.itertuples(index=False):
        if r.transaction_id not in tx.index:
            return False
        base = tx.loc[r.transaction_id]
        if base["status"] != "COMPLETED" or r.currency != base["currency"]:
            return False
        if int(r.refund_amount_minor) <= 0 or int(r.refund_amount_minor) > int(base["transaction_amount_minor"]):
            return False
    for r in reversals.itertuples(index=False):
        if r.transaction_id not in tx.index:
            return False
        base = tx.loc[r.transaction_id]
        if base["status"] != "COMPLETED" or r.currency != base["currency"]:
            return False
        if int(r.reversal_amount_minor) != int(base["transaction_amount_minor"]):
            return False
    return True


def _settlement_valid(tables: dict[str, pd.DataFrame]) -> bool:
    tx = tables["transactions"].set_index("transaction_id")
    items = tables["settlement_items"].copy()
    batches = tables["settlement_batches"].copy()
    completed_ids = set(tx.loc[tx["status"].eq("COMPLETED")].index)
    if set(items["transaction_id"]) != completed_ids or items["transaction_id"].duplicated().any():
        return False
    for r in items.itertuples(index=False):
        base = tx.loc[r.transaction_id]
        if int(r.net_amount_minor) != int(r.gross_amount_minor) - int(r.refund_amount_minor) - int(r.reversal_amount_minor):
            return False
        if int(r.gross_amount_minor) != int(base["transaction_amount_minor"]) or r.currency != base["currency"]:
            return False
        if int(r.net_amount_minor) < 0:
            return False
    agg = items.groupby(["settlement_batch_id", "settlement_date", "currency"], as_index=False).agg(
        item_count=("settlement_item_id", "count"),
        gross_amount_minor=("gross_amount_minor", "sum"),
        refund_amount_minor=("refund_amount_minor", "sum"),
        reversal_amount_minor=("reversal_amount_minor", "sum"),
        net_amount_minor=("net_amount_minor", "sum"),
    )
    cols = ["settlement_batch_id", "settlement_date", "currency", "item_count", "gross_amount_minor", "refund_amount_minor", "reversal_amount_minor", "net_amount_minor"]
    left = agg[cols].sort_values("settlement_batch_id").reset_index(drop=True)
    right = batches[cols].sort_values("settlement_batch_id").reset_index(drop=True)
    return left.equals(right) and batches["batch_status"].eq("SETTLED").all()


def _daily_controls_valid(tables: dict[str, pd.DataFrame]) -> bool:
    generator = generator_module()
    expected = generator.build_daily_controls(
        tables["transactions"], tables["refunds"], tables["reversals"], tables["settlement_items"]
    )
    actual = tables["daily_control_totals"].copy()
    actual = actual[expected.columns].sort_values(["business_date", "currency"]).reset_index(drop=True)
    expected = expected.sort_values(["business_date", "currency"]).reset_index(drop=True)
    return actual.equals(expected) and actual["control_status"].eq("MATCHED").all()


def _privacy_clean(tables: dict[str, pd.DataFrame]) -> bool:
    forbidden = set(SCHEMA["privacy_forbidden_columns"])
    email_re = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
    for df in tables.values():
        if forbidden & {c.lower() for c in df.columns}:
            return False
        for col in df.select_dtypes(include="object").columns:
            text = "\n".join(df[col].astype(str).head(10000).tolist())
            if email_re.search(text):
                return False
    return True


def validate() -> dict:
    before_hashes = file_hashes()
    generator = generator_module()
    rerun = generator.build_all()
    after_hashes = file_hashes()
    tables = load_tables()
    manifest = json.loads((OUT / "phase_26_manifest.json").read_text(encoding="utf-8-sig"))
    bounds = CONTRACT["bounded_scale"]
    allowed_currencies = set(CONTRACT["currency_policy"]["currencies"])
    row_counts = {name: int(len(df)) for name, df in tables.items()}
    phase27_artifacts = [
        str(p.relative_to(ROOT)) for p in ROOT.rglob("*")
        if p.is_file() and ("phase27" in p.name.lower() or "phase_27" in p.name.lower())
    ]
    token_checks = (
        tables["customers"]["customer_token"].str.startswith("SYN-CUSTOMER-").all()
        and tables["accounts"]["account_token"].str.startswith("SYN-ACCOUNT-").all()
        and tables["merchants"]["merchant_token"].str.startswith("SYN-MERCHANT-").all()
    )
    manifest_hashes = {x["table"]: x["sha256"] for x in manifest["tables"]}
    checks = {
        "design_gate_20_pass": DESIGN.get("status") == "PASS" and DESIGN.get("check_count") == 20,
        "exact_ten_tables": set(tables) == set(TABLE_NAMES) and len(tables) == 10,
        "schema_columns_exact": _schema_exact(tables),
        "grain_uniqueness": _all_grains_unique(tables),
        "referential_integrity": _all_fks_valid(tables),
        "bounded_scale": row_counts["customers"] <= bounds["customers_max"] and row_counts["accounts"] <= bounds["accounts_max"] and row_counts["merchants"] <= bounds["merchants_max"] and row_counts["transactions"] <= bounds["transactions_max"] and row_counts["payment_events"] <= bounds["payment_events_max"] and sum(row_counts.values()) <= bounds["total_rows_all_tables_max"],
        "money_integer_nonnegative": _money_integer_nonnegative(tables),
        "currency_domain": all(set(df["currency"]).issubset(allowed_currencies) for df in tables.values() if "currency" in df.columns),
        "transaction_account_currency_match": _transaction_account_currency_match(tables),
        "transaction_idempotency_unique": not tables["transactions"]["idempotency_key"].duplicated().any(),
        "transaction_completion_semantics": (
            tables["transactions"].loc[tables["transactions"]["status"].eq("PENDING"), "completed_at"].eq("").all()
            and tables["transactions"].loc[~tables["transactions"]["status"].eq("PENDING"), "completed_at"].ne("").all()
        ),
        "payment_event_lifecycle_ordering": _event_lifecycle_valid(tables),
        "refund_reversal_rules": _refund_reversal_valid(tables),
        "settlement_reconciliation": _settlement_valid(tables),
        "daily_control_totals_reconcile": _daily_controls_valid(tables),
        "synthetic_token_policy": bool(token_checks),
        "privacy_columns_and_email_clean": _privacy_clean(tables),
        "fully_synthetic_no_company_source": (
            manifest.get("generation_mode") == "FULLY_SYNTHETIC_NO_COMPANY_SOURCE"
            and manifest.get("source_dependencies") == []
            and manifest.get("raw_company_identity_preserved") == "NO"
            and manifest.get("cloud_upload_performed") == "NO"
        ),
        "deterministic_rerun_hash_10_of_10": before_hashes == after_hashes == manifest_hashes and len(after_hashes) == 10,
        "manifest_rows_match_files": (
            manifest.get("table_count") == 10
            and manifest.get("total_rows") == sum(row_counts.values())
            and {x["table"]: int(x["rows"]) for x in manifest["tables"]} == row_counts
        ),
        "phase27_artifacts_absent": len(phase27_artifacts) == 0,
    }
    bad_duplicate_tx = {k: v.copy(deep=True) for k, v in tables.items()}
    bad_duplicate_tx["transactions"] = pd.concat(
        [bad_duplicate_tx["transactions"], bad_duplicate_tx["transactions"].iloc[[0]]], ignore_index=True
    )
    bad_orphan = {k: v.copy(deep=True) for k, v in tables.items()}
    bad_orphan["transactions"].loc[0, "account_id"] = "BROKEN-ACCOUNT"
    bad_event = {k: v.copy(deep=True) for k, v in tables.items()}
    first_tx = bad_event["payment_events"].iloc[0]["transaction_id"]
    event_idx = bad_event["payment_events"].index[bad_event["payment_events"]["transaction_id"].eq(first_tx)]
    bad_event["payment_events"].loc[event_idx[0], "event_sequence"] = 99
    bad_refund = {k: v.copy(deep=True) for k, v in tables.items()}
    refund_txid = bad_refund["refunds"].iloc[0]["transaction_id"]
    base_amount = int(bad_refund["transactions"].set_index("transaction_id").loc[refund_txid, "transaction_amount_minor"])
    bad_refund["refunds"].loc[0, "refund_amount_minor"] = base_amount + 1
    bad_settlement = {k: v.copy(deep=True) for k, v in tables.items()}
    bad_settlement["settlement_items"] = pd.concat(
        [bad_settlement["settlement_items"], bad_settlement["settlement_items"].iloc[[0]]], ignore_index=True
    )
    bad_control = {k: v.copy(deep=True) for k, v in tables.items()}
    bad_control["daily_control_totals"].loc[0, "transaction_count"] += 1
    failure_detection = {
        "duplicate_transaction_id": not _all_grains_unique(bad_duplicate_tx),
        "orphan_account_reference": not _all_fks_valid(bad_orphan),
        "payment_event_out_of_order": not _event_lifecycle_valid(bad_event),
        "refund_above_transaction_amount": not _refund_reversal_valid(bad_refund),
        "duplicate_settlement_item": (
            not _all_grains_unique(bad_settlement) and not _settlement_valid(bad_settlement)
        ),
        "daily_control_total_mismatch": not _daily_controls_valid(bad_control),
    }
    failure_detection = {k: bool(v) for k, v in failure_detection.items()}
    checks["controlled_failure_detectors_6_of_6"] = all(failure_detection.values()) and len(failure_detection) == 6
    checks["cloud_mutation_absent"] = manifest.get("cloud_upload_performed") == "NO"
    checks["phase27_not_started"] = len(phase27_artifacts) == 0
    checks = {k: bool(v) for k, v in checks.items()}

    result = {
        "phase": 26,
        "step": "26.2B_LOCAL_SYNTHETIC_VALIDATION",
        "status": "PASS" if all(checks.values()) else "FAIL",
        "checks": checks,
        "check_count": len(checks),
        "passed": sum(bool(v) for v in checks.values()),
        "table_count": len(tables),
        "total_rows": sum(row_counts.values()),
        "row_counts": row_counts,
        "deterministic_hash_match_count": sum(before_hashes[k] == after_hashes[k] for k in TABLE_NAMES),
        "controlled_failure_detection": failure_detection,
        "generation_mode": manifest.get("generation_mode"),
        "cloud_mutation_performed": False,
        "phase27_artifact_count": len(phase27_artifacts),
        "phase27_status": "NOT_STARTED",
    }
    EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
    EVIDENCE.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    return result


if __name__ == "__main__":
    result = validate()
    print(json.dumps({
        "phase": 26,
        "step": "26.2B",
        "status": result["status"],
        "passed": result["passed"],
        "check_count": result["check_count"],
        "tables": result["table_count"],
        "total_rows": result["total_rows"],
        "hash_match": result["deterministic_hash_match_count"],
        "failure_detectors": sum(result["controlled_failure_detection"].values()),
    }, ensure_ascii=False))
    if result["status"] != "PASS":
        raise SystemExit(1)
