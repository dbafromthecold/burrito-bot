import pyodbc

server = "burrito-bot-db-server.database.windows.net"
database = "burrito-bot-db"
username = "XXXXXXXXXXXXXXXXXXXXXXX"
password = "XXXXXXXXXXXXXXXXXXXXXXX"

conn_str = (
    f"Driver={{ODBC Driver 18 for SQL Server}};"
    f"Server={server};"
    f"Database={database};"
    f"UID={username};"
    f"PWD={password};"
    f"Encrypt=yes;"
    f"TrustServerCertificate=no;"
    f"Connection Timeout=30;"
)

print("Connecting...")
conn = pyodbc.connect(conn_str)
print("✅ Connected!")
conn.close()