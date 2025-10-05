from pathlib import Path
import re

ROOT = Path(__file__).parent
OUTPUT = ROOT / "combined-update-milestones.sql"

pattern = re.compile(r"update-milestones(\d+)\.sql")

def sort_key(path: Path) -> tuple[int, str]:
    match = pattern.fullmatch(path.name)
    if match:
        return (int(match.group(1)), path.name)
    return (10**9, path.name)

sql_files = sorted(ROOT.glob("update-milestones*.sql"), key=sort_key)

with OUTPUT.open("w", encoding="utf-8") as out_file:
    for index, sql_path in enumerate(sql_files):
        if index:
            out_file.write("\n")
        out_file.write(f"-- {sql_path.name}\n")
        out_file.write(sql_path.read_text(encoding="utf-8"))
        out_file.write("\n")

print(f"Combined {len(sql_files)} files into {OUTPUT}")
