provider "aws" {
  region = "eu-west-3"
  access_key = var.access_key
  secret_key = var.secret_key
}


variable "access_key" {}
variable "secret_key" {}
variable "vpc_cidr" {}
variable "private_cidrs" {}
variable "public_cidrs" {}

# Virtual Private Cloud
resource "aws_vpc" "eks-vpc" {
  cidr_block = var.vpc_cidr


  tags = {
    "Name" = "ECOMM_VPC"
    "Terraform" = "true"
    "Environment" = "true"
    "kubernetes.io/cluster/ecomm-eks-cluster" = "shared"
  }

  enable_dns_hostnames = true
}

# Internet Gateway
resource "aws_internet_gateway" "eks-igw" {
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    "Name" = "ECOMM_IGW"
  }
}

# Private subnet 01
resource "aws_subnet" "private-sub-eu-west-3a" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = var.private_cidrs[0]

  availability_zone = "eu-west-3a"
  
  tags = {
    "Name" = "private-eu-west-3a"
    "kubernetes.io/cluster/ecomm-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb" = 1

  }
}

# Private subnet 02
resource "aws_subnet" "private-sub-eu-west-3b" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = var.private_cidrs[1]

  availability_zone = "eu-west-3b"
  
  tags = {
    "Name" = "private-eu-west-3b"
    "kubernetes.io/cluster/ecomm-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb" = 1

  }
}

# Private subnet 03
resource "aws_subnet" "private-sub-eu-west-3c" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = var.private_cidrs[2]

  availability_zone = "eu-west-3c"
  
  tags = {
    "Name" = "private-eu-west-3c"
    "kubernetes.io/cluster/ecomm-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb" = 1

  }
}



# Public subnet 01
resource "aws_subnet" "public-sub-eu-west-3a" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = var.public_cidrs[0]

  availability_zone = "eu-west-3a"
  
  tags = {
    "Name" = "public-eu-west-3a"
    "kubernetes.io/cluster/ecomm-eks-cluster" = "shared"
    "kubernetes.io/role/elb" = 1

  }
}


# Public subnet 02
resource "aws_subnet" "public-sub-eu-west-3b" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = var.public_cidrs[1]

  availability_zone = "eu-west-3b"
  
  tags = {
    "Name" = "public-eu-west-3b"
    "kubernetes.io/cluster/ecomm-eks-cluster" = "shared"
    "kubernetes.io/role/elb" = 1

  }
}

# Public subnet 03
resource "aws_subnet" "public-sub-eu-west-3c" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = var.public_cidrs[2]

  availability_zone = "eu-west-3c"
  
  tags = {
    "Name" = "public-eu-west-3c"
    "kubernetes.io/cluster/ecomm-eks-cluster" = "shared"
    "kubernetes.io/role/elb" = 1

  }
}

# Elastic IP
resource "aws_eip" "eks-eip" {
  domain   = "vpc"

  tags = {
    "Name" = "ECOMM_EIP"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "eks-nat-gw" {
  allocation_id = aws_eip.eks-eip.id
  subnet_id     = aws_subnet.public-sub-eu-west-3a.id

  tags = {
    Name = "ECOMM_NAT_GW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.eks-igw]
}


# Private route table
resource "aws_route_table" "eks-private-rtb" {
  vpc_id = aws_vpc.eks-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks-nat-gw.id
  }

  tags = {
    "Name" = "ECOMM_PRIVATE_RT"
  }
}

# Public route table
resource "aws_route_table" "eks-public-rtb" {
  vpc_id = aws_vpc.eks-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-igw.id
  }

  tags = {
    "Name" = "ECOMM_PUBLIC_RT"
  }
}

# Create an association between private route tables and private subnets
resource "aws_route_table_association" "private-rtb-eu-west-3a-assoc" {
  subnet_id      = aws_subnet.private-sub-eu-west-3a.id
  route_table_id = aws_route_table.eks-private-rtb.id
}

resource "aws_route_table_association" "private-rtb-eu-west-3b-assoc" {
  subnet_id      = aws_subnet.private-sub-eu-west-3b.id
  route_table_id = aws_route_table.eks-private-rtb.id
}

resource "aws_route_table_association" "private-rtb-eu-west-3c-assoc" {
  subnet_id      = aws_subnet.private-sub-eu-west-3c.id
  route_table_id = aws_route_table.eks-private-rtb.id
}

# Create an association between public route tables and public subnets
resource "aws_route_table_association" "public-rtb-eu-west-3a-assoc" {
  subnet_id      = aws_subnet.public-sub-eu-west-3a.id
  route_table_id = aws_route_table.eks-public-rtb.id
}

resource "aws_route_table_association" "public-rtb-eu-west-3b-assoc" {
  subnet_id      = aws_subnet.public-sub-eu-west-3b.id
  route_table_id = aws_route_table.eks-public-rtb.id
}

resource "aws_route_table_association" "public-rtb-eu-west-3c-assoc" {
  subnet_id      = aws_subnet.public-sub-eu-west-3c.id
  route_table_id = aws_route_table.eks-public-rtb.id
}



# Create EKS Cluster

# Create IAM role for eks cluster
resource "aws_iam_role" "eks-cluster-iam-role" {
  name = "eks_cluster_iam_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    "Name" = "ECOMM EKS IAM Role"
  }
}

# Attach Policy to EKS cluster IAM role
resource "aws_iam_role_policy_attachment" "eks-policy-AmazonEKSClusterPolic" {
  role       = aws_iam_role.eks-cluster-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create EKS cluster
resource "aws_eks_cluster" "eks-cluster" {
  name = "eks_cluster"

  access_config {
    bootstrap_cluster_creator_admin_permissions = true
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.eks-cluster-iam-role.arn
  version  = "1.33"

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true

    subnet_ids = [
      aws_subnet.private-sub-eu-west-3a.id,
      aws_subnet.private-sub-eu-west-3b.id,
      aws_subnet.private-sub-eu-west-3c.id,
      aws_subnet.public-sub-eu-west-3a.id,
      aws_subnet.public-sub-eu-west-3b.id,
      aws_subnet.public-sub-eu-west-3c.id
    ]
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks-policy-AmazonEKSClusterPolic,
  ]
}

# Create IAM role for eks node group
resource "aws_iam_role" "eks-node-group-iam-role" {
  name = "eks_node_group_iam_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    "Name" = "ECOMM EKS Node Group IAM Role"
  }
}

# Attach Policies to EKS node group IAM role
resource "aws_iam_role_policy_attachment" "eks-policy-AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks-node-group-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks-policy-AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks-node-group-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks-policy-AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks-node-group-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Create EKS node group
resource "aws_eks_node_group" "eks-node-group" {
  cluster_name    = aws_eks_cluster.eks-cluster.name
  node_group_name = "eks_nodes"
  node_role_arn   = aws_iam_role.eks-node-group-iam-role.arn
  subnet_ids      = [
    aws_subnet.private-sub-eu-west-3a.id,
    aws_subnet.private-sub-eu-west-3b.id,
    aws_subnet.private-sub-eu-west-3c.id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
  
  # capacity_type = "ON_DEMAND"
  instance_types = ["t3.medium"]


  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-policy-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-policy-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-policy-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    "Name" = "ECOMM EKS Node Group"
  }
}