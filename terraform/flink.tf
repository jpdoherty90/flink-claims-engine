
resource "confluent_flink_compute_pool" "claims_compute_pool" {
  display_name = "claims_compute_pool"
  cloud        = "AWS"
  region       = var.region
  max_cfu      = 10
  environment {
    id = confluent_environment.flink_claims_engine.id
  }
}

# resource "confluent_service_account" "claims-flink-sa" {
#   display_name = "claims-flink-sa"
#   description  = "Service Account for Claims Flink pool"
# }

# resource "confluent_role_binding" "claims-flink-sa-role" {
#   principal   = "User:${confluent_service_account.claims-flink-sa.id}"
#   role_name   = "FlinkAdmin"
#   crn_pattern = confluent_environment.flink_claims_engine.resource_name
# }

# resource "confluent_api_key" "cliams_flink_api_key" {
#   display_name = "claims_flink_api_key"

#   owner {
#     id          = confluent_service_account.claims-flink-sa.id
#     api_version = confluent_service_account.claims-flink-sa.api_version
#     kind        = confluent_service_account.claims-flink-sa.kind
#   }

# }

# data "confluent_flink_region" "claims_flink_region" {
#   cloud  = "AWS"
#   region = var.region
# }

# data "confluent_organization" "se_strat_org" {}

# resource "confluent_flink_statement" "create_customers" {
#   organization {
#     id = data.confluent_organization.se_strat_org.id
#   }

#   environment {
#     id = confluent_environment.flink_claims_engine.id
#   }

#   compute_pool {
#     id = confluent_flink_compute_pool.claims_compute_pool.id
#   }

#   principal {
#     id = confluent_service_account.claims-flink-sa.id
#   }

#   statement = <<EOT
#     CREATE TABLE customers(
#       `account_id` INT,
#       `first_name` STRING,
#       `last_name` STRING,
#       `dob` STRING,
#       `state_of_residence` STRING,
#       `email` STRING,
#       `drivers_license_num` STRING,
#       `policy_expiration_date` DATE,
#       PRIMARY KEY(`account_id`) NOT ENFORCED
#     );
#     EOT

#   properties = {
#     "sql.current-catalog"  = confluent_environment.flink_claims_engine.display_name
#     "sql.current-database" = confluent_kafka_cluster.dedicated.display_name
#   }

#   rest_endpoint = data.confluent_flink_region.claims_flink_region.rest_endpoint

#   credentials {
#     key    = confluent_api_key.cliams_flink_api_key.id
#     secret = confluent_api_key.cliams_flink_api_key.secret
#   }

#   lifecycle {
#     prevent_destroy = true
#   }

# }








