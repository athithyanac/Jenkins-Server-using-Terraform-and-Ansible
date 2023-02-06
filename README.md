# Prerequisite

* Need AWS CLI access
* Terraform need to be installed. Click to download [Terraform](https://www.terraform.io/downloads "Terraform").

# Features

* Easy to customise and use.
* Tfvars file to modify variables.

## provider.tf
```terraform
provider "aws" {
  region = var.region
}
```
## variables.tf
```terraform
variable "region" {}
variable "type" {}
variable "ami" {}
variable "user" {}
variable "filename" {}  
variable "project" {}
```
## variables.tfvars
```terraform
region        = "ap-south-1"
ami           = "ami-01a4f99c4ac11b03c"
type          = "t2.micro"
user          = "ec2-user"
filename      = "main.yml"
project       = "tera-ans"
```
## datasource.tf
```terraform
data "aws_vpc" "vpc" {
  state = "available"
}
```
## output.tf
```terraform

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
```
## main.tf

### INSTANCE
```terraform
resource "aws_instance" "instance" {
  ami                    = var.ami
  instance_type          = var.type
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name = aws_key_pair.key.id
  tags = {
    Name = "${var.project}"
  }
```
`file provisoner for copying ansible playbook from local machine to remote machine`
```terraform
  provisioner "file" {
    source = "${var.filename}"
    destination = "/home/${var.user}/${var.filename}"
  }
```
  `remote-exec provisoner for executing ansible playbook in remote server created`
```terraform
  provisioner "remote-exec" {
    inline = [
      "sleep 60",
      "ansible-playbook /home/${var.user}/${var.filename}",
    ]
  }
```
`connection for connecting to remote server`
```terraform
  connection {
    type        = "ssh"
    user        = "${var.user}"
    private_key = file("keypair")
    host        = self.public_ip
  }

  user_data = file("userdata.sh")
  
}
```
### KEYPAIR
```terraform
resource "aws_key_pair" "key" {
  key_name   = "Master Key"
  public_key = file("keypair.pub")
  tags = {
    Name = "${var.project}-key"
  }
}
```
### Security Group
```terraform
resource "aws_security_group" "sg" {
  name        = "Allow SSH & Jenkins"
  description = "allow SSH & Jenkins"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description = "SSH Traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Jenkins Traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    # Necessary if changing 'name' or 'name_prefix' properties.
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project}-sg"
  }
}
```
## main.yml
```yaml
---
- name: "Install Jenkins, Java and Python"
  become: true
  hosts: localhost
  vars:
    - packages:
        - jenkins
        - python3
        
  tasks:

    - name: "Adding Jenkins repository key"
      rpm_key:
        key: https://pkg.jenkins.io/redhat-stable/jenkins.io.key
        state: present

    - name: "Adding Jenkins repository"
      yum_repository:
        name: jenkins
        description: jenkins stable
        baseurl: https://pkg.jenkins.io/redhat-stable
        state: present

    - name: "Updating"
      yum:
        name: yum
        state: latest

    - name: "Installing Jenkins"
      yum:
        name: "{{packages}}"
        state: present

    - name: "Install Java"
      shell: amazon-linux-extras install java-openjdk11 -y

    - name: "Start Jenkins"
      service:
        name: jenkins
        state: started
        enabled: yes
```