resource "aws_vpc" "main" {
  cidr_block = var.base_cidr_block

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "publics" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  availability_zone = var.availability_zones[count.index]

  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, length(var.availability_zones), count.index)

  tags = {
    Name = "${var.project_name}-public-subnet-${(count.index + 1)}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${aws_vpc.main.tags["Name"]}-igw"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${aws_vpc.main.tags["Name"]}-public-route-table"
  }
}

resource "aws_route_table_association" "publics" {
  count = length(aws_subnet.publics)

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.publics[count.index].id
}

resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "nodes-security-group"
  }

  ingress {
    description = "Docker"
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "inbounds" {
  security_group_id = aws_security_group.main.id

  count = length(var.forwarded_ports)

  type     = "ingress"
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  to_port   = var.forwarded_ports[count.index]
  from_port = var.forwarded_ports[count.index]
}

resource "aws_key_pair" "main" {
  key_name   = var.key_name
  public_key = file("${var.key_name}.pub")
}
