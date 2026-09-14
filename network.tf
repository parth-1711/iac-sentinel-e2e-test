# --- Remediated: SSH restricted to the internal VPC CIDR instead of 0.0.0.0/0 ---
resource "aws_security_group" "app_ssh" {
  name        = "app-ssh-sg"
  description = "Allows SSH access to application servers"
  vpc_id      = "vpc-0123456789abcdef0"

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "iac-sentinel-demo"
  }
}

resource "aws_security_group_rule" "ssh_from_anywhere" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.app_ssh.id
}

# --- Violates: security/open_security_groups (inline ingress block) ---
# --- Violates: governance/naming_conventions (uppercase + space in SG name) ---
resource "aws_security_group" "mgmt_sg" {
  name        = "Public SG"
  description = "Legacy management security group with inline ingress"
  vpc_id      = "vpc-0123456789abcdef0"

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "iac-sentinel-demo"
  }
}
