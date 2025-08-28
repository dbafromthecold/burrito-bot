# app.py
import os, traceback
from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI()

# --- single place to open a SQL connection via env vars ---
def get_conn():
    import pyodbc
    server = os.environ["SQL_SERVER"]          # e.g. tcp:burrito-bot-sql.uksouth.cloudapp.azure.com,1433
    database = os.environ.get("SQL_DB", "")    # e.g. burrito-bot-db
    uid = os.environ["SQL_UID"]                # e.g. burrito-bot-web
    pwd = os.environ["SQL_PWD"]                # your secret
    return pyodbc.connect(
        driver="{ODBC Driver 18 for SQL Server}",
        server=server,
        database=database,
        uid=uid,
        pwd=pwd,
        Encrypt="yes",
        TrustServerCertificate="yes",  # keep yes for VM unless you’ve installed a trusted cert
        timeout=30,
    )

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/diagnose")
def diagnose():
    # Quick sanity report (password not returned)
    report = {
        "ok": False,
        "server": os.environ.get("SQL_SERVER"),
        "database": os.environ.get("SQL_DB"),
        "uid": os.environ.get("SQL_UID"),
        "have_pwd": bool(os.environ.get("SQL_PWD")),
    }
    try:
        conn = get_conn()
        report["connect"] = "ok"
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
            report["select1"] = cur.fetchone()[0]
        try:
            with conn.cursor() as cur:
                # Your proc name per earlier messages
                cur.execute("EXEC dbo.search_restaurants ?, ?", ("test", 1))
            report["proc_exec"] = "ok"
        except Exception as ex:
            report["proc_exec"] = f"error: {type(ex).__name__}: {ex}"
        finally:
            conn.close()
        report["ok"] = True
        return report
    except Exception as ex:
        report.update({
            "step": "connect-or-exec",
            "errorType": type(ex).__name__,
            "message": str(ex),
            "trace": traceback.format_exc().splitlines()[-1]
        })
        return JSONResponse(status_code=500, content=report)
