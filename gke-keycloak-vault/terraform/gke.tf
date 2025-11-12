resource "google_container_cluster" "gke" {
    name = "gke-keycloack-vault-cluster"
    location = local.zone_id
    remove_default_node_pool = true
    initial_node_count = 1
    network = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.private_subnet.self_link
    networking_mode = "VPC_NATIVE"


    deletion_protection = false


    default_max_pods_per_node = 20

    ip_allocation_policy {
      cluster_secondary_range_name = google_compute_subnetwork.private_subnet.secondary_ip_range[0].range_name
      services_secondary_range_name = google_compute_subnetwork.private_subnet.secondary_ip_range[1].range_name
    }

    private_cluster_config {
      enable_private_nodes = true
      enable_private_endpoint = false
      master_ipv4_cidr_block = "172.16.0.0/28"
    }

  
}