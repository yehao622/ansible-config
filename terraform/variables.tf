variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "ansible-linux"
}

variable "region" {
  default = "us-west1"
}

variable "zone" {
  default = "us-west1-b"
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
}
