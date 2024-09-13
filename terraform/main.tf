terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.68.0"
    }
  }
}

provider "confluent" {
}

resource "confluent_environment" "flink_claims_engine" {
  display_name = "Flink_Claims_Engine"
}

data "confluent_schema_registry_region" "sg_package" {
  cloud   = "AWS"
  region  = var.region
  package = var.sg_package
}

resource "confluent_schema_registry_cluster" "sr_package" {
  package = data.confluent_schema_registry_region.sg_package.package

  environment {
    id = confluent_environment.flink_claims_engine.id
  }

  region {
    id = data.confluent_schema_registry_region.sg_package.id
  }

}

resource "confluent_kafka_cluster" "dedicated" {
  display_name = "claims_kafka_cluster"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = var.region
  dedicated {
    cku = 2
  }

  environment {
    id = confluent_environment.flink_claims_engine.id
  }
}


resource "confluent_service_account" "claims-app-manager" {
  display_name = "claims-app-manager"
  description  = "Service Account for managing claims apps"
}

resource "confluent_role_binding" "claims-app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.claims-app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.dedicated.rbac_crn
}

resource "confluent_api_key" "claims-app-manager-kafka-api-key" {
  display_name = "claims-app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'claims-app-manager' service account"
  owner {
    id          = confluent_service_account.claims-app-manager.id
    api_version = confluent_service_account.claims-app-manager.api_version
    kind        = confluent_service_account.claims-app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = confluent_environment.flink_claims_engine.id
    }
  }

  depends_on = [
    confluent_role_binding.claims-app-manager-kafka-cluster-admin
  ]

}

resource "confluent_kafka_topic" "oracle_redo_log" {
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }

  topic_name       = "OracleCdcSourceConnector-customers-redo-log"
  rest_endpoint    = confluent_kafka_cluster.dedicated.rest_endpoint
  partitions_count = 1
  credentials {
    key    = confluent_api_key.claims-app-manager-kafka-api-key.id
    secret = confluent_api_key.claims-app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_topic" "auto_fnol" {
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }
  topic_name       = "auto_fnol"
  rest_endpoint    = confluent_kafka_cluster.dedicated.rest_endpoint
  partitions_count = 1
  credentials {
    key    = confluent_api_key.claims-app-manager-kafka-api-key.id
    secret = confluent_api_key.claims-app-manager-kafka-api-key.secret
  }
  config = {
    "confluent.value.schema.validation" = "true"
  }

}

resource "confluent_service_account" "claims-env-manager" {
  display_name = "claims-env-manager"
  description  = "Service account to manage 'Flink_Claims_Engine' environment"
}

resource "confluent_role_binding" "claims-env-manager-environment-admin" {
  principal   = "User:${confluent_service_account.claims-env-manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.flink_claims_engine.resource_name
}

resource "confluent_api_key" "claims-env-manager-schema-registry-api-key" {
  display_name = "claims-env-manager-schema-registry-api-key"
  description  = "Schema Registry API Key that is owned by 'claims-env-manager' service account"
  owner {
    id          = confluent_service_account.claims-env-manager.id
    api_version = confluent_service_account.claims-env-manager.api_version
    kind        = confluent_service_account.claims-env-manager.kind
  }

  managed_resource {
    id          = confluent_schema_registry_cluster.sr_package.id
    api_version = confluent_schema_registry_cluster.sr_package.api_version
    kind        = confluent_schema_registry_cluster.sr_package.kind

    environment {
      id = confluent_environment.flink_claims_engine.id
    }
  }

  depends_on = [
    confluent_role_binding.claims-env-manager-environment-admin
  ]

}


resource "confluent_schema" "auto_fnol" {
  schema_registry_cluster {
    id = confluent_schema_registry_cluster.sr_package.id
  }
  rest_endpoint = confluent_schema_registry_cluster.sr_package.rest_endpoint
  subject_name  = "auto_fnol-value"
  format        = "AVRO"
  schema        = file("./schemas/avro/auto_fnol.avsc")
  credentials {
    key    = confluent_api_key.claims-env-manager-schema-registry-api-key.id
    secret = confluent_api_key.claims-env-manager-schema-registry-api-key.secret
  }

}

resource "confluent_connector" "customers_oracle_cdc" {

  environment {
    id = confluent_environment.flink_claims_engine.id
  }

  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }

  config_sensitive = {
    "kafka.api.key"    = var.kafka_api_key,
    "kafka.api.secret" = var.kafka_api_secret
    "oracle.username"  = var.rds_username,
    "oracle.password"  = var.rds_password,
  }

  config_nonsensitive = {
    "connector.class"         = "OracleCdcSource",
    "name"                    = "CustomersOracleCDC",
    "kafka.auth.mode"         = "KAFKA_API_KEY",
    "oracle.server"           = aws_db_instance.insurance-customers.address,
    "oracle.port"             = "1521",
    "oracle.sid"              = "ORCL",
    "table.inclusion.regex"   = "ORCL[.]ADMIN1[.]CUSTOMERS",
    "start.from"              = "snapshot",
    "query.timeout.ms"        = "60000",
    "redo.log.row.fetch.size" = "1",
    "table.topic.name.template" = "ORCL.ADMIN1.CUSTOMERS",
    "redo.log.topic.name"       = "OracleCdcSourceConnector-customers-redo-log",
    "numeric.mapping"           = "best_fit_or_double",
    "output.data.key.format"    = "AVRO",
    "output.data.value.format"  = "AVRO",
    "tasks.max"                 = "1",
    "heartbeat.interval.ms": "1800000"
  }

}

