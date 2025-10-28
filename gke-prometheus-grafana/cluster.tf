provider "google" {
  project = "gke-prometheus-grafana-476414"
  region = "europe-west4"
}
resource "google_compute_network" "default" {
  name                     = "example-network"
  auto_create_subnetworks  = false
}

resource "google_compute_subnetwork" "default" {
  name          = "example-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  region        = "europe-west4"


  network = google_compute_network.default.id
  
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.0.0/24"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.1.0/24"
  }
}

resource "google_container_cluster" "default" {
  name     = "example-standard-cluster"
  location = "europe-west4-a"

  network    = google_compute_network.default.id
  subnetwork = google_compute_subnetwork.default.id

  ip_allocation_policy {
    services_secondary_range_name = google_compute_subnetwork.default.secondary_ip_range[0].range_name
    cluster_secondary_range_name  = google_compute_subnetwork.default.secondary_ip_range[1].range_name
  }

  deletion_protection = false
  initial_node_count  = 1

  node_config {
    preemptible  = true
    machine_type = "e2-small"
    disk_size_gb = 30
    disk_type    = "pd-standard"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
