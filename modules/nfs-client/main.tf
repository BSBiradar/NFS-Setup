resource "aws_security_group" "nfs_client_sg" {
  name        = "${var.project}-nfs-client-sg"
  description = "allow NFS and SSH"
  vpc_id      = var.vpc_id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "TCP"
    from_port   = 22
    to_port     = 22
  }

  ingress {
    cidr_blocks = [var.vpc_cidr]
    protocol    = "TCP"
    from_port   = 2049
    to_port     = 2049
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = {
    Name = "${var.project}-nfs-client-sg"
    env  = var.env
  }
}

resource "aws_instance" "nfs_client_instance" {
  ami                    = var.image_id
  instance_type          = var.instance_type
  key_name               = var.key_pair
  vpc_security_group_ids = [aws_security_group.nfs_client_sg.id]

  tags = {
    Name = "${var.project}-client-instance"
    env  = var.env
  }

  subnet_id = var.public_subnet_id

  user_data = <<-EOF
              #!/bin/bash
              set -e

              yum install -y nfs-utils

              yum install -y firewalld

              sudo systemctl start firewalld
              sudo systemctl enable firewalld

              firewall-cmd --add-port=2049/tcp --permanent
              firewall-cmd --add-service=nfs --permanent

              firewall-cmd --reload

              mkdir -p /mnt/nfs/share

              mount -t nfs4 ${var.nfs_server_private_ip}:/srv/nfs/share /mnt/nfs/share

              echo "${var.nfs_server_private_ip}:/srv/nfs/share /mnt/nfs/share nfs4 defaults 0 0" >> /etc/fstab

              mount -a

              systemctl status nfs-utils
              EOF

}