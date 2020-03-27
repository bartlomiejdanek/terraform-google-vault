#
# Copyright 2019 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# This file contains the actual Vault server definitions
#

resource "google_compute_address" "vault" {
  project = var.project_id

  name   = "vault-lb"
  region = var.region

  depends_on = [google_project_service.service]
}

resource "google_compute_firewall" "vault" {
  name    = "vault-firewall"
  network = "default"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["8200", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vault"]
}

resource "google_compute_instance" "vault" {
  project      = var.project_id
  name         = "vault"
  machine_type = var.vault_machine_type
  zone         = var.zone

  tags = ["vault"]

  boot_disk {
    initialize_params {
      image = var.vault_instance_base_image
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.vault.address
    }
  }
  metadata = merge(
    var.vault_instance_metadata,
    {
      "google-compute-enable-virtio-rng" = "true"
      "startup-script"                   = data.template_file.vault-startup-script.rendered
    },
  )

  # metadata_startup_script = "echo hi > /test.txt"

  service_account {
    email  = google_service_account.vault-admin.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
