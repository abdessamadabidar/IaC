# 1. Egress from pods and nodes to kubelet on nodes
resource "google_compute_firewall" "allow_egress_to_nodes_kubelet" {
  name        = "gke-fw-allow-egress-to-nodes-kubelet"
  network     = google_compute_network.vpc.id
  direction   = "EGRESS"
  priority    = 1000
  description = "Allow egress from pods and nodes to node IPs (kubelet)"

  target_tags = [local.cluster_name]
  
  # Source: pods and nodes can initiate traffic
  source_ranges = [
    google_compute_subnetwork.private_subnet.secondary_ip_range[0].ip_cidr_range,  # Pods
    google_compute_subnetwork.private_subnet.ip_cidr_range                          # Nodes
  ]
  
  # Destination: node IPs (where kubelet runs)
  destination_ranges = [google_compute_subnetwork.private_subnet.ip_cidr_range]

  allow {
    protocol = "tcp"
    ports    = ["10255", "10250"]
  }
}

# 2. Egress from pods to all pod and node IPs
resource "google_compute_firewall" "allow_egress_to_pods_and_nodes_all" {
  name        = "gke-fw-allow-egress-to-pods-and-nodes-all"
  network     = google_compute_network.vpc.id
  direction   = "EGRESS"
  priority    = 1000
  description = "Allow egress from pods to all pod and node IPs"

  target_tags = [local.cluster_name]
  
  # Source: pods can initiate traffic
  source_ranges = [google_compute_subnetwork.private_subnet.secondary_ip_range[0].ip_cidr_range]
  
  # Destination: other pods and nodes
  destination_ranges = [
    google_compute_subnetwork.private_subnet.secondary_ip_range[0].ip_cidr_range,  # Pods
    google_compute_subnetwork.private_subnet.ip_cidr_range                          # Nodes
  ]

  allow {
    protocol = "all"
  }
}

# 3. Egress from nodes to nodes
resource "google_compute_firewall" "allow_egress_nodes_to_nodes_all" {
  name        = "gke-fw-allow-egress-nodes-to-nodes-all"
  network     = google_compute_network.vpc.id
  direction   = "EGRESS"
  priority    = 1000
  description = "Allow egress from all node IPs to all node IPs"

  target_tags = [local.cluster_name]
  
  # Source: nodes
  source_ranges = [google_compute_subnetwork.private_subnet.ip_cidr_range]
  
  # Destination: other nodes
  destination_ranges = [google_compute_subnetwork.private_subnet.ip_cidr_range]

  allow {
    protocol = "all"
  }
}



# 4. Egress to control plane - FIXED
resource "google_compute_firewall" "allow_egress_to_control_plane" {
  name        = "gke-fw-allow-egress-to-control-plane"
  network     = google_compute_network.vpc.id
  direction   = "EGRESS"
  priority    = 1000
  description = "Allow egress from pods and nodes to control plane"

  target_tags = [local.cluster_name]
  
  # Source: pods and nodes
  source_ranges = [
    google_compute_subnetwork.private_subnet.secondary_ip_range[0].ip_cidr_range,  # Pods
    google_compute_subnetwork.private_subnet.ip_cidr_range                          # Nodes
  ]
  
  # Destination: CONTROL PLANE CIDR (must be defined based on your GKE config)
  # Example: if your control plane is in 172.16.0.0/28
  destination_ranges = [google_container_cluster.gke.private_cluster_config[0].master_ipv4_cidr_block] 

  allow {
    protocol = "tcp"
    ports    = ["443", "10250"]  # 443 for K8s API, 10250 for kubelet
  }
}