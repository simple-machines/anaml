module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "9.0.0"
  project_id   = var.project_id
  network_name = "anaml-vpc"

  subnets = [
    {
      subnet_name           = "anaml-01"
      subnet_ip             = "10.0.0.0/20"
      subnet_region         = var.region
      subnet_private_access = true
    }
  ]

  secondary_ranges = {
    "anaml-01" = [
      {
        ip_cidr_range = "10.10.0.0/16"
        range_name    = "anaml-vpc-private-gke-pods"
      },
      {
        ip_cidr_range = "10.20.0.0/16"
        range_name    = "anaml-vpc-private-gke-services"
      },
    ]
  }
}

module "subnets" {
  source       = "terraform-google-modules/network/google//modules/subnets"
  version      = "9.0.0"
  project_id   = var.project_id
  network_name = module.vpc.network_name

  subnets = [
    {
      subnet_name   = "anaml-vpc-proxy-only"
      subnet_ip     = "10.0.16.0/20"
      subnet_region = var.region
      purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
      role          = "ACTIVE"
    }
  ]
}

# # Setup Private IP Range and Private service connection to GCP services
resource "google_compute_global_address" "private_ip_range" {
  name          = "anaml-vpc-private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.vpc.network.network.id
  project       = var.project_id
}

resource "google_compute_address" "ingress_internal_ip" {
  name         = "anaml-vpc-ingress-internal-ip"
  subnetwork   = module.vpc.subnets["${var.region}/anaml-01"].name
  address_type = "INTERNAL"
  project      = var.project_id
  region       = var.region
}

resource "google_service_networking_connection" "private_service_connection" {
  network                 = module.vpc.network.network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}


resource "google_compute_router" "router" {
  name    = "anaml-vpc-router"
  region  = var.region
  network = module.vpc.network_name
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "anaml-vpc-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
