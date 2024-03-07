module "anaml_all" {
  source = "github.com/simple-machines/anaml-terraform-registry//modules/app-all?ref=v0.47.1"

  anaml_admin_email    = var.initial_admin_email
  anaml_admin_password = var.initial_admin_password
  anaml_version        = "v1.15.0"

  container_registry = "australia-southeast1-docker.pkg.dev/anaml-public-artifacts/docker"

  # Form Login
  enable_form_client = true

  # Configure Kubernetes ingress to use AWS ALB so we can access anaml-ui from a browser
  kubernetes_ingress_enable      = true
  kubernetes_ingress_annotations = {}

  kubernetes_namespace_create                 = true
  kubernetes_namespace_name                   = "anaml"
  kubernetes_pod_node_selector_app            = { node_pool = "anaml-app-pool" }
  kubernetes_pod_node_selector_spark_driver   = { node_pool = "spark-driver" }
  kubernetes_pod_node_selector_spark_executor = { node_pool = "spark-exec" }

  # We use an external RDS database instead of deploying a Postgres instance inside EKS
  kubernetes_service_enable_postgres = false

  # This basic deploy does not have SSL configured for brevity
  # We need to disable the hsts header and secure cookie flag
  override_anaml_server_enable_secure_cookies = false
  override_anaml_server_enable_hsts           = false

  override_anaml_spark_server_kubernetes_service_account_spark_driver_executor_create = true
  override_anaml_spark_server_kubernetes_service_account_spark_driver_executor        = "anaml-spark-executor"

  # Integrate with GKE
  kubernetes_service_annotations_anaml_docs = {
    "cloud.google.com/neg" : jsonencode({ "ingress" : true }),
  }

  # Integrate with GKE
  kubernetes_service_annotations_anaml_server = {
    "cloud.google.com/neg" : jsonencode({ "ingress" : true }),
    "cloud.google.com/backend-config": jsonencode({"default": "anaml-backendconfig"})
  }

  # Integrate with GKE
  kubernetes_service_annotations_anaml_ui = {
    "cloud.google.com/neg" : jsonencode({ "ingress" : true }),
  }

  # Integrate with GKE
  kubernetes_service_annotations_spark_history_service = {
    "cloud.google.com/neg" : jsonencode({ "ingress" : true }),
  }

  kubernetes_pod_anaml_server_sidecars = [{
    name  = "cloudsql-proxy",
    image = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.1.2"
    command = [
      "/cloud-sql-proxy",
      "--port=5432",
      "--private-ip",
      google_sql_database_instance.anaml_postgres_instance.connection_name
    ]
    security_context = {
      run_as_non_root = true
    }
    port = {
      container_port = 5432
    }
  }]

  postgres_password                         = google_sql_user.anaml.password
  postgres_user                             = google_sql_user.anaml.name
  postgres_host                             = "localhost"
  override_anaml_server_anaml_database_name = "postgres"

  # If you have a licence key, uncomment the below with the value
  # license_key = "example"

  # Create a Kubernetes service account for anaml
  kubernetes_service_account_create = true

  kubernetes_service_account_annotations = {
    "iam.gke.io/gcp-service-account" = "${google_service_account.anaml.email}"
  }

  override_anaml_spark_server_kubernetes_service_account_spark_driver_executor_annotations = {
    "iam.gke.io/gcp-service-account" = "${google_service_account.anaml.email}"
  }

}
