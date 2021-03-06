data "http" "myip" {
  url = "http://ifconfig.co/ip"
}

resource "aws_security_group" "wireguard_sg" {
  name_prefix = "wireguard_sg-"
  description = "Wireguard SG"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
    description = "Permit ingress SSH from deployment IP only"
  }

  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Permit all ingress to Wireguard"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Permit ALL egress"
  }
}

