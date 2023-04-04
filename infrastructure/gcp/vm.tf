#Google Compute Engine

variable "instance_name" { type = string }
variable "instance_machine_type" { type = string }
variable "instance_disk_image" { type = string }
variable "instance_disk_size" { type = string }
variable "instance_disk_type" { type = string }
variable "instance_user" { type = string }
variable "instance_ssh_key" { type = any }
variable "instance_ssh_private_key" { type = any }
variable "instance_script" { type = string }

variable "django_secret_key" { type = string }
variable "django_db_name" { type = string }
variable "django_db_user" { type = string }
variable "django_db_password" { type = string }

locals {
  script_name = substr(var.instance_script, -15, -1)
}


resource "google_compute_instance" "main" {
  name         = var.instance_name
  machine_type = var.instance_machine_type
  tags         = ["allow-ssh", "allow-http"]

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.instance_disk_image
      size  = var.instance_disk_size
      type  = var.instance_disk_type
    }
  }

  network_interface {
    network    = google_compute_network.main.name
    subnetwork = google_compute_subnetwork.main.id
    access_config {
      nat_ip = google_compute_address.main.address
    }
  }

  metadata = {
    ssh-keys = "${var.instance_user}:${var.instance_ssh_key}"
  }

  connection {
    type        = "ssh"
    user        = var.instance_user
    host        = self.network_interface.0.access_config.0.nat_ip
    private_key = var.instance_ssh_private_key
  }

  provisioner "file" {
    source      = var.instance_script
    destination = local.script_name
  }

  provisioner "remote-exec" {
    inline = [
      "export DJANGO_SECRET_KEY=${var.django_secret_key}",
      "export DJANGO_DEBUG=False",
      "export POSTGRES_DB=${var.django_db_name}",
      "export POSTGRES_USER=${var.django_db_user}",
      "export POSTGRES_PASSWORD=${var.django_db_password}",
      "export POSTGRES_HOST=localhost",
      "export POSTGRES_PORT=5432",
      "chmod +x ./${local.script_name}",
      "./${local.script_name}",
    ]
  }

}

output "INSTANCE_USER" {
  value = var.instance_user
}

output "INSTANCE_IP" {
  value = google_compute_instance.main.network_interface.0.access_config.0.nat_ip
}

output "INSTANCE_SSH_CONNECT" {
  value = "ssh ${var.instance_user}@${google_compute_instance.main.network_interface.0.access_config.0.nat_ip}"
}
