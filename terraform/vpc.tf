# ============================================================================
# VPC.TF — Your private network in AWS
# ============================================================================
# Creates: VPC, Public Subnets, Private Subnets, Internet Gateway,
#          NAT Gateway, Route Tables
#
# Architecture:
#   Internet → Internet Gateway → Public Subnets (ALB, NAT GW)
#                                      │
#                                 NAT Gateway
#                                      │
#                                Private Subnets (EKS Nodes — SECURE!)
# ============================================================================

# Get available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  cluster_name = "${var.project_name}-${var.environment}"
  azs          = slice(data.aws_availability_zones.available.names, 0, 3)
}

# ── The VPC (Your Private Network) ──
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true    # Pods get DNS names
  enable_dns_support   = true    # DNS resolution works

  tags = {
    Name        = "${local.cluster_name}-vpc"
    Environment = var.environment
  }
}

# ── Public Subnets (for ALB and NAT Gateway) ──
resource "aws_subnet" "public" {
  count = 3

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true     # Resources here get public IPs

  tags = {
    Name                                          = "${local.cluster_name}-public-${local.azs[count.index]}"
    "kubernetes.io/role/elb"                       = "1"    # Tells K8s: create ALB here
    "kubernetes.io/cluster/${local.cluster_name}"  = "shared"
  }
}

# ── Private Subnets (for EKS Nodes — NOT exposed to internet) ──
resource "aws_subnet" "private" {
  count = 3

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name                                          = "${local.cluster_name}-private-${local.azs[count.index]}"
    "kubernetes.io/role/internal-elb"              = "1"    # For internal load balancers
    "kubernetes.io/cluster/${local.cluster_name}"  = "shared"
  }
}

# ── Internet Gateway (Front door to the internet) ──
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.cluster_name}-igw"
  }
}

# ── Elastic IP for NAT Gateway ──
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.cluster_name}-nat-eip"
  }
}

# ── NAT Gateway (lets private subnets reach internet ONE WAY) ──
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id    # NAT lives in public subnet

  tags = {
    Name = "${local.cluster_name}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# ── Route Table: Public (traffic goes to Internet Gateway) ──
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                    # All internet traffic
    gateway_id = aws_internet_gateway.main.id    # Goes through IGW
  }

  tags = {
    Name = "${local.cluster_name}-public-rt"
  }
}

# ── Route Table: Private (traffic goes to NAT Gateway) ──
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"                # All internet traffic
    nat_gateway_id = aws_nat_gateway.main.id     # Goes through NAT (one-way!)
  }

  tags = {
    Name = "${local.cluster_name}-private-rt"
  }
}

# ── Associate Public Subnets with Public Route Table ──
resource "aws_route_table_association" "public" {
  count = 3

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ── Associate Private Subnets with Private Route Table ──
resource "aws_route_table_association" "private" {
  count = 3

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
