
resource "null_resource" "cloud_init_vm-terraform-test" {
  connection {
    type    = "ssh"
    user    = var.pve_user
    private_key = file("~/.ssh/id_ed25519")
    host    = var.pve_host
  } 
  provisioner "file" {
    source       = local_file.cloud_init_vm-terraform-test.filename
    destination  = "/var/lib/vz/snippets/cloud_init_vm-terraform-test.yml"
  }
}

# Create a local copy of the file, to transfer to Proxmox
resource "local_file" "cloud_init_vm-terraform-test" {
  # content   = data.template_file.cloud_init_vm-terraform-test.rendered
  content   = templatefile("${path.module}/cloud-init/pve2.tftpl", {ssh_key = file("~/.ssh/id_ed25519.pub"), hostname = var.vm_hostname, domain = var.vm_domain, tailscale_auth_key = var.tailscale_auth_key})
  filename  = "${path.module}/files/user_data_cloud_init_vm-terraform-test.cfg"
}
resource "proxmox_vm_qemu" "vm-terraform-test" {
    depends_on = [
    null_resource.cloud_init_vm-terraform-test
  ]
  count            = 1
  vmid             = 201
  name             = "vm-terraform-test"
  desc             = "terraform test"
  target_node      = "pve2"
  agent            = 1
  clone            = "ubuntu-cloud"
  cores            = 2
  cpu_type         = "host"
  memory           = 4096
  scsihw           = "virtio-scsi-single"
  boot             = "order=scsi0"
  hotplug          = "network"
  vm_state         = "running"
  automatic_reboot = true
  cicustom         = "vendor=local:snippets/cloud_init_vm-terraform-test.yml"
  ciupgrade        = true
  ipconfig0        = "ip=192.168.1.10/24,gw=192.168.1.1,ip6=auto"
  ciuser           = var.ci_user
  sshkeys          = var.ssh_keys
  serial {
    id = 0
  }
  disks {
    ide {
      ide2 {
        cloudinit {
          storage = "local-zfs"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          storage    = "local-zfs"
          size       = "50G"
          emulatessd = true
          iothread   = true
        }
      }
    }
  }
  network {
    id = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
  provisioner "local-exec" {
  command = <<EOT
    ssh-keygen -R 192.168.1.10
    ssh-keyscan -H 192.168.1.10 >> ~/.ssh/known_hosts
  EOT
  }

}
