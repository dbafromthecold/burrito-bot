# app.py
import os
from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok"}

def _get_conn_str():
    return (
        os.getenv("SQLAZURECONNSTR_DefaultConnection")
        or os.getenv("SQLCONNSTR_DefaultConnection")
        or os.getenv("CUSTOMCONNSTR_DefaultConnection")
    )

@app.post("/chat")
def chat(payload: dict):
    q = (payload.get("question") or "").strip()
    if not q:
        return {"answer": "Please ask a question.", "citations": []}

    cs = _get_conn_str()
    if not cs:
        return JSONResponse(status_code=500, content={"error": "SQL connection string not found in env."})

    import pyodbc  # import only when needed
    conn = pyodbc.connect("Driver={ODBC Driver 18 for SQL Server};" + cs + ";Connection Timeout=30;")
    try:
        with conn.cursor() as cur:
            cur.execute("{CALL dbo.usp_SemanticSearchRestaurants(?,?)}", (q, 5))
            cols = [c[0].lower() for c in cur.description]
            rows = [dict(zip(cols, r)) for r in cur.fetchall()]
    finally:
        conn.close()

    ctx = "\n".join([f"- {r['name']} in {r['city']}" for r in rows])
    return {"answer": "Top results from SQL:\n" + ctx, "citations": rows}
