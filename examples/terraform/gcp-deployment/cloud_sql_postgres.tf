resource "google_sql_database_instance" "anaml_postgres_instance" {
  name             = "anaml-postgres"
  region           = var.region
  database_version = "POSTGRES_14"
  settings {
    tier      = "db-custom-1-3840"
    disk_size = 20
    ip_configuration {
      ipv4_enabled    = false
      require_ssl     = true
      private_network = module.vpc.network_id
    }
  }

  project             = var.project_id
  deletion_protection = false

  # Needed for Terraform destroy depedency ordering
  depends_on = [google_service_networking_connection.private_service_connection]
}

resource "google_sql_user" "anaml" {
  project  = var.project_id
  name     = "anaml"
  instance = google_sql_database_instance.anaml_postgres_instance.name
  password = random_password.postgres.result
}

resource "random_password" "postgres" {
  length = 32
}
