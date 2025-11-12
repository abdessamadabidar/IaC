resource "google_compute_network" "vpc" {
  name                            = "main"
  routing_mode                    = "REGIONAL"
  auto_create_subnetworks         = false

  depends_on = [ google_project_service.api ]
}
