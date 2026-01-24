resource "aws_network_acl" "allow_all" {
  vpc_id = aws_vpc.this.id

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "allow-all-nacl"
  }
}

resource "aws_network_acl_association" "private" {
  network_acl_id = aws_network_acl.allow_all.id
  subnet_id      = aws_subnet.private.id
}

resource "aws_network_acl_association" "public_a" {
  network_acl_id = aws_network_acl.allow_all.id
  subnet_id      = aws_subnet.public_a.id
}

resource "aws_network_acl_association" "public_b" {
  network_acl_id = aws_network_acl.allow_all.id
  subnet_id      = aws_subnet.public_b.id
}

