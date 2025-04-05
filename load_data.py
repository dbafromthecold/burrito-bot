import os
import pandas as pd
import numpy as np
import faiss
import time
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
import pyodbc
from openai import AzureOpenAI

# === LOAD ENVIRONMENT VARIABLES ===
load_dotenv()

# === AZURE SQL CONFIGURATION ===
server = os.getenv("AZURE_SQL_SERVER")
database = os.getenv("AZURE_SQL_DATABASE")
table = os.getenv("AZURE_SQL_TABLE")

# === AZURE OPENAI CONFIGURATION ===
client = AzureOpenAI(
    api_key=os.getenv("EMBEDDING_API_KEY"),
    api_version=os.getenv("EMBEDDING_API_VERSION"),
    azure_endpoint=os.getenv("EMBEDDING_ENDPOINT"),
)
EMBEDDING_DEPLOYMENT_NAME = os.getenv("EMBEDDING_MODEL_NAME")

# === GET ENTRA ID ACCESS TOKEN FOR SQL ===
credential = DefaultAzureCredential(exclude_interactive_browser_credential=False)
token = credential.get_token("https://database.windows.net/.default")
print("Access token retrieved:", token.token[:20], "...")
access_token = token.token.encode("utf-16-le")

# === CONNECT TO AZURE SQL DATABASE ===
print(f"\n🔌 Connecting to Azure SQL Database '{database}'...")
connection_string = (
    f"Driver={{ODBC Driver 17 for SQL Server}};"
    f"Server={server};"
    f"Database={database};"
    f"Authentication=ActiveDirectoryAccessToken;"
)

try:
    conn = pyodbc.connect(connection_string, attrs_before={1256: access_token})
    query = f"SELECT name, city, rating, review_count, address, phone, url FROM {table}"
    df = pd.read_sql(query, conn)
    conn.close()
except Exception as e:
    raise RuntimeError(f"❌ Failed to load data from Azure SQL: {e}")

print(f"✅ Loaded {len(df)} rows from Azure SQL table '{table}'")

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

# === BUILD FAISS INDEX ===
d = embeddings.shape[1]
index = faiss.IndexFlatL2(d)
index.add(embeddings)

# === SAVE OUTPUTS ===
PROCESSED_CSV = 'processed_burrito_data.csv'
FAISS_INDEX_FILE = 'burrito_index.faiss'

faiss.write_index(index, FAISS_INDEX_FILE)
df.to_csv(PROCESSED_CSV, index=False)

print(f"\n✅ FAISS index saved as '{FAISS_INDEX_FILE}'")
print(f"✅ Processed data saved as '{PROCESSED_CSV}'")
print("\n🎉 Data processing complete! The burrito chatbot is ready to use.")