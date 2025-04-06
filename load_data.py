import os
import pandas as pd
import numpy as np
import faiss
import time
from dotenv import load_dotenv
import pyodbc
from openai import AzureOpenAI

# === LOAD ENVIRONMENT VARIABLES ===
load_dotenv()

# === AZURE SQL CONFIGURATION ===
server = os.getenv("AZURE_SQL_SERVER")
database = os.getenv("AZURE_SQL_DATABASE")
source_table = os.getenv("AZURE_SQL_SOURCE_TABLE")
target_table = os.getenv("AZURE_SQL_TARGET_TABLE")
username = os.getenv("AZURE_SQL_USERNAME")
password = os.getenv("AZURE_SQL_PASSWORD")

# === AZURE OPENAI CONFIGURATION ===
client = AzureOpenAI(
    api_key=os.getenv("EMBEDDING_API_KEY"),
    api_version=os.getenv("EMBEDDING_API_VERSION"),
    azure_endpoint=os.getenv("EMBEDDING_ENDPOINT"),
)
EMBEDDING_DEPLOYMENT_NAME = os.getenv("EMBEDDING_MODEL_NAME")

# === CONNECT TO AZURE SQL DATABASE ===
print(f"\n🔌 Connecting to Azure SQL Database '{database}' using SQL authentication...")
connection_string = (
    f"Driver={{ODBC Driver 17 for SQL Server}};"
    f"Server={server};"
    f"Database={database};"
    f"UID={username};"
    f"PWD={password};"
    f"Encrypt=yes;"
    f"TrustServerCertificate=no;"
    f"Connection Timeout=30;"
)

# === LOAD DATA FROM SOURCE TABLE ===
try:
    conn = pyodbc.connect(connection_string)
    query = f"SELECT name, city, rating, review_count, address, phone, url FROM {source_table}"
    df = pd.read_sql(query, conn)
    conn.close()
except Exception as e:
    raise RuntimeError(f"❌ Failed to load data from Azure SQL: {e}")

print(f"✅ Loaded {len(df)} rows from Azure SQL source table '{source_table}'")

# === CLEAN & PREPARE DATA ===
df = df.dropna(subset=['name', 'city', 'address'])

df['description'] = (
    df['name'] + ' at ' + df['address'] + ' in ' + df['city'] +
    '. Rating: ' + df['rating'].astype(str) + ' stars.' +
    ' Based on ' + df['review_count'].astype(str) + ' reviews.'
)

print("\n📋 Sample cleaned descriptions:")
print(df[['name', 'description']].head())

# === EMBEDDING FUNCTION ===
def get_embedding(text, max_retries=3, delay=1):
    for attempt in range(max_retries):
        try:
            response = client.embeddings.create(
                input=[text],
                model=EMBEDDING_DEPLOYMENT_NAME
            )
            return response.data[0].embedding
        except Exception as e:
            print(f"⚠️ Error generating embedding (attempt {attempt + 1}): {e}")
            time.sleep(delay)
    raise RuntimeError(f"Failed to get embedding after {max_retries} attempts.")

# === GENERATE EMBEDDINGS ===
print("\n🔄 Generating embeddings using Azure OpenAI...")
embedding_list = []
for i, desc in enumerate(df['description'].tolist(), 1):
    print(f"Embedding {i}/{len(df)}...", end='\r')
    embedding = get_embedding(desc)
    embedding_list.append(embedding)

embeddings = np.array(embedding_list).astype("float32")

# === TRUNCATE + BATCH INSERT INTO TARGET TABLE ===
print(f"\n📝 Replacing data in Azure SQL target table '{target_table}'...")

try:
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()

    # Clear target table
    cursor.execute(f"TRUNCATE TABLE {target_table}")
    conn.commit()

    # Prepare all rows as list of tuples
    rows_to_insert = [
        (
            row['name'],
            row['city'],
            float(row['rating']),
            int(row['review_count']),
            row['address'],
            row['phone'],
            row['url'],
            row['description'],
            list(map(float, embedding_list[i]))
        )
        for i, row in df.iterrows()
    ]

    if not rows_to_insert:
        print("⚠️ No rows to insert. Exiting.")
        conn.close()
        exit()

    # Batch insert
    cursor.executemany(
        f"""
        INSERT INTO {target_table} (name, city, rating, review_count, address, phone, url, description, embedding)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        rows_to_insert
    )

    conn.commit()
    cursor.execute(f"SELECT COUNT(*) FROM {target_table}")
    print(f"✅ Insert complete! Total rows in '{target_table}': {cursor.fetchone()[0]}")
    conn.close()
except Exception as e:
    raise RuntimeError(f"❌ Failed to insert embeddings into Azure SQL: {e}")

# === OPTIONAL: LOCAL FAISS EXPORT ===
print("\n📦 Saving FAISS index and processed data locally...")

d = embeddings.shape[1]
index = faiss.IndexFlatL2(d)
index.add(embeddings)

PROCESSED_CSV = 'processed_burrito_data.csv'
FAISS_INDEX_FILE = 'burrito_index.faiss'

faiss.write_index(index, FAISS_INDEX_FILE)
df.to_csv(PROCESSED_CSV, index=False)

print(f"\n✅ FAISS index saved as '{FAISS_INDEX_FILE}'")
print(f"✅ Processed data saved as '{PROCESSED_CSV}'")
print("\n🎉 Embedding pipeline complete! Vector-enriched data is now live in Azure SQL.")

