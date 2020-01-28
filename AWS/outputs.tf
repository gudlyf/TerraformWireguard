output "public_ip" {
  value = "VPN IP Address: ${aws_instance.ec2.public_ip}"
}

