output "oracle_endpoint" {
  value     = aws_db_instance.insurance-customers
  sensitive = true
}
