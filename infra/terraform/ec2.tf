data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags = { Project = var.project_name }
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_pull" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-profile"
  role = aws_iam_role.ec2_role.name
}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

resource "aws_cloudwatch_log_group" "docker" {
  name              = "${var.project_name}-docker"
  retention_in_days = var.cw_logs_retention_days
}

resource "aws_iam_role_policy_attachment" "ec2_cw_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = compact([
  aws_security_group.app_sg.id,
  aws_security_group.ssh_ci.id,
  try(aws_security_group.ssh_static[0].id, null)
  ])
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  key_name                    = var.key_pair_name

  metadata_options { 
    http_endpoint="enabled" 
    http_tokens="required" 
    }

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    # Update & install Docker + CloudWatch Agent
    (yum update -y || dnf update -y)
    (yum install -y docker awscli amazon-cloudwatch-agent || dnf install -y docker awscli amazon-cloudwatch-agent)
    systemctl enable --now docker
    usermod -aG docker ec2-user

    # Compose v2 plugin
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -sSL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
      -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    # CloudWatch Agent config
    mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'JSON'
    {
      "logs": { "logs_collected": { "files": { "collect_list": [
        {
          "file_path": "/var/lib/docker/containers/*/*-json.log",
          "log_group_name": "${aws_cloudwatch_log_group.docker.name}",
          "log_stream_name": "{instance_id}"
        }
      ] } } }
    }
    JSON
    systemctl enable amazon-cloudwatch-agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

    # App workspace
    mkdir -p /opt/app
    chown -R ec2-user:ec2-user /opt/app
    # --- Add extra SSH public keys for ec2-user (idempotent append) ---
    install -d -m 700 /home/ec2-user/.ssh
    touch /home/ec2-user/.ssh/authorized_keys
    chown -R ec2-user:ec2-user /home/ec2-user/.ssh
    chmod 600 /home/ec2-user/.ssh/authorized_keys

    cat > /tmp/extra_keys <<'KEYS'
    ${join("\n", var.extra_ssh_public_keys)}
    KEYS

    awk 'NF && $0 !~ /^#/' /tmp/extra_keys | while read -r key; do
      grep -qxF "$key" /home/ec2-user/.ssh/authorized_keys || echo "$key" >> /home/ec2-user/.ssh/authorized_keys
    done
    rm -f /tmp/extra_keys
    # --- end keys block ---
  EOF

  tags = { Name = var.project_name, Project = var.project_name }
}

output "ec2_public_dns"   { value = aws_instance.app.public_dns }
output "ec2_public_ip"    { value = aws_instance.app.public_ip }
output "ec2_instance_id"  { value = aws_instance.app.id }
