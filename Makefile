LOCATION ?= eastus
CONTAINER ?= parquet
PARQUET_FILE ?= ./userdata.parquet
ifndef RESOURCE_GROUP
$(error RESOURCE_GROUP is not set)
endif
ifndef STORAGE_ACCOUNT
$(error STORAGE_ACCOUNT is not set)
endif
$(eval SAS_END = $(shell date -u -d "30 minutes" '+%Y-%m-%dT%H:%MZ'))
$(eval SAS_TOKEN = $(shell az storage container generate-sas \
	--name $(CONTAINER) \
	--account-name $(STORAGE_ACCOUNT) \
	--https-only \
	--permissions dwlr \
	--expiry $(SAS_END) \
	--output tsv))
KEY_FILE := $(PARQUET_FILE).key
ENCRYPTED_FILE := $(PARQUET_FILE).enc

.PHONY: infra
infra:
	az storage account create \
		--name $(STORAGE_ACCOUNT) \
		--resource-group $(RESOURCE_GROUP) \
		--location $(LOCATION) && \
	az storage container create \
		--account-name $(STORAGE_ACCOUNT) \
		--name $(CONTAINER) \
		--public-access off

$(ENCRYPTED_FILE) $(KEY_FILE):
encrypt:
	python3 encrypt.py "$(PARQUET_FILE)"

.PHONY: upload
upload: $(ENCRYPTED_FILE) $(KEY_FILE)
	@az storage blob upload \
		--account-name $(STORAGE_ACCOUNT) \
		--container-name $(CONTAINER) \
		--sas-token "$(SAS_TOKEN)" \
		--file $(ENCRYPTED_FILE) \

.PHONY: run 
run: $(KEY_FILE)
	@PARQUET_FILE=$(ENCRYPTED_FILE) \
	CONTAINER=$(CONTAINER) \
	SAS_TOKEN="$(SAS_TOKEN)" \
	FERNET_KEY=$(shell cat $(KEY_FILE)) \
	python3 main.py
