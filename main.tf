variable "x" {
  default="4"
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "ec2-key-terraform-${var.x}"
  public_key = tls_private_key.example.public_key_openssh
}

resource "local_file" "create-private-key-file" {
  filename = "${path.module}/ec2-key-terraform-${var.x}.pem"
  content  = tls_private_key.example.private_key_pem
}

//security.tf
resource "aws_security_group" "ingress-all-test" {
  name   = "allow-all-sg"
  vpc_id = "vpc-04fa1d91cea29daa0"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  } // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "create-temp-ec2" {
  ami                         = "ami-0745bc24bc4178882"
  instance_type               = "t2.micro"
  subnet_id                   = "subnet-088a8e16a499a5799"
  associate_public_ip_address = true
  security_groups             = ["${aws_security_group.ingress-all-test.id}"]
  
  key_name = "ec2-key-terraform-${var.x}"
  #   --instance-initiated-shutdown-behavior terminate

 tags = {
    Name = "terroform-created-${var.x}"
  }
}

resource "aws_eip" "ip-test-env" {
  instance = "${aws_instance.create-temp-ec2.id}"
  vpc      = true
}