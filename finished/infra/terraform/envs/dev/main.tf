data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.project}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project}-igw" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true

  tags = { Name = "${var.project}-public" }
}

# ----------------------------
# NEW: 2nd public subnet (public_b) in another AZ
# ----------------------------
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_b_cidr # NEW var
  availability_zone       = var.az_b                 # NEW var
  map_public_ip_on_launch = true

  tags = { Name = "${var.project}-public-b" } # NEW tag name
}


resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = false

  tags = { Name = "${var.project}-private" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project}-rt-public" }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# NAT (single) - biggest cost item, but required for private EC2 to pull deps/build images
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.project}-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  tags          = { Name = "${var.project}-nat" }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project}-rt-private" }
}

resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# SSH key for both instances
resource "aws_key_pair" "this" {
  key_name   = "${var.project}-key"
  public_key = file(var.ssh_public_key_path)
}

# Security Groups
resource "aws_security_group" "bastion" {
  name        = "${var.project}-sg-bastion"
  description = "SSH only from my IP"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-sg-bastion" }
}

resource "aws_security_group" "app" {
  name        = "${var.project}-sg-app"
  description = "App in private subnet. SSH only from bastion."
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "SSH from bastion SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # For now allow HTTP only from bastion (later we'll switch to ALB SG)
  # ingress {
  #   description     = "HTTP from bastion SG (temporary)"
  #   from_port       = 80
  #   to_port         = 80
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.bastion.id]
  # }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-sg-app" }
}

# Minimal IAM for SSM (useful later even if we deploy via SSH)
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_ssm_role" {
  name               = "${var.project}-ec2-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# EC2 Bastion (public)
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type_bastion
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  tags = { Name = "${var.project}-bastion" }
}

# EC2 App (private) - will run FE+BE+DB+Nginx via docker compose
resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type_app
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = aws_key_pair.this.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
  #!/bin/bash
  set -euo pipefail

  SWAP_GB=2
  SWAPFILE=/swapfile

  if ! swapon --show | awk '{print $1}' | grep -qx "$${SWAPFILE}"; then
    if [ ! -f "$${SWAPFILE}" ]; then
      fallocate -l "$${SWAP_GB}G" "$${SWAPFILE}" || dd if=/dev/zero of="$${SWAPFILE}" bs=1M count=$((SWAP_GB*1024))
      chmod 600 "$${SWAPFILE}"
      mkswap "$${SWAPFILE}"
    fi

    swapon "$${SWAPFILE}"

    if ! grep -qE "^$${SWAPFILE}\\s" /etc/fstab; then
      echo "$${SWAPFILE} none swap sw 0 0" >> /etc/fstab
    fi
  fi

  sysctl -w vm.swappiness=10
  if ! grep -q "^vm.swappiness" /etc/sysctl.conf; then
    echo "vm.swappiness=10" >> /etc/sysctl.conf
  else
    sed -i 's/^vm\.swappiness=.*/vm.swappiness=10/' /etc/sysctl.conf
  fi
EOF



  tags = { Name = "${var.project}-app" }
}
