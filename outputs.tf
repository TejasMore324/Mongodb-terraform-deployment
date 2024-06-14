# outputs.tf

output "jumpbox_public_ip" {
  value = aws_instance.jumpbox.public_ip
}

output "mongodb_private_ips" {
  value = aws_instance.mongodb[*].private_ip
}

output "vpc_id" {
  value = aws_vpc.main.id
}
