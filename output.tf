
output "vpcid" {
  value = data.aws_vpc.vpc.id
}
output "instance_public_ip" {
  value = resource.aws_instance.instance.public_ip
}
output "instance_dns" {
  value = resource.aws_instance.instance.public_dns
}
output "security_group" {
  value = resource.aws_security_group.sg
}
output "key_name" {
  value = resource.aws_key_pair.key
}
