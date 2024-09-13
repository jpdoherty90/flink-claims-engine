variable "sg_package" {
  description = "Stream Governance Package: Advanced or Essentials"
  type        = string
  default     = "ADVANCED"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "rds_instance_class" {
  description = "Amazon RDS (Oracle) instance size"
  type        = string
  default     = "db.m5.large"
}

variable "rds_instance_identifier" {
  description = "Amazon RDS (Oracle) instance identifier"
  type        = string
  default     = "insurnace-customers"
}

variable "rds_username" {
  description = "Amazon RDS (Oracle) master username"
  type        = string
}

variable "rds_password" {
  description = "Amazon RDS (Oracle) database password. You can change it through command line"
  type        = string
}

variable "rds_vpc_cidr" {
  type        = string
  description = "VPC IPv4 CIDR"
  default     = "10.0.0.0/16"
}

variable "rds_subnet_1_cidr" {
  type        = string
  description = "IPv4 CIDR for RDS Oracle subnet 1"
  default     = "10.0.1.0/24"
}

variable "rds_subnet_2_cidr" {
  type        = string
  description = "IPv4 CIDR for  RDS Oracle subnet 2"
  default     = "10.0.2.0/24"
}

variable "kafka_api_key" {
  description = "Kafka cluster API key"
  type        = string
}

variable "kafka_api_secret" {
  description = "Kafka cluster API secret"
  type        = string
}
