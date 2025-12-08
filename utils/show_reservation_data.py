import pandas as pd

reservation_file = '2025-09-01/reservation.csv'
reservation_df = pd.read_csv(reservation_file)
print(len(reservation_df))

csv_file = '2025-09-01/reservation_content.csv'

df = pd.read_csv(csv_file)
print(len(df))

# df_new = df.drop("chair", axis=1)
# df_new = df_new.drop("desk", axis=1)
# df_new = df_new.drop("worker", axis=1)
#
# df_new['worker_need'] = 0
# df_new['worker_id'] = 0
df_new = df

for i in range(len(df_new)):
    if pd.isnull(df_new.loc[i, 'food']):
        df_new.loc[i, 'food'] = "X"

print('### CSV New Schema')
print(df_new.dtypes)

print('\n### Top 10 New Rows')
print(df_new.head(10))

df_new.to_csv("dataset/new_reservation_content.csv", index=False)
