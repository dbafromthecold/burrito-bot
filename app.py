# app.py
import os
import pyodbc
from pathlib import Path
from fastapi import FastAPI
from fastapi.responses import JSONResponse, HTMLResponse, FileResponse
from openai import AzureOpenAI

app = FastAPI()
BASE_DIR = Path(__file__).resolve().parent


# ---------- Azure OpenAI (lazy init so startup can't fail) ----------
def get_aoai_client() -> AzureOpenAI:
    """
    Create Azure OpenAI client only when needed.
    Prevents App Service startup crashes.
    """
    return AzureOpenAI(
        api_key=os.environ["AZURE_OPENAI_KEY"],
        azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
        api_version="2024-02-15-preview"
    )


def get_aoai_deployment() -> str:
    return os.environ["AZURE_OPENAI_DEPLOYMENT"]


# ---------- DB connection ----------
def get_conn():
    return pyodbc.connect(
        driver="{ODBC Driver 18 for SQL Server}",
        server=os.environ["SQL_SERVER"],
        database=os.environ.get("SQL_DB", ""),
        uid=os.environ["SQL_UID"],
        pwd=os.environ["SQL_PWD"],
        Encrypt="yes",
        TrustServerCertificate="yes",
        timeout=30,
    )


def call_search(conn, query: str, top_k: int = 5):
    """
    Calls vector search stored procedure in SQL Server.
    SQL Server performs semantic retrieval (NOT the LLM).
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


# ---------- Serve UI ----------
@app.get("/", response_class=HTMLResponse)
def index():
    return FileResponse(BASE_DIR / "ui.html")


# ---------- Remove NULL / Junk Fields ----------
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


# ---------- Build RAG Context ----------
def build_context(rows: list[dict]) -> str:
    """
    Converts SQL results into grounded evidence for the LLM.
    """

    blocks = []

    for r in rows:
        name = r.get("name") or r.get("Name")
        city = r.get("city")
        rating = r.get("rating")
        review_count = r.get("review_count")
        address = r.get("address")
        reviews = r.get("combined_reviews") or r.get("metadata_text") or ""

        block = f"""
Restaurant: {name}
City: {city}
Rating: {rating} ({review_count} reviews)
Address: {address}

Customer feedback:
{reviews}
"""
        blocks.append(block.strip())

    return "\n\n---\n\n".join(blocks)


# ---------- Generation Step ----------
def generate_answer(question: str, context: str) -> str:
    """
    Calls Azure OpenAI using grounded SQL context.
    """

    system_prompt = """
You are Burrito Bot, an assistant that recommends Mexican restaurants.

STRICT RULES:
- Use ONLY the provided context.
- Do NOT make up restaurants or facts.
- If unsure, say you don't know.
- Keep answers friendly and concise.
"""

    user_prompt = f"""
User Question:
{question}

Context:
{context}
"""

    client = get_aoai_client()
    deployment = get_aoai_deployment()

    response = client.chat.completions.create(
        model=deployment,
        temperature=0.2,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ]
    )

    return response.choices[0].message.content


# ---------- Chat Endpoint (RAG Pipeline) ----------
@app.post("/chat")
def chat(payload: dict):
    q = (payload.get("question") or "").strip()
    top_k = int(payload.get("top_k") or 5)

    if not q:
        return {"answer": "Please ask a question.", "citations": []}

    try:
        with get_conn() as conn:
            rows = [remove_null_fields(r) for r in call_search(conn, q, top_k)]
    except Exception as ex:
        return JSONResponse(
            status_code=500,
            content={"error": f"SQL error: {ex}"}
        )

    if not rows:
        return {"answer": "No matches found.", "citations": []}

    context = build_context(rows)

    try:
        answer = generate_answer(q, context)
    except Exception as e:
        # Do not kill the API if AOAI fails
        answer = f"(LLM unavailable: {e})"

    return {
        "answer": answer,
        "citations": rows
    }
