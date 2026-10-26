import pandas as pd
df = pd.read_sql("select count(*) as n from walmart_fact_table where is_current", conn)
print(df)