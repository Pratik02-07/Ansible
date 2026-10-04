#Outputs for count

# # Output instance ID    
# output "instance_id" {
#   value = aws_instance.my_instance[*].id
# }

# # Output instance arn 
# output "ec2_arn" {
#   description = "ARN of the EC2 instance"
#   value       = aws_instance.my_instance[*].arn
# }

# # Output instance public IP 
# output "ec2_public_ip" {
#   description = "Public IP address of the EC2 instance"
#   value       = aws_instance.my_instance[*].public_ip
# }

# # Output instance public DNS 
# output "ec2_public_dns" {
#   description = "Public DNS name of the EC2 instance"
#   value       = aws_instance.my_instance[*].public_dns
# }

# # Output instance private IP 
# output "ec2_private_ip" {
#   description = "Public IP address of the EC2 instance"
#   value       = aws_instance.my_instance[*].private_ip
# }

# output "ec2_public_dns" {
#   description = "Public DNS name of the EC2 instance"
#   value       = aws_instance.my_instance[*].public_dns
# }



#Outputs for for_each

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = [for instance in aws_instance.my_instance : instance.public_ip]
}
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = [for instance in aws_instance.my_instance : instance.id]
}
output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = [for instance in aws_instance.my_instance : instance.public_dns]
}
output "ec2_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = [for instance in aws_instance.my_instance : instance.private_ip]
}
output "ec2_arn" {
  description = "ARN of the EC2 instance"
  value       = [for instance in aws_instance.my_instance : instance.arn]
}