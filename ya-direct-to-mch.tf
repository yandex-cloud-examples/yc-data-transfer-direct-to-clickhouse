# Infrastructure for Cloud Functions, Object Storage, the Managed Service for ClickHouse®, and Data Transfer
#
# RU: https://cloud.yandex.ru/docs/data-transfer/tutorials/direct-clickhouse
# EN: https://cloud.yandex.com/en/docs/data-transfer/tutorials/direct-clickhouse
#
# Specify the following settings:
locals {

  folder_id   = "" # Set your cloud folder ID, same as for provider.
  app_token   = "" # Set an application token.
  bucket_name = "" # Set a unique bucket name.
  ch_password = "" # Set a password for the ClickHouse® admin user.

  path_to_zip_cf  = "" # Path to ZIP archive with function code
  create_function = 0  # Set to 1 to create the Cloud Function.

  # Specify these settings ONLY AFTER the cluster is created. Then run "terraform apply" command again.
  # You should set up a source endpoint for the Object Storage bucket using the GUI to obtain its ID.
  source_endpoint_id = "" # Set the source endpoint ID.
  transfer_enabled   = 0  # Set to 1 to enable Transfer.

  # The following settings are predefined. Change them only if necessary.
  network_name          = "mch-network"          # Name of the network
  subnet_name           = "mch-subnet-a"         # Name of the subnet
  zone_a_v4_cidr_blocks = "10.1.0.0/16"          # CIDR block for the subnet in the ru-central1-a availability zone
  sa-name               = "storage-lockbox-sa"   # Name of the service account
  function_name         = "direct-to-objstorage" # Name of the function
  security_group_name   = "mch-security-group"   # Name of the security group
  mch_cluster_name      = "mch-cluster"          # Name of the ClickHouse cluster
  database_name         = "db1"                  # Name of the ClickHouse database
  ch_username           = "user1"                # Name of the ClickHouse admin user
  target_endpoint_name  = "mch-target"         # Name of the target endpoint for the ClickHouse® cluster
  transfer_name         = "s3-mch-transfer"      # Name of the transfer from the Object Storage bucket to the Managed Service for ClickHouse® cluster
}

# Network infrastructure for the Managed Service for ClickHouse® cluster

resource "yandex_vpc_network" "network" {
  description = "Network for the Managed Service for ClickHouse® cluster"
  name        = local.network_name
}

resource "yandex_vpc_subnet" "subnet-a" {
  description    = "Subnet in the ru-central1-a availability zone"
  name           = local.subnet_name
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [local.zone_a_v4_cidr_blocks]
}

resource "yandex_vpc_security_group" "security-group" {
  description = "Security group for the Managed Service for ClickHouse® cluster"
  name        = local.security_group_name
  network_id  = yandex_vpc_network.network.id

  ingress {
    description    = "# Allow connections to the Managed Service for ClickHouse® cluster from the internet"
    protocol       = "TCP"
    port           = 9440
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "# Allow connections to the Managed Service for ClickHouse® cluster from the internet"
    protocol       = "TCP"
    port           = 8443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "The rule allows all outgoing traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Infrastructure for the Object Storage bucket and Cloud Function

# Create a service account
resource "yandex_iam_service_account" "example-sa" {
  folder_id = local.folder_id
  name      = local.sa-name
}

# Create a static key for the service account
resource "yandex_iam_service_account_static_access_key" "example-sa-sk" {
  service_account_id = yandex_iam_service_account.example-sa.id
}

# Grant the service account a role to create storages
resource "yandex_resourcemanager_folder_iam_binding" "s3-admin" {
  folder_id = local.folder_id
  role      = "storage.admin"

  members = [
    "serviceAccount:${yandex_iam_service_account.example-sa.id}",
  ]
}

# Grant the service account a role to use Lockbox
resource "yandex_resourcemanager_folder_iam_binding" "lockbox" {
  folder_id = local.folder_id
  role      = "lockbox.payloadViewer"

  members = [
    "serviceAccount:${yandex_iam_service_account.example-sa.id}",
  ]
}

# Create Yandex Object Storage bucket
resource "yandex_storage_bucket" "example-bucket" {
  bucket     = local.bucket_name
  access_key = yandex_iam_service_account_static_access_key.example-sa-sk.access_key
  secret_key = yandex_iam_service_account_static_access_key.example-sa-sk.secret_key
}

# Create a Lockbox secret
resource "yandex_lockbox_secret" "sa_key_token_secret" {
  name        = "sa_key_token_secret"
  description = "Contains static key pair and Yandex Direct token in order to pass it later to Yandex Cloud Function"
  folder_id   = local.folder_id
}

# Create a version of Lockbox secret with static key pair and application token
resource "yandex_lockbox_secret_version" "first_version" {
  secret_id = yandex_lockbox_secret.sa_key_token_secret.id
  entries {
    key        = "access_key"
    text_value = yandex_iam_service_account_static_access_key.example-sa-sk.access_key
  }
  entries {
    key        = "secret_key"
    text_value = yandex_iam_service_account_static_access_key.example-sa-sk.secret_key
  }
  entries {
    key        = "app_token"
    text_value = local.app_token
  }
}

# Create a Yandex Cloud Function
resource "yandex_function" "example-function" {
  count              = local.create_function
  name               = local.function_name
  user_hash          = "example-function-hash"
  folder_id          = local.folder_id
  runtime            = "python39"
  entrypoint         = "example.foo"
  memory             = "128"
  execution_timeout  = "100"
  service_account_id = yandex_iam_service_account.example-sa.id
  content {
    zip_filename = local.path_to_zip_cf
  }
  secrets {
    id                   = yandex_lockbox_secret.sa_key_token_secret.id
    version_id           = yandex_lockbox_secret_version.first_version.id
    key                  = "access_key"
    environment_variable = "AWS_ACCESS_KEY_ID"
  }

  secrets {
    id                   = yandex_lockbox_secret.sa_key_token_secret.id
    version_id           = yandex_lockbox_secret_version.first_version.id
    key                  = "secret_key"
    environment_variable = "AWS_SECRET_ACCESS_KEY"
  }

  secrets {
    id                   = yandex_lockbox_secret.sa_key_token_secret.id
    version_id           = yandex_lockbox_secret_version.first_version.id
    key                  = "app_token"
    environment_variable = "TOKEN"
  }
  environment = {
    BUCKET = yandex_storage_bucket.example-bucket.bucket
  }
}

resource "yandex_mdb_clickhouse_cluster" "mch-cluster" {
  description        = "Managed Service for ClickHouse® cluster"
  name               = local.mch_cluster_name
  environment        = "PRODUCTION"
  network_id         = yandex_vpc_network.network.id
  security_group_ids = [yandex_vpc_security_group.security-group.id]

  clickhouse {
    resources {
      resource_preset_id = "s2.micro" # 2 vCPU, 8 GB RAM
      disk_type_id       = "network-ssd"
      disk_size          = 10 # GB
    }
  }

  host {
    type             = "CLICKHOUSE"
    zone             = "ru-central1-a"
    subnet_id        = yandex_vpc_subnet.subnet-a.id
    assign_public_ip = true # Required for connection from the internet
  }

  database {
    name = local.database_name
  }

  user {
    name     = local.ch_username
    password = local.ch_password
    permission {
      database_name = local.database_name
    }
  }
}

# Data Transfer infrastructure

resource "yandex_datatransfer_endpoint" "mch-target" {
  description = "Target endpoint for ClickHouse® cluster"
  name        = local.target_endpoint_name
  settings {
    clickhouse_target {
      connection {
        connection_options {
          mdb_cluster_id = yandex_mdb_clickhouse_cluster.mch-cluster.id
          database       = local.database_name
          user           = local.ch_username
          password {
            raw = local.ch_password
          }
        }
      }
      cleanup_policy = "CLICKHOUSE_CLEANUP_POLICY_DROP"
    }
  }
}

resource "yandex_datatransfer_transfer" "objstorage-mch-transfer" {
  count       = local.transfer_enabled
  description = "Transfer from the Object Storage bucket to the Managed Service for ClickHouse® cluster"
  name        = "transfer-objstorage-mch"
  source_id   = local.source_endpoint_id
  target_id   = yandex_datatransfer_endpoint.mch-target.id
  type        = "SNAPSHOT_ONLY" # Copy data
}
