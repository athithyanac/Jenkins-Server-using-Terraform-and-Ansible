#INSTANCE
resource "aws_instance" "instance" {
  ami                    = var.ami
  instance_type          = var.type
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name = aws_key_pair.key.id
  tags = {
    Name = "${var.project}"
  }
  provisioner "file" {
    source = "${var.filename}"
    destination = "/home/${var.user}/${var.filename}"
  }
  provisioner "remote-exec" {
    inline = [
      "sleep 60",
      "ansible-playbook /home/${var.user}/${var.filename}",
    ]
  }
  connection {
    type        = "ssh"
    user        = "${var.user}"
    private_key = file("keypair")
    host        = self.public_ip
  }

  user_data = file("userdata.sh")
  
}
#KEYPAIR
resource "aws_key_pair" "key" {
  key_name   = "Master Key"
  public_key = file("keypair.pub")
  tags = {
    Name = "${var.project}-key"
  }
}
#SG
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