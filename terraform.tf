provider "aws" {
  region  = "eu-west-2"
  profile = "personal"
}

resource "aws_vpc" "default" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "default" {
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 3, 1)
  vpc_id            = aws_vpc.default.id
  availability_zone = "eu-west-2a"
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "vps" {

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ingress-all-test.id]
  subnet_id              = aws_subnet.default.id
  key_name               = "Berkeli"

}

resource "aws_security_group" "ingress-all-test" {
  name   = "allow-all-sg"
  vpc_id = aws_vpc.default.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "ip-test-env" {
  instance = aws_instance.vps.id
  vpc      = true
}

resource "aws_internet_gateway" "test-env-gw" {
  vpc_id = aws_vpc.default.id
}


resource "aws_route_table" "route-table-test-env" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test-env-gw.id
  }
}
resource "aws_route_table_association" "subnet-association" {
  subnet_id      = aws_subnet.default.id
  route_table_id = aws_route_table.route-table-test-env.id
}


output "public_dns" {
  value = aws_eip.ip-test-env.public_dns
}
