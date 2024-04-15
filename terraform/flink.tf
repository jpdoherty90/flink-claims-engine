
resource "confluent_flink_compute_pool" "claims_compute_pool" {
  display_name     = "claims_compute_pool"
  cloud            = "AWS"
  region           = var.region
  max_cfu          = 5
  environment {
    id = confluent_environment.flink_claims_engine.id
  }
}

resource "confluent_service_account" "claims-flink-sa" {
  display_name = "claims-flink-sa"
  description  = "Service Account for Claims Flink pool"
}

resource "confluent_role_binding" "claims-flink-sa-role" {
  principal   = "User:${confluent_service_account.claims-flink-sa.id}"
  role_name   = "FlinkAdmin"
  crn_pattern = confluent_environment.flink_claims_engine.resource_name
}










