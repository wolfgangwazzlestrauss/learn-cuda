provider "aws" {
  region = "us-west-2"
}

variable "private_key" {
  description = "SSH private key path"
  type        = string
}

resource "aws_instance" "server" {
  ami                    = "ami-07dd19a7900a1f049"
  instance_type = "t2.micro"
#   instance_type          = "g4dn.xlarge"
  key_name               = aws_key_pair.server.key_name
  vpc_security_group_ids = [aws_security_group.server.id]

  connection {
    host        = self.public_ip
    port        = 22
    private_key = file(var.private_key)
    type        = "ssh"
    user        = "ubuntu"
  }

  provisioner "local-exec" {
    command = <<EOF
    sleep 60
    echo "[python]\n${aws_instance.server.public_ip}" > python/inventory
	ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
        -i python/inventory \
        -u ubuntu \
        --private-key ${var.private_key} \
        python/playbook.yaml
    EOF
  }
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

output "address" {
  value = aws_instance.server.public_ip
}

output "connect" {
  value = "ssh -i ${var.private_key} ubuntu@${aws_instance.server.public_ip}"
}

output "private_key" {
  value = var.private_key
}

