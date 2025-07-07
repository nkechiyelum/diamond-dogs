provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Owner       = "Globomantics"
      Project     = var.project
      Environment = var.environment
    }
  }
}


resource "aws_vpc" "diamond_dogs" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.prefix}-vpc-${var.region}-${var.environment}"
    environment = var.environment
  }
}

resource "aws_subnet" "diamond_dogs" {
  vpc_id     = aws_vpc.diamond_dogs.id
  cidr_block = var.subnet_prefix
  availability_zone = "us-east-1b"

  tags = {
    name = "${var.prefix}-subnet-${var.environment}"
  }
}

resource "aws_security_group" "diamond_dogs" {
  name = "${var.prefix}-security-group-${var.environment}"

  vpc_id = aws_vpc.diamond_dogs.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-sg-${var.environment}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_internet_gateway" "diamond_dogs" {
  vpc_id = aws_vpc.diamond_dogs.id

  tags = {
    Name = "${var.prefix}-igw-${var.environment}"
  }
}

resource "aws_route_table" "diamond_dogs" {
  vpc_id = aws_vpc.diamond_dogs.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.diamond_dogs.id
  }

  tags = {
    Name = "${var.prefix}-rt-${var.environment}"
  }
}

resource "aws_route_table_association" "diamond_dogs" {
  subnet_id      = aws_subnet.diamond_dogs.id
  route_table_id = aws_route_table.diamond_dogs.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "diamond_dogs" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.diamond_dogs.id
  vpc_security_group_ids      = [aws_security_group.diamond_dogs.id]

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/files/deploy_app.sh", {
    placeholder = var.placeholder
    width       = var.width
    height      = var.height
    project     = var.project
  })

  tags = {
    Name = "${var.prefix}-diamonddogs-${var.environment}"
    "Name:eni" = "${var.prefix}-eni-${var.environment}" 
  }
}

resource "aws_eip" "diamond_dogs" {
  instance = aws_instance.diamond_dogs.id

  tags = {
     Name = "${var.prefix}-eip-${var.environment}"
  }

}

resource "aws_eip_association" "diamond_dogs" {
  instance_id   = aws_instance.diamond_dogs.id
  allocation_id = aws_eip.diamond_dogs.id

  tags = {
    Name = "${var.prefix}-eip-${var.environment}"
  }
}
