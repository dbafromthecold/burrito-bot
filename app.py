# app.py (replace your snippet with this)
import os, re, traceback
from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI()

# --- read raw connection string from env (support all App Service prefixes) ---
def _get_conn_env():
    for key in ("SQLCONNSTR_DefaultConnection",
                "SQLAZURECONNSTR_DefaultConnection",
                "CUSTOMCONNSTR_DefaultConnection",
                "DefaultConnection"):
        val = os.getenv(key)
        if val:
            return key, val
    return None, None

# --- robust parser: tolerate casing, spacing, and odd whitespace ---
def _parse_connstr(raw: str) -> dict:
    if not raw:
        return {}
    # normalize odd unicode spaces
    raw = re.sub(r"[\u00A0\u2000-\u200B\u202F\u205F\u3000]", " ", raw)
    parts = [p for p in (s.strip() for s in raw.split(";")) if p]
    kv = {}
    for p in parts:
        if "=" in p:
            k, v = p.split("=", 1)
            kv[k.strip().lower()] = v.strip().strip('"').strip("'").strip()
    # map common aliases
    return {
        "server":   kv.get("server") or kv.get("data source") or kv.get("addr") or kv.get("address"),
        "database": kv.get("database") or kv.get("initial catalog"),
        "uid":      kv.get("uid") or kv.get("user id") or kv.get("user"),
        "pwd":      kv.get("pwd") or kv.get("password"),
        "encrypt":  (kv.get("encrypt") or "yes"),
        "trust":    (kv.get("trustservercertificate") or kv.get("trust server certificate") or "yes"),
        "timeout":  kv.get("connection timeout") or kv.get("timeout") or "30",
    }

# --- build a pyodbc connection using kwargs (avoids ODBC string parser) ---
def _open_conn(parsed: dict):
    import pyodbc
    if not parsed.get("server") or not parsed.get("uid"):
        raise RuntimeError(f"Bad SQL env. Parsed -> server='{parsed.get('server')}', uid='{parsed.get('uid')}'")
    return pyodbc.connect(
        driver="{ODBC Driver 18 for SQL Server}",
        server=parsed["server"],
        database=parsed.get("database") or "",
        uid=parsed["uid"],
        pwd=parsed.get("pwd") or "",
        Encrypt=str(parsed["encrypt"]).lower(),
        TrustServerCertificate=str(parsed["trust"]).lower(),
        timeout=int(parsed["timeout"]),
    )

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/diagnose")
def diagnose():
    which, raw = _get_conn_env()
    if not raw:
        return JSONResponse(status_code=500, content={
            "ok": False,
            "step": "read-connstr",
            "message": "No SQL connection string env var found. Expected SQLCONNSTR_DefaultConnection (or SQLAZURECONNSTR_...)."
        })

    parsed = _parse_connstr(raw)
    # mask password for the report
    report = {
        "ok": False,
        "envVarUsed": which,
        "parsed": {
            "server": parsed.get("server"),
            "database": parsed.get("database"),
            "uid": parsed.get("uid"),
            "encrypt": parsed.get("encrypt"),
            "trust": parsed.get("trust"),
            "timeout": parsed.get("timeout"),
        }
    }

    try:
        conn = _open_conn(parsed)
        report["connect"] = "ok"
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
            report["select1"] = cur.fetchone()[0]
        try:
            with conn.cursor() as cur:
                # your proc name (per your note): dbo.search_restaurants
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
