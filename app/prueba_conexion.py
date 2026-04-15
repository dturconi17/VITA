import pyodbc
import pandas as pd

server = '148.113.152.56'
database = 'SISVITA'
username = 'consulta_ventas'
password = '.3e1JN$x[k7eB>UC<NTZ'

conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    f'SERVER={server};'
    f'DATABASE={database};'
    f'UID={username};'
    f'PWD={password}'
)

query = "SELECT TOP 10 * FROM sales.tu_tabla"

df = pd.read_sql(query, conn)

print(df.head())