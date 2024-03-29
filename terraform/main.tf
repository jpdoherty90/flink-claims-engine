terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.55.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
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
    # See https://docs.confluent.io/cloud/current/stream-governance/packages.html#stream-governance-regions
    id = data.confluent_schema_registry_region.sg_package.id
  }
}

resource "confluent_kafka_cluster" "basic" {
  display_name = "claims_kafka_cluster"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = var.region
  basic {}

  environment {
    id = confluent_environment.flink_claims_engine.id
  }
}