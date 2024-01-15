import numpy as np
import polars as pl
import os
from cryptography.fernet import Fernet

storage_options = {
    "azure_storage_account_name": os.environ["STORAGE_ACCOUNT"],
    "azure_storage_sas_token": os.environ["SAS_TOKEN"],
}

container = os.environ["CONTAINER"]
parquet_file = os.environ["PARQUET_FILE"]
source = f"az://{container}/{parquet_file}"
fernet_key = os.environ["FERNET_KEY"]
f = Fernet(fernet_key)

dec_fn = lambda x: f.decrypt(x).decode()

lazy_df = pl.scan_parquet(source, storage_options=storage_options)
df = lazy_df.with_columns(
    pl.col("first_name").map_elements(dec_fn),
    pl.col("last_name").map_elements(dec_fn),
).group_by('first_name').agg(
    median_salary=pl.median("salary"),
    count=pl.count("salary"),
).filter(
    pl.col("count") > 2
).drop_nulls().top_k(10, by="median_salary").collect()
print(df.write_json(row_oriented=True))
