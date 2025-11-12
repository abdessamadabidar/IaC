resource "google_service_account" "gke" {
  account_id   = "gke-cluster-nodes"
  display_name = "GKE Cluster Nodes Service Account"
}

resource "google_container_node_pool" "node-pool" {
  name = "gke-keycloak-vault-node-pool"
  cluster = google_container_cluster.gke.id

  autoscaling {
    min_node_count = 1
    max_node_count = 4
  }


  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = true
    machine_type = "e2-medium"
    disk_size_gb = 30
    disk_type    = "pd-standard"
    
    service_account = google_service_account.gke.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

}