output "nfs_server_private_ip" {
  value       = aws_instance.nfs_server_instance.private_ip
}
