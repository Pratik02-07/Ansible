# key pair 
resource "aws_key_pair" "my_key" {
  key_name   = "terra-key-ec2"
  public_key = file("terra-key-ec2.pub")
}

# vpc & security group
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

# security group (Crucial: Port 22 is open for Ansible SSH connection)
resource "aws_security_group" "my_security_group" {
  name        = "automate-sg"
  description = "Allow SSH and HTTP, this will add a TF generated security group."
  vpc_id      = aws_default_vpc.default.id

  # inbound rules - ingress
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For production, restrict this to your Control Node IP
    description = "Allow SSH from anywhere"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  # outbound rules - egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all traffic access from anywhere open outbounds"
  }
}

# ec2 instance
resource "aws_instance" "my_instance" {
  # FIXED: Restored the for_each block to match the naming convention tags below
  for_each = tomap({
    "automate-micro" = "t3.micro"
  })

  depends_on = [aws_security_group.my_security_group, aws_key_pair.my_key]

  ami                    = var.ec2_ami_id
  instance_type          = each.value     
  key_name               = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [aws_security_group.my_security_group.id]

  # REMOVED: user_data script removed so Ansible can handle configuration management instead!

  root_block_device {
    volume_size = var.env == "prod" ? 15 : var.ec2_default_root_storage_size
    volume_type = var.ec2_root_storage_type
  }

  tags = {
    Name = "Terraform-EC2-${each.key}"
  }
}

# ADDED: Output the Public IP so you can easily drop it into your Ansible inventory
output "ec2_public_ips" {
  value       = { for k, v in aws_instance.my_instance : k => v.public_ip }
  description = "The public IP addresses of the deployed EC2 instances"
}
