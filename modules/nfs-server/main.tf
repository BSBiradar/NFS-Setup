resource "aws_security_group" "nfs_server_sg" {
  name        = "${var.project}-nfs-server-sg"
  description = "allow NFS and SSH"
  vpc_id      = var.vpc_id
  ingress {
    cidr_blocks = [var.vpc_cidr]
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
    Name = "${var.project}-nfs-server-sg"
    env  = var.env
  }
}

resource "aws_instance" "nfs_server_instance" {
  ami                    = var.image_id
  instance_type          = var.instance_type
  key_name               = var.key_pair
  vpc_security_group_ids = [aws_security_group.nfs_server_sg.id]

  tags = {
    Name = "${var.project}-server-instance"
    env  = var.env
  }

  subnet_id = var.private_subnet_id

  user_data = <<-EOF
              #!/bin/bash
              set -e

              yum install -y nfs-utils

              systemctl start nfs-server
              systemctl enable nfs-server

              yum install -y firewalld

              sudo systemctl start firewalld
              sudo systemctl enable firewalld

              firewall-cmd --add-port=2049/tcp --permanent
              firewall-cmd --add-service=nfs --permanent

              firewall-cmd --reload

              mkdir -p /srv/nfs/share
              chmod -R 777 /srv/nfs/share

              echo "/srv/nfs/share *(rw,sync,no_subtree_check)" >> /etc/exports

              exportfs -ra

              systemctl restart nfs-server

              systemctl status nfs-server
              EOF

}
