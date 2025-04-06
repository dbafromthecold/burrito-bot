import os
import pandas as pd
from dotenv import load_dotenv
import pyodbc

# === LOAD ENVIRONMENT VARIABLES ===
load_dotenv()

# === AZURE SQL CONFIGURATION ===
server = os.getenv("AZURE_SQL_SERVER")
database = os.getenv("AZURE_SQL_DATABASE")
username = os.getenv("AZURE_SQL_USERNAME")
password = os.getenv("AZURE_SQL_PASSWORD")
stored_procedure = os.getenv("AZURE_SQL_EMBEDDING_PROC")

# === CONNECT TO AZURE SQL DATABASE ===
print(f"Connecting to Azure SQL Database '{database}' using SQL authentication...")
connection_string = (
    f"Driver=ODBC Driver 18 for SQL Server;"
    f"Server={server};"
    f"Database={database};"
    f"UID={username};"
    f"PWD={password};"
    f"Encrypt=yes;"
    f"TrustServerCertificate=yes;"
    f"Connection Timeout=30;"
)

# === CALL STORED PROCEDURE ===
try:
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()

    print(f"Calling stored procedure: {stored_procedure}...")
    cursor.execute(f"EXEC {stored_procedure}")
    conn.commit()

    print(f"✅ Stored procedure '{stored_procedure}' executed successfully!")
    conn.close()
except Exception as e:
    raise RuntimeError(f"❌ Failed to call stored procedure '{stored_procedure}': {e}")
