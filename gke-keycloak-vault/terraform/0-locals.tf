locals {
  project_id = "gke-keycloak-vault"
  region = "europe-west4"
  zone_id = "europe-west4-a"
  cluster_name = "gke-keycloack-vault-cluster"
  apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "logging.googleapis.com",
  ]
}