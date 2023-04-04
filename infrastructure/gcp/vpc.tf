#Google Cloud Virtual Network

variable "network_name" { type = string }
variable "network_subnetwork_name" { type = string }
variable "network_address_name" { type = string }

resource "google_compute_network" "main" {
  name                    = var.network_name
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "main" {
  name          = var.network_subnetwork_name
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.main.id
}

resource "google_compute_address" "main" {
  name = var.network_address_name
}

resource "google_compute_firewall" "ssh" {
  name          = "ssh"
  network       = google_compute_network.main.name
  target_tags   = ["allow-ssh"]
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "http" {
  name          = "http"
  network       = google_compute_network.main.name
  target_tags   = ["allow-http"]
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}
