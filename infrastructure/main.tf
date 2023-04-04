terraform {
  required_version = "1.3.1"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.43.1"
    }
  }
  backend "gcs" {}
}

locals { project_name = "apache-gcp-django" }

variable "gcp" {
  type    = map(string)
  default = {
    project     = ""
    region      = ""
    zone        = ""
    credentials = ""
  }
}

provider "google" {
  project     = var.gcp.project
  region      = var.gcp.region
  zone        = var.gcp.zone
  credentials = var.gcp.credentials
}

variable "django" {
  type    = map(string)
  default = {
    secret_key  = ""
    db_name     = ""
    db_user     = ""
    db_password = ""
  }
}

module "gcp" {
  source = "./gcp"

  instance_name            = "${local.project_name}-instance"
  instance_machine_type    = "e2-micro"
  instance_disk_image      = "ubuntu-os-cloud/ubuntu-2004-lts"
  instance_disk_size       = "10"
  instance_disk_type       = "pd-ssd"
  instance_user            = "${local.project_name}_user"
  instance_ssh_key         = file("${path.module}/.ssh/id_rsa.pub")
  instance_ssh_private_key = file("${path.module}/.ssh/id_rsa")
  instance_script          = "./scripts/nginx_deploy.sh"

  django_secret_key  = var.django.secret_key
  django_db_name     = var.django.db_name
  django_db_user     = var.django.db_user
  django_db_password = var.django.db_password

  network_name            = "${local.project_name}-network"
  network_address_name    = "${local.project_name}-network-address"
  network_subnetwork_name = "${local.project_name}-network-subnetwork"

}

output "gcp" {
  value     = module.gcp
  sensitive = true
}
