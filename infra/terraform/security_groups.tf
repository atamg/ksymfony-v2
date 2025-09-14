resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-sg"
  description = "Web ingress; full egress"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.open_http_80 ? [1] : []
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    }
  }
  dynamic "ingress" {
    for_each = var.open_https_443 ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All egress"
  }

  tags = { Name="${var.project_name}-sg", Project=var.project_name }
}

resource "aws_security_group" "ssh_ci" {
  name        = "${var.project_name}-ssh-ci"
  description = "Ephemeral SSH from GitHub Actions runner"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle { ignore_changes = [ingress] }
  tags = { Name="${var.project_name}-ssh-ci", Project=var.project_name }
}

resource "aws_security_group" "ssh_static" {
  count       = length(var.user_allowed_ip_list) > 0 ? 1 : 0
  name        = "${var.project_name}-ssh-static"
  description = "Static SSH allow-list"
  vpc_id      = var.vpc_id

  # one ingress rule per CIDR
  dynamic "ingress" {
    for_each = var.user_allowed_ip_list
    content {
      description = "Static SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # egress open (same as others)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ssh-static", Project = var.project_name }
}

output "security_group_id" { value = aws_security_group.app_sg.id }
output "ssh_ci_sg_id"      { value = aws_security_group.ssh_ci.id }
