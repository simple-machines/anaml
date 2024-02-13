module "anaml_all" {
  source = "github.com/simple-machines/anaml-terraform-registry//modules/app-all?ref=v0.44.0"

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

  kubernetes_service_account_annotations = {
    "eks.amazonaws.com/role-arn" = aws_iam_role.anaml-eks-service-account.arn
  }

  override_anaml_spark_server_kubernetes_service_account_spark_driver_executor_annotations = {
    "eks.amazonaws.com/role-arn" = aws_iam_role.anaml-eks-spark-service-account.arn
  }

}

# Allow anaml to use IAM for EKS
# This is useful for attaching S3 bucket access policies to the role
# so Anaml can read/write data
resource "aws_iam_role" "anaml-eks-spark-service-account" {
  name               = "anaml-eks-spark-service-account"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement: [
        {
            Effect: "Allow",
            Principal: {
                "Federated": module.eks.oidc_provider_arn
            },
            Action: "sts:AssumeRoleWithWebIdentity",
            Condition: {
                StringEquals: {
                  "${module.eks.oidc_provider}:sub": "system:serviceaccount:anaml:anaml-spark-executor"
                }
            }
        }
    ]
  })
}

resource "aws_iam_role" "anaml-eks-service-account" {
  name               = "anaml-eks-service-account"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement: [
        {
            Effect: "Allow",
            Principal: {
                "Federated": module.eks.oidc_provider_arn
            },
            Action: "sts:AssumeRoleWithWebIdentity",
            Condition: {
                StringEquals: {
                  "${module.eks.oidc_provider}:sub": "system:serviceaccount:anaml:anaml"
                }
            }
        }
    ]
  })
}
