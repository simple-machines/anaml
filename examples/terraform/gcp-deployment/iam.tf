# Service account for running the Anaml server
# We give each deployment is own service account so we can do fine grained permissions
resource "google_service_account" "anaml" {
  account_id   = "svc-anaml"
  display_name = "Anaml Service Account - ANAML"
  project      = var.project_id
}

# Allow the Kubernetes service account to impersonate the Google service account.
# https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#authenticating_to
resource "google_service_account_iam_member" "anaml_svc_workload_identity" {
  service_account_id = google_service_account.anaml.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${module.anaml_all.kubernetes_namespace}/${module.anaml_all.kubernetes_service_account}]"
}

resource "google_service_account_iam_member" "anaml_executor_svc_workload_identity" {
  service_account_id = google_service_account.anaml.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${module.anaml_all.kubernetes_namespace}/${module.anaml_all.kubernetes_service_account_spark_executor_driver}]"
}

# Grant the anaml services access to cloud-sql
resource "google_project_iam_member" "anaml_svc_cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.anaml.email}"
}
