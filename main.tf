provider "aws" {
  region = "us-west-2"
}

variable "private_key" {
  description = "SSH private key path"
  type        = string
}

resource "aws_instance" "server" {
  ami                    = "ami-09dd2e08d601bff67"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.server.key_name
  vpc_security_group_ids = [aws_security_group.server.id]
}

resource "aws_key_pair" "server" {
  public_key = file("${var.private_key}.pub")
}

resource "aws_security_group" "server" {
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "connect" {
  value = "ssh -i ${var.private_key} ubuntu@${aws_instance.server.public_ip}"
}
