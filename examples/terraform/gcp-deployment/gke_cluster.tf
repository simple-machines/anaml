data "google_client_config" "default" {}

module "gke_cluster" {
  source                  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                 = "30.0.0"
  project_id              = var.project_id
  name                    = "anaml-cluster"
  region                  = var.region
  zones                   = var.zones
  network                 = module.vpc.network_name
  subnetwork              = "anaml-01"
  ip_range_pods           = "anaml-vpc-private-gke-pods"
  ip_range_services       = "anaml-vpc-private-gke-services"
  enable_private_endpoint = false
  enable_private_nodes    = true
  master_ipv4_cidr_block  = "10.1.0.0/28"

  node_pools = [
    {
      # Anaml-server should be run with multiple replicas in production for
      # redundancy, and to allow rolling upgrades.
      name               = "anaml-app-pool"
      machine_type       = "e2-highmem-2"
      image_type         = "COS_CONTAINERD"
      enable_secure_boot = true
      node_locations     = join(",", var.zones)
      autoscaling        = true
      min_count          = 1
      max_count          = 3
      node_count         = 1
      disk_size_gb       = 100
      max_pods_per_node  = 110
    },
    {
      name               = "spark-driver"
      machine_type       = "e2-standard-4"
      image_type         = "COS_CONTAINERD"
      enable_secure_boot = true
      spot               = false
      node_locations     = join(",", var.zones)
      autoscaling        = true
      min_count          = 0
      max_count          = 15
      node_count         = 0
      disk_size_gb       = 100
      disk_type          = "pd-balanced"
      local_ssd_count    = 0
    },
    {
      name               = "spark-exec"
      machine_type       = "e2-standard-16"
      image_type         = "COS_CONTAINERD"
      enable_secure_boot = true
      spot               = true
      node_locations     = join(",", var.zones)
      autoscaling        = true
      min_count          = 0
      max_count          = 15
      node_count         = 0
      disk_size_gb       = 500
      disk_type          = "pd-balanced"
      local_ssd_count    = 0
    }
  ]
  node_pools_taints = {
    spark-driver = [
      {
        key    = "spark-only"
        value  = "true"
        effect = "NO_SCHEDULE"
      },
    ],
    spark-exec = [
      {
        key    = "spark-only"
        value  = "true"
        effect = "NO_SCHEDULE"
      },
    ]
  }

  deletion_protection = false


  # Needed for Terraform destroy depedency ordering
  depends_on = [google_service_networking_connection.private_service_connection]
}

# Increase ingress timeouts to allow for web socket connections
resource "kubernetes_manifest" "backend_config" {
  manifest = {
    "apiVersion" = "cloud.google.com/v1"
    "kind"       = "BackendConfig"
    "metadata" = {
      "name"      = "anaml-backendconfig"
      "namespace" = "anaml"
    }
    "spec" = {
      "timeoutSec" = 1600
    }
  }
}
