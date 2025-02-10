
# Create a local copy of the file, to transfer to Proxmox
resource "local_file" "ubuntu-cloud" {
  # content   = data.template_file.ubuntu-cloud.rendered
  content  = templatefile("${path.module}/cloud-init/pve0.tftpl", { ssh_key = file("~/.ssh/id_ed25519.pub"), hostname = var.vm_hostname0, domain = var.vm_domain, tailscale_auth_key = var.tailscale_auth_key })
  filename = "${path.module}/files/ubuntu-cloud-init.cfg"
}

resource "null_resource" "ubuntu-cloud" {
  depends_on = [local_file.ubuntu-cloud]
  connection {
    type        = "ssh"
    user        = var.pve_user
    private_key = file("~/.ssh/id_ed25519")
    host        = var.pve0_host
  }
  provisioner "file" {
    source      = local_file.ubuntu-cloud.filename
    destination = "/var/lib/vz/snippets/ubuntu-cloud-init.yml"
  }
}
resource "proxmox_vm_qemu" "ubuntu-cloud" {
  depends_on = [
    null_resource.ubuntu-cloud
  ]
  count            = 1
  vmid             = 1001
  name             = "ubuntu"
  desc             = "ubuntu cloud image"
  target_node      = "pve0"
  agent            = 1
  clone            = "ubuntu-cloud0"
  cores            = 1
  cpu_type         = "host"
  memory           = 1024
  scsihw           = "virtio-scsi-single"
  boot             = "order=scsi0"
  hotplug          = "network"
  vm_state         = "running"
  automatic_reboot = true
  cicustom         = "vendor=local:snippets/ubuntu-cloud-init.yml"
  ciupgrade        = true
  ipconfig0        = "ip=192.168.1.11/24,gw=192.168.1.1,ip6=auto"
  ciuser           = var.ci_user
  sshkeys          = var.ssh_keys
  serial {
    id = 0
  }
  vga {
    type = "virtio"
  }
  pcis {
    pci0 {
      mapping {
        mapping_id    = "nvidia"
        pcie          = true
        primary_gpu   = false
        rombar        = true
        device_id     = "2503"
        vendor_id     = "10de"
        sub_device_id = "1377"
        sub_vendor_id = "196e"
      }
    }
  }
  efidisk {
    efitype = "4m"
    storage = "local-zfs"
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
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
  provisioner "local-exec" {
    command = <<EOT
    ssh-keygen -R 192.168.1.11
    ssh-keyscan -H 192.168.1.11 >> ~/.ssh/known_hosts
  EOT
  }

}


# import {
#   to = proxmox_vm_qemu.test
#   id = "pve0/qemu/1002"
# }
# # Create a local copy of the file, to transfer to Proxmox
# resource "local_file" "debian-cloudinit" {
#   # content   = data.template_file.debian-cloudinit.rendered
#   content  = templatefile("${path.module}/cloud-init/pve0.tftpl", { ssh_key = file("~/.ssh/id_ed25519.pub"), hostname = var.vm_hostname1, domain = var.vm_domain, tailscale_auth_key = var.tailscale_auth_key })
#   filename = "${path.module}/files/debian-cloudinit.cfg"
# }

