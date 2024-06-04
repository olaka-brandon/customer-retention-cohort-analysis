import pandas as pd
import openpyxl

file = 'data/online_retail.xlsx'
df = pd.read_excel(file)

csv_file = 'data/online_retail.csv'
df.to_csv(csv_file, index=False) 