output "vm_public_ip" {
  value       = google_compute_instance.ansible_vm.network_interface[0].access_config[0].nat_ip
  description = "SSH into: ssh hao@<this IP>"
}
