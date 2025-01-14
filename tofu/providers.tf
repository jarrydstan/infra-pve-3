terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc6"
    }
  }
}
variable "pm_api_token_secret" {}
variable "pm_api_token_id" {}
variable "tailscale_auth_key" {}
variable "pve_user" {}
variable "pve_password" {}
variable "pve_host" {}
variable "ssh_public_key" {}
variable "ssh_private_key" {}
variable "vm_hostname" {}
variable "vm_domain" {}
variable "ssh_keys" {}
variable "ci_user" {}

provider "proxmox" {
  pm_api_url          = "https://pve2.jarryd.cc:8006/api2/json"
  pm_api_token_secret = var.pm_api_token_secret
  pm_api_token_id     = var.pm_api_token_id
}
