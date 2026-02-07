# app.py
import os
import pyodbc
from pathlib import Path
from fastapi import FastAPI
from fastapi.responses import JSONResponse, HTMLResponse, FileResponse

app = FastAPI()

BASE_DIR = Path(__file__).resolve().parent  # folder where app.py lives

# ---------- DB connection ----------
def get_conn():
    return pyodbc.connect(
        driver="{ODBC Driver 18 for SQL Server}",
        server=os.environ["SQL_SERVER"],          # e.g. tcp:vm.dns.name,1433
        database=os.environ.get("SQL_DB", ""),
        uid=os.environ["SQL_UID"],
        pwd=os.environ["SQL_PWD"],
        Encrypt="yes",
        TrustServerCertificate="yes",             # VM without trusted cert
        timeout=30,
    )

def call_search(conn, query: str, top_k: int = 5):
    """
    Call the dbo.search_restaurants stored procedure.
    Returns list[dict].
    """
    with conn.cursor() as cur:
        cur.execute("EXEC dbo.search_restaurants ?, ?", (query, top_k))
        cols = [c[0] for c in cur.description] if cur.description else []
        if not cols:
            return []
        return [dict(zip(cols, row)) for row in cur.fetchall()]


# ---------- Health ----------
@app.get("/health")
def health():
    return {"status": "ok"}


# ---------- Minimal web UI at "/" ----------
@app.get("/", response_class=HTMLResponse)
def index():
    """Serve the ui.html file instead of embedding HTML inline."""
    return FileResponse(BASE_DIR / "ui.html")


# ---------- Removing NULLs ----------
def remove_null_fields(row: dict) -> dict:
    cleaned = {}
    for k, v in row.items():
        if v is None:
            continue
        if isinstance(v, str) and not v.strip():
            continue
        if isinstance(v, str) and v.upper() == "N/A":
            continue
        cleaned[k] = v
    return cleaned

# ---------- JSON API ----------
@app.post("/chat")
def chat(payload: dict):
    q = (payload.get("question") or "").strip()
    top_k = int(payload.get("top_k") or 5)
    if not q:
        return {"answer": "Please ask a question.", "citations": []}

    try:
        with get_conn() as conn:
           # rows = call_search(conn, q, top_k)
            rows = [remove_null_fields(r) for r in call_search(conn, q, top_k)]
    except Exception as ex:
        return JSONResponse(
            status_code=500,
            content={"error": f"{type(ex).__name__}: {ex}"}
        )

    if not rows:
        return {"answer": "No matches found.", "citations": []}

    # Adjust field names if your proc returns different columns
    lines = []
    for r in rows:
        name = r.get("Name") or r.get("restaurant") or r.get("title") or "(no name)"
        city = r.get("city") or r.get("location") or ""
        lines.append(f"- {name}" + (f" in {city}" if city else ""))
    answer = "Top results:\n" + "\n".join(lines)
    return {"answer": answer, "citations": rows}