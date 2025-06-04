# Transferring data from Yandex Direct to a Yandex Managed Service for ClickHouse® data mart

Follow this scenario to migrate data from Yandex Direct to Managed Service for ClickHouse® by means of Cloud Functions, Object Storage, and Data Transfer. To do this:

1. With Cloud Functions, transfer your data from Yandex Direct to Object Storage.
2. With Data Transfer, transfer your data from Object Storage to Managed Service for ClickHouse®.

To run this scenario, use the [Yandex Cloud management console](https://console.yandex.cloud) or Terraform. Also, you will need the [example-py.zip](example-py.zip) archive file, containing a Python code for the function.
If you prefer using Terraform, download this configuration file: [ya-direct-to-mch.tf](ya-direct-to-mch.tf). 

The scenario includes preparing your test data, creating and activating a data transfer, checking that the transfer runs as intended, and deleting temporary data and resources engaged in the deployment. For more information, see [this tutorial](https://yandex.cloud/en/docs/data-transfer/tutorials/direct-to-mch).

Additional materials on Yandex Data Transfer:

* [Available transfers](https://yandex.cloud/en/docs/data-transfer/transfer-matrix)
* [Tutorials](https://yandex.cloud/en/docs/data-transfer/tutorials/)
