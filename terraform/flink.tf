
resource "confluent_flink_compute_pool" "claims_compute_pool" {
  display_name = "claims_compute_pool"
  cloud        = "AWS"
  region       = var.region
  max_cfu      = 10
  environment {
    id = confluent_environment.flink_claims_engine.id
  }
}
