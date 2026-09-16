from __future__ import annotations

import json
import re
import os
from pathlib import Path

import pandas as pd

PROJECT = Path(__file__).resolve().parents[2]
_workshop = os.environ.get("P08_PRIVATE_WORKSHOP")
WORKSHOP = Path(_workshop) if _workshop else None

def _workshop_root() -> Path:
    if WORKSHOP is None:
        raise RuntimeError("Set P08_PRIVATE_WORKSHOP to the local private workshop path.")
    return WORKSHOP
SAFE = PROJECT / "data" / "portfolio_safe"
CLASSIFICATION = PROJECT / "data_contracts" / "phase_02_field_classification.csv"
REGISTRY = PROJECT / "data_contracts" / "phase_01_source_registry.csv"
PROFILE = PROJECT / "evidence" / "phase_01_structure_verified.json"

EMAIL_RE = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
PHONE_RE = re.compile(r"(?<!\d)\d{9,13}(?!\d)")


def canonical_file(role: str) -> Path:
    reg = pd.read_csv(REGISTRY, encoding="utf-8-sig")
    flag = reg["canonical_source"].astype(str).str.lower().eq("true")
    row = reg[flag & reg["project_role"].eq(role)].iloc[0]
    return _workshop_root() / str(row["relative_path"])


def _clean_values(series: pd.Series) -> set[str]:
    out = set()
    for value in series.dropna():
        text = str(value).strip()
        if len(text) >= 5 and text.lower() not in {"nan", "none", "null"}:
            out.add(text)
    return out


def restricted_raw_values() -> set[str]:
    fields = pd.read_csv(CLASSIFICATION, encoding="utf-8-sig")
    fields = fields[fields["sensitivity"].eq("RESTRICTED")]
    frames: list[tuple[str, str, pd.DataFrame]] = []

    orders = canonical_file("ORDERS_TRANSACTIONS")
    creators = canonical_file("CREATOR_MASTER")
    payment = canonical_file("CREATOR_LIVE_PAYMENT")
    paw = canonical_file("MESSY_SOURCE_ONBOARDING_LAB")

    frames.append(("ORDERS_TRANSACTIONS", "csv", pd.read_csv(orders, low_memory=False)))
    frames.append(("CREATOR_MASTER", "csv", pd.read_csv(creators, low_memory=False)))

    pay_xls = pd.ExcelFile(payment)
    frames.append(("CREATOR_LIVE_PAYMENT", pay_xls.sheet_names[14], pd.read_excel(payment, sheet_name=14, header=1)))
    frames.append(("CREATOR_LIVE_PAYMENT", pay_xls.sheet_names[15], pd.read_excel(payment, sheet_name=15, header=18)))

    paw_xls = pd.ExcelFile(paw)
    paw_headers = {0: 10, 1: 3, 2: 3, 3: 3, 4: 1, 5: 0, 6: 0, 7: 2, 9: 1}
    for idx, header in paw_headers.items():
        frames.append(("MESSY_SOURCE_ONBOARDING_LAB", paw_xls.sheet_names[idx], pd.read_excel(paw, sheet_name=idx, header=header)))

    values: set[str] = set()
    for role, sheet, df in frames:
        positions = fields[(fields["source_role"].eq(role)) & (fields["sheet_name"].eq(sheet))]["column_position"].astype(int)
        for pos in positions:
            if 0 <= pos < df.shape[1]:
                values.update(_clean_values(df.iloc[:, pos]))
    return values


def generated_text_values() -> set[str]:
    values: set[str] = set()
    for path in sorted(SAFE.glob("*.csv")):
        df = pd.read_csv(path)
        for col in df.select_dtypes(include=["object", "string"]).columns:
            values.update(_clean_values(df[col]))
    return values


def direct_pattern_hits() -> dict[str, int]:
    email_hits = 0
    phone_hits = 0
    for path in sorted(SAFE.glob("*.csv")):
        df = pd.read_csv(path)
        for col in df.select_dtypes(include=["object", "string"]).columns:
            for value in df[col].dropna().astype(str):
                email_hits += int(bool(EMAIL_RE.search(value)))
                phone_hits += int(bool(PHONE_RE.search(value)))
    return {"email_pattern_hits": email_hits, "phone_pattern_hits": phone_hits}


def validate() -> dict:
    raw_restricted = restricted_raw_values()
    generated = generated_text_values()
    overlap = raw_restricted.intersection(generated)
    patterns = direct_pattern_hits()
    result = {
        "raw_restricted_values_scanned": len(raw_restricted),
        "generated_text_values_scanned": len(generated),
        "raw_restricted_exact_overlap_count": len(overlap),
        **patterns,
    }
    result["status"] = "PASS" if len(overlap) == 0 and all(v == 0 for k, v in patterns.items()) else "FAIL"
    return result


def detects_dummy_pii(text: str) -> bool:
    return bool(EMAIL_RE.search(text) or PHONE_RE.search(text))


if __name__ == "__main__":
    result = validate()
    print(json.dumps(result, ensure_ascii=False))
    raise SystemExit(0 if result["status"] == "PASS" else 1)
