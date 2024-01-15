import numpy as np
import polars as pl
import sys
from cryptography.fernet import Fernet

parquet_file = sys.argv[1]

df = pl.read_parquet(parquet_file)
key = Fernet.generate_key()
key_file = f"{parquet_file}.key"
with open(key_file, 'wb') as file:
    file.write(key)
    file.close()
    print(f"wrote key to {key_file}")
f = Fernet(key)

enc_fn = lambda x: f.encrypt(str(x).encode())

df = df.with_columns(
    pl.col("first_name").map_elements(enc_fn),
    pl.col("last_name").map_elements(enc_fn),
)

enc_file = f"{parquet_file}.enc"
df.write_parquet(enc_file)
print(f"wrote encrypted table to {enc_file}")
