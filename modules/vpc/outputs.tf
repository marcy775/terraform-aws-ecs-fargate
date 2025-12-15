output "vpc_id" {
  value = aws_vpc.tf_vpc
}

output "public_subnet_ids" {
  value = aws_subnet.tf_public_subnet[*].id
}