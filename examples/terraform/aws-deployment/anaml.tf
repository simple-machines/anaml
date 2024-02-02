module "anaml_all" {
  source = "github.com/simple-machines/anaml-terraform-registry//modules/app-all?ref=0eea3600887822b66fed13c0cff7a8f3913185f7"

  anaml_admin_email    = var.initial_admin_email
  anaml_admin_password = var.initial_admin_password
  anaml_version        = "v1.15.0"

  container_registry = "australia-southeast1-docker.pkg.dev/anaml-public-artifacts/docker"

  # Form Login
  enable_form_client = true

  # Configure Kubernetes ingress to use AWS ALB so we can access anaml-ui from a browser
  kubernetes_ingress_enable = true
  kubernetes_ingress_annotations = {
    "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
    "alb.ingress.kubernetes.io/target-type" = "ip"
    "kubernetes.io/ingress.class"           = "alb"
  }

  kubernetes_namespace_create                 = true
  kubernetes_namespace_name                   = "anaml"
  kubernetes_pod_node_selector_app            = { node_pool = "anaml-app-pool" }
  kubernetes_pod_node_selector_spark_driver   = { node_pool = "anaml-spark-pool" }
  kubernetes_pod_node_selector_spark_executor = { node_pool = "anaml-spark-pool" }

  # We use an external RDS database instead of deploying a Postgres instance inside EKS
  kubernetes_service_enable_postgres = false

  # This basic deploy does not have SSL configured for brevity
  # We need to disable the hsts header and secure cookie flag
  override_anaml_server_enable_secure_cookies = false
  override_anaml_server_enable_hsts           = false

  override_anaml_spark_server_kubernetes_service_account_spark_driver_executor_create = true
  override_anaml_spark_server_kubernetes_service_account_spark_driver_executor        = "anaml-spark-executor"

  postgres_password                         = random_password.anaml-postgres-password.result
  postgres_user                             = aws_db_instance.anaml-postgres.username
  postgres_host                             = aws_db_instance.anaml-postgres.address
  override_anaml_server_anaml_database_name = aws_db_instance.anaml-postgres.db_name

  # If you have a licence key, uncomment the below with the value
  # license_key = "example"

  # Create a Kubernetes service account for anaml
  kubernetes_service_account_create = true
  kubernetes_service_account_name   = "anaml"
}
