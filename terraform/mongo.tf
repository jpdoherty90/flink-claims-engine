provider "mongodbatlas" {
  public_key  = var.mongodbatlas_public_key
  private_key = var.mongodbatlas_private_key
}

# Create a Project
resource "mongodbatlas_project" "atlas-project" {
  org_id = "<your-org-id>"
  name   = var.mongodbatlas_project_name
}

# Create MongoDB Atlas resources
resource "mongodbatlas_cluster" "flink_claims_engine" {
  project_id = mongodbatlas_project.atlas-project.id
  name       = "flink-claims-engine"

  # Provider Settings "block"
  provider_instance_size_name = "M0"
  provider_name               = "TENANT"
  backing_provider_name       = "AWS"
  provider_region_name        = var.mongodbatlas_region
}

resource "mongodbatlas_project_ip_access_list" "flink_claims_engine-ip" {
  project_id = mongodbatlas_project.atlas-project.id
  cidr_block = "0.0.0.0/0"
  comment    = "Allow connections from anywhere for demo purposes"
}

# Create a MongoDB Atlas Admin Database User
resource "mongodbatlas_database_user" "flink_claims_engine-db-user" {
  username           = var.mongodbatlas_database_username
  password           = var.mongodbatlas_database_password
  project_id         = mongodbatlas_project.atlas-project.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = mongodbatlas_cluster.flink_claims_engine.name
  }
}