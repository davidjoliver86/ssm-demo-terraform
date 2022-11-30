locals {
  azs = ["us-east-1a", "us-east-1b"]
}

resource "aws_vpc" "this" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = var.default_tags
}

resource "aws_subnet" "public" {
  for_each          = var.subnets.public
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(var.default_tags, {
    Name = "ssm-demo-public-${each.key}"
    type = "public"
  })
}

resource "aws_subnet" "private" {
  for_each          = var.subnets.private
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(var.default_tags, {
    Name = "ssm-demo-private-${each.key}"
    type = "private"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = var.default_tags
}

resource "aws_eip" "nat" {
  for_each = toset(local.azs)
  vpc      = true
  tags = merge(var.default_tags, {
    Name = "ssm-demo-${each.key}"
    az   = each.key
  })
}

resource "aws_nat_gateway" "this" {
  for_each      = toset(local.azs)
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.default_tags, {
    Name = "ssm-demo-${each.key}"
    az   = each.key
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.default_tags, {
    Name = "ssm-demo-public"
    type = "public"
  })
}

resource "aws_route_table" "private" {
  for_each = toset(local.azs)
  vpc_id   = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[each.key].id
  }

  tags = merge(var.default_tags, {
    Name = "ssm-demo-private-${each.key}"
    type = "private"
    az   = each.key
  })
}

resource "aws_route_table_association" "public" {
  for_each       = toset(local.azs)
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each       = toset(local.azs)
  route_table_id = aws_route_table.private[each.key].id
  subnet_id      = aws_subnet.private[each.key].id
}

# Endpoints for SSM

# resource "aws_vpc_endpoint" "interfaces" {
#   for_each          = toset(["ssm", "ec2messages", "ec2", "ssmmessages", "kms", "logs"])
#   vpc_id            = aws_vpc.this.id
#   service_name      = "com.amazonaws.us-east-1.${each.key}"
#   subnet_ids        = [for subnet in aws_subnet.private : subnet.id]
#   vpc_endpoint_type = "Interface"
# }

# resource "aws_vpc_endpoint" "gateway" {
#   vpc_id            = aws_vpc.this.id
#   service_name      = "com.amazonaws.us-east-1.s3"
#   vpc_endpoint_type = "Gateway"
# }
