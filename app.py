# app.py (add this alongside your existing code)
import os, traceback
from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI()

def _get_conn_str():
    # Read from App Service Connection Strings (prefixed env vars)
    for key in ("SQLAZURECONNSTR_DefaultConnection",
                "SQLCONNSTR_DefaultConnection",
                "CUSTOMCONNSTR_DefaultConnection",
                "DefaultConnection"):
        val = os.getenv(key)
        if val:
            return key, val
    return None, None

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/diagnose")
def diagnose():
    which, cs = _get_conn_str()
    if not cs:
        return JSONResponse(status_code=500, content={
            "ok": False,
            "step": "read-connstr",
            "message": "No SQL connection string env var found. Expected SQLCONNSTR_DefaultConnection (or SQLAZURECONNSTR_...)."
        })

    info = {"ok": True, "envVarUsed": which}
    try:
        import pyodbc
        conn = pyodbc.connect("Driver={ODBC Driver 18 for SQL Server};" + cs + ";Connection Timeout=30;")
        info["connect"] = "ok"
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
            info["select1"] = cur.fetchone()[0]
        # Try the proc with minimal params; adjust if your proc signature differs
        try:
            with conn.cursor() as cur:
                # More reliable on SQL Server than ODBC {CALL ...}:
                cur.execute("EXEC dbo.search_restaurants ?, ?", ("test", 1))
                # We won’t fetch rows; just ensure it runs
            info["proc_exec"] = "ok"
        except Exception as ex:
            info["proc_exec"] = f"error: {type(ex).__name__}: {ex}"
        finally:
            conn.close()
    except Exception as ex:
        return JSONResponse(status_code=500, content={
            "ok": False,
            "step": "connect-or-exec",
            "envVarUsed": which,
            "errorType": type(ex).__name__,
            "message": str(ex)
        })
    return info