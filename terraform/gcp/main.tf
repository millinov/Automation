terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = "project-dbbc895c-751b-4d44-899"
  region  = "asia-southeast1"
  zone    = "asia-southeast1-a"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_firewall" "rules" {
  name        = "allow-all"
  network     = google_compute_network.vpc_network.name
  description = "So VM can be accessed by all"

  allow {
   protocol = "tcp"
   ports = ["0-9090"]
  }

  source_ranges = ["0.0.0.0/0"]
 
  target_tags = ["allow-all"]
}

resource "google_compute_disk" "ubuntu_disk" {
  name = "ubuntu-disk"
  type = "pd-balanced"
  size = 20
}

resource "google_compute_disk" "debian_disk" {
  name = "debian-disk"
  type = "pd-balanced"
  size = 20
}

resource "google_compute_attached_disk" "ubuntu_attached" {
  disk     = google_compute_disk.ubuntu_disk.id
  instance = google_compute_instance.vm_instance.id
}

resource "google_compute_attached_disk" "debian_attached" {
  disk     = google_compute_disk.debian_disk.id
  instance = google_compute_instance.debian_instance.id
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-ubuntu"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-minimal-2404-lts-amd64"
      size = 20
      type = "pd-balanced"
    }
  }
  
  allow_stopping_for_update = true 
  tags = ["http-server","https-server","lb-health-check","port-3000-vm","allow-all"]

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}

resource "google_compute_instance" "debian_instance" {
  name         = "terraform-debian"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size = 20
      type = "pd-balanced"
    }
  }

  allow_stopping_for_update = true
  tags = ["http-server","https-server","lb-health-check","port-3000-vm","allow-all"]

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}

output "disk_attached" {
  value = {
    (google_compute_instance.vm_instance.name) = google_compute_attached_disk.ubuntu_attached.disk
    (google_compute_instance.debian_instance.name)  = google_compute_attached_disk.debian_attached.disk
  }
  description = "Check if disk is attached"
}
