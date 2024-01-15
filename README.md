# Processing PII data in a Parquet stream

## Scenario

We have a data set that contains PII data. A third party wants to perform an aggregated analysis on the this data, which is taking the PII-relevant fields into consideration, so we cannot simply mask them.

## Approach

Columns `first_name` and `last_name` (for brevity we stick to those fields) are encrypted with a symmetric key in the original dataset. The encrypted dataset is uploaded to an Azure storage account. A consumer can then read the parquet data from the storage account and decrypt the data during processing using the symmetric key.

## Instructions

### Requirements

```bash
pip3 install -r requirements.txt
```

### Run

```bash
export RESOURCE_GROUP=myresourcegroup
export STORAGE_ACCOUNT=mynewstorageaccount
make encrypt
make upload
make run | jq -c .[]
```

## References

Sample data retrieved from [teradata/kylo](https://github.com/Teradata/kylo/blob/master/samples/sample-data/parquet/userdata1.parquet)

