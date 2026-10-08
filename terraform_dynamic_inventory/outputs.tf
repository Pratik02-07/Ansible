output "instance_details" {
  description = "Details of all EC2 instances"
  value = {
    for name, instance in aws_instance.my_instance : name => {
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
      user       = var.instances[name].user
      os_family  = var.instances[name].os_family
    }
  }
}

output "control_node_public_ip" {
  description = "Public IP of the control node — SSH here to run Ansible"
  value       = one([for name, inst in aws_instance.my_instance : inst.public_ip if can(regex("control", name))])
}

output "inventory_file" {
  description = "Path to the teaching inventory (used from the control node)"
  value       = local_file.ansible_inventory.filename
}
