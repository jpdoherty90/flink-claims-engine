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

  lifecycle {
    prevent_destroy = true
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

  lifecycle {
    prevent_destroy = true
  }
}


resource "confluent_kafka_topic" "auto-fnol" {
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }
  topic_name         = "auto-fnol"
  rest_endpoint      = confluent_kafka_cluster.dedicated.rest_endpoint
  credentials {
    key    = confluent_api_key.claims-app-manager-kafka-api-key.id
    secret = confluent_api_key.claims-app-manager-kafka-api-key.secret
  }
  config = {
    "confluent.value.schema.validation" = "true"
  }

  lifecycle {
    prevent_destroy = true
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

  lifecycle {
    prevent_destroy = true
  }
}


resource "confluent_schema" "auto-fnol" {
  schema_registry_cluster {
    id = confluent_schema_registry_cluster.sr_package.id
  }
  rest_endpoint = confluent_schema_registry_cluster.sr_package.rest_endpoint
  subject_name = "auto-fnol-value"
  format = "AVRO"
  schema = file("./schemas/avro/auto-fnol.avsc")
  credentials {
    key    = confluent_api_key.claims-env-manager-schema-registry-api-key.id
    secret = confluent_api_key.claims-env-manager-schema-registry-api-key.secret
  }

  lifecycle {
    prevent_destroy = true
  }
}


















