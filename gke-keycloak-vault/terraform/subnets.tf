resource "google_compute_subnetwork" "public_subnet" {
  name          = "gke-public-subnet"
  ip_cidr_range = "10.10.0.0/16"
  region        = local.region
  network       = google_compute_network.vpc.id
  private_ip_google_access = true
  stack_type = "IPV4_ONLY"
}

resource "google_compute_subnetwork" "private_subnet" {
  name                     = "gke-private-subnet"
  ip_cidr_range            = "10.5.0.0/20"
  region                   = local.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
  stack_type               = "IPV4_ONLY"



  secondary_ip_range {
    range_name    = "pod-ip-range"
    ip_cidr_range = "10.0.0.0/14"
  }

  secondary_ip_range {
    range_name    = "services-ip-range"
    ip_cidr_range = "10.4.0.0/19"
  }
}