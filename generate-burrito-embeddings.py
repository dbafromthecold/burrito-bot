import logging
import pyodbc
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import os

def main(mytimer: func.TimerRequest) -> None:
    logging.info('🔄 Running Azure Function to trigger embedding generation')

    # === GET SECRETS FROM KEY VAULT ===
    credential = DefaultAzureCredential()
    client = SecretClient(vault_url=kv_url, credential=credential)

    kv_url     = client.get_secret("AZURE-KEY-VAULT-URL").value
    sql_server = client.get_secret("AZURE-SQL-SERVER").value
    sql_proc   = client.get_secret("AZURE-SQL-EMBEDDING-PROC").value
    sql_db     = client.get_secret("AZURE-SQL-DATABASE").value
    sql_user   = client.get_secret("azure-sql-username").value
    sql_pass   = client.get_secret("azure-sql-password").value

    # === CONNECT TO SQL ===
    conn_str = (
        f"Driver={{ODBC Driver 18 for SQL Server}};"
        f"Server={sql_server};"
        f"Database={sql_db};"
        f"UID={sql_user};"
        f"PWD={sql_pass};"
        f"Encrypt=yes;"
        f"TrustServerCertificate=no;"
    )

    try:
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        logging.info(f"📡 Calling stored procedure: {sql_proc}")
        cursor.execute(f"EXEC {sql_proc}")
        conn.commit()
        logging.info("✅ Embedding generation complete.")
    except Exception as e:
        logging.error(f"❌ Failed to call stored procedure: {e}")
    finally:
        if conn:
            conn.close()
