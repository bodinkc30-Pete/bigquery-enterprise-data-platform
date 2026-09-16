from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parents[1]
TEXT_EXTS = {'.py','.sql','.yml','.yaml','.json','.md','.txt','.csv','.tf','.toml'}
FORBIDDEN = {
    'local_workspace': re.compile(r'D:\\Neo-Workspace|preme15', re.I),
    'private_runtime': re.compile(r'evidence[/\\]private_runtime', re.I),
    'master_handoff': re.compile(r'PROJECT_08_BIGQUERY_ENTERPRISE_DATA_PLATFORM_MASTER_HANDOFF', re.I),
    'internal_source_names': re.compile(r'PawChoice|Smooto x Rave up|Live Performance Core Stats|Product Card Traffic Stats|Campaign overview data', re.I),
    'private_key_material': re.compile(r'BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY', re.I),
    'client_secret_value': re.compile(r'client_secret\s*[:=]\s*["\'][^"\']{8,}', re.I),
}
violations=[]
for path in ROOT.rglob('*'):
    if not path.is_file() or '.git' in path.parts or path.suffix.lower() not in TEXT_EXTS:
        continue
    if path.resolve() == Path(__file__).resolve():
        continue
    text=path.read_text(encoding='utf-8-sig', errors='replace')
    for name,pat in FORBIDDEN.items():
        if pat.search(text): violations.append((str(path.relative_to(ROOT)),name))
if violations:
    for item in violations: print('VIOLATION', *item)
    sys.exit(1)
print(f'PUBLICATION_GUARD_PASS files_scanned={sum(1 for p in ROOT.rglob("*") if p.is_file())}')
