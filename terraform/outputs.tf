output "oracle_endpoint" {
  value     = aws_db_instance.insurance-customers
  sensitive = true
}

output "mongodbatlas_connection_string" {
  description = "Connection string for MongoDB Atlas database to be used in Confluent Cloud connector"
  value       = mongodbatlas_cluster.flink_claims_engine.connection_strings[0].standard_srv
}