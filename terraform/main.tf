terraform {
  backend "gcs" {
    bucket = "ansible-linux-tfstate"
    prefix = "terraform/state"
    credentials = "./terraform-sa-key.json"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
  credentials = file("./terraform-sa-key.json")
}

resource "google_compute_instance" "ansible_vm" {
  name         = "ansible-target"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network       = "default"
    access_config {}   # gives it a public ephemeral IP
  }

  metadata = {
    ssh-keys = "hao:${var.ssh_public_key}"
  }

  tags = ["ansible-target"]
}

# Firewall: allow SSH + Prometheus/Grafana ports
resource "google_compute_firewall" "allow_ssh_monitoring" {
  name    = "allow-ssh-monitoring"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "9090", "3000", "9093", "9100", "3100"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ansible-target"]
}

# Auto-generate inventory.ini for Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    public_ip = google_compute_instance.ansible_vm.network_interface[0].access_config[0].nat_ip
  })
  filename = "../ansible-config/inventory.ini"
}
