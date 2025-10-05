import json
from pathlib import Path

root = Path(r'c:\Trae Apps\BabySleepApp')
json_path = root / 'currentmilestones-deletelater.json'

LINES_PER_FILE = 100
OUTPUT_BASENAME = 'update-milestones'


def escape_sql(value: str) -> str:
    """Escape single quotes for SQL string literals."""
    return value.replace("'", "''")


with json_path.open('r', encoding='utf-8') as f:
    milestones = json.load(f)


def open_output(index: int):
    path = root / f"{OUTPUT_BASENAME}{index}.sql"
    return path.open('w', encoding='utf-8'), path


file_index = 1
current_file, current_path = open_output(file_index)
current_line_count = 0

try:
    for entry in milestones:
        statement_lines = [
            "UPDATE public.milestones\n",
            "SET short_name   = 'Dummy',\n",
            "    priority     = -1, \n",
            "    shareability = -1\n",
            (
                "WHERE id = '{id}' AND title = '{title}';\n".format(
                    id=escape_sql(entry['id']),
                    title=escape_sql(entry['title'])
                )
            ),
            "\n",
        ]

        if current_line_count + len(statement_lines) > LINES_PER_FILE:
            current_file.close()
            file_index += 1
            current_file, current_path = open_output(file_index)
            current_line_count = 0

        current_file.writelines(statement_lines)
        current_line_count += len(statement_lines)
finally:
    current_file.close()