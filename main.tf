resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "ec2-key-terraform-${var.x}"
  public_key = tls_private_key.example.public_key_openssh
}

resource "local_file" "private-key-file" {
  filename = "${path.module}/ec2-key-terraform-${var.x}.pem"
  content  = tls_private_key.example.private_key_pem
}

//security.tf
resource "aws_security_group" "public-ec2-sg" {
  name   = "allow-all-public-sg"
  vpc_id = var.vpc_id

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  } // Terraform removes the default rule

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    description = "Allow ping from 1.2.3.4"
  }

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

resource "aws_security_group" "private-ec2-sg" {
  name   = "allow-ping-private-sg"
  vpc_id = var.vpc_id

  ingress {
    cidr_blocks = ["192.168.0.0/24"]
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    description = "allow ping"
  }

  ingress {
    cidr_blocks = ["192.168.0.0/24"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "allow ping"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "public-ec2" {
  ami                         = "ami-04d9e855d716f9c99"
  instance_type               = "t2.micro"
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  security_groups = [
    "${aws_security_group.public-ec2-sg.id}",
    "${aws_security_group.public-ec2-sg.id}"
  ]

  key_name = "ec2-key-terraform-${var.x}"
  #   --instance-initiated-shutdown-behavior terminate

  provisioner "local-exec" {
    command = <<EOT
      rm -f ~/_Development/access_keys/ec2-key-terraform-${var.x}.pem
      cp ${path.module}/ec2-key-terraform-${var.x}.pem ~/_Development/access_keys
      chmod 400 ${path.module}/ec2-key-terraform-${var.x}.pem
    EOT
  }

  provisioner "file" {
    source      = "${path.module}/ec2-key-terraform-${var.x}.pem"
    destination = "/home/ubuntu/ec2-key-terraform-${var.x}.pem"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.example.private_key_pem
    }
  }

  depends_on = [local_file.private-key-file]

  tags = {
    Name = "cxy-terraform-vpc-public-ec2-${var.x}"
  }
}

resource "aws_instance" "private-ec2-1" {
  ami           = "ami-04d9e855d716f9c99"
  instance_type = "t2.micro"
  subnet_id     = var.private_subnet_id_1
  # associate_public_ip_address = true
  security_groups = ["${aws_security_group.private-ec2-sg.id}"]

  key_name = "ec2-key-terraform-${var.x}"
  #   --instance-initiated-shutdown-behavior terminate

  tags = {
    Name = "cxy-terraform-vpc-private-ec2-${var.x}"
  }
}

resource "aws_instance" "private-ec2-2" {
  ami           = "ami-04d9e855d716f9c99"
  instance_type = "t2.micro"
  subnet_id     = var.private_subnet_id_2
  # associate_public_ip_address = true
  security_groups = ["${aws_security_group.private-ec2-sg.id}"]

  key_name = "ec2-key-terraform-${var.x}"
  #   --instance-initiated-shutdown-behavior terminate

  tags = {
    Name = "cxy-terraform-vpc-private-ec2-${var.x}"
  }
}

resource "aws_eip" "ip-test-env" {
  instance = aws_instance.public-ec2.id
  vpc      = true
}
