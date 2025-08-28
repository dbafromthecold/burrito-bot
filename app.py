import os, pyodbc
from fastapi import FastAPI
from fastapi.responses import JSONResponse

# look for the connection string in all possible slots
cs = (
    os.getenv("SQLAZURECONNSTR_DefaultConnection")
    or os.getenv("SQLCONNSTR_DefaultConnection")
    or os.getenv("CUSTOMCONNSTR_DefaultConnection")
    or os.getenv("DefaultConnection")  # fallback if you move it to App Settings instead
)

if not cs:
    raise RuntimeError("No SQL connection string found in environment")

conn = pyodbc.connect(
    "Driver={ODBC Driver 18 for SQL Server};"
    + cs
    + ";Connection Timeout=30;"
)

# --- Azure OpenAI client (only if all env vars exist) ---
USE_LLM = all(k in os.environ for k in [
    "AZURE_OPENAI_ENDPOINT",
    "AZURE_OPENAI_API_VERSION",
    "AZURE_OPENAI_DEPLOYMENT",
    "AZURE_OPENAI_API_KEY"
])

if USE_LLM:
    from openai import AzureOpenAI
    client = AzureOpenAI(
        api_key=os.environ["AZURE_OPENAI_API_KEY"],
        api_version=os.environ["AZURE_OPENAI_API_VERSION"],
        azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    )
    CHAT_MODEL = os.environ["AZURE_OPENAI_DEPLOYMENT"]

app = FastAPI()

@app.post("/chat")
def chat(payload: dict):
    q = (payload.get("question") or "").strip()
    if not q:
        return {"answer": "Please ask a question.", "citations": []}

    # call your SQL stored procedure
    with conn.cursor() as cur:
        cur.execute("{CALL dbo.search_restaurants(?,?)}", (q, 5))
        cols = [c[0].lower() for c in cur.description]
        matches = [dict(zip(cols, r)) for r in cur.fetchall()]

    context = "\n".join([f"- {m['name']} in {m['city']}" for m in matches])

    if USE_LLM:
        resp = client.chat.completions.create(
            model=CHAT_MODEL,
            messages=[
                {"role":"system","content":"Answer using only the CONTEXT."},
                {"role":"user","content":f"QUESTION: {q}\n\nCONTEXT:\n{context}"}
            ],
            temperature=0.2,
        )
        answer = resp.choices[0].message.content
    else:
        answer = "Top results from SQL:\n" + context

    return {"answer": answer, "citations": matches}
