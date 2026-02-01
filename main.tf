# VPC Security Group
resource "aws_security_group" "dynatrace_sg" {
  name        = "dynatrace-ec2-sg"
  description = "Security group for Dynatrace EC2 instance"

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict to your IP in production
  }

  ingress {
    description = "ActiveGate HTTPS"
    from_port   = 9999
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict to Dynatrace IPs or your network
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dynatrace-sg"
  }
}

# EC2 Instance
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "dynatrace_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type
#  key_name               = var.ec2_key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.dynatrace_activegate_profile.name
  vpc_security_group_ids = [aws_security_group.dynatrace_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Update and install dependencies
    yum update -y
    yum install -y wget unzip jq

    # Install OneAgent (unchanged - this should still work)
    wget -O /tmp/Dynatrace-OneAgent-Linux.sh "${var.dynatrace_env_url}/api/v1/deployment/installer/agent/unix/default/latest?arch=x86" --header="Authorization: Api-Token ${var.dynatrace_oneagent_token}"
    bash /tmp/Dynatrace-OneAgent-Linux.sh --set-app-log-content-access=true --set-host-group="ec2-dynatrace-group"

    # Install Environment ActiveGate - REMOVE the invalid --enable-aws-monitoring
    wget -O /tmp/Dynatrace-ActiveGate-Linux-x86.sh "${var.dynatrace_env_url}/api/v1/deployment/installer/gateway/unix/latest?arch=x86" --header="Authorization: Api-Token ${var.dynatrace_activegate_token}"
    bash /tmp/Dynatrace-ActiveGate-Linux-x86.sh  # No parameters needed for default install

    # Optional: Add custom params if desired (e.g., custom install path, group, network zone)
    # bash /tmp/Dynatrace-ActiveGate-Linux-x86.sh INSTALL=/opt/dynatrace-ag --set-group="aws-monitoring-group" --set-network-zone="aws-zone"

    # Enable and restart services
    systemctl enable oneagent
    systemctl restart oneagent
    systemctl enable dynatracegateway
    systemctl restart dynatracegateway

    # Log completion and status for debugging
    echo "Dynatrace installation complete" > /var/log/dynatrace-install.log
    systemctl status oneagent >> /var/log/dynatrace-install.log
    systemctl status dynatracegateway >> /var/log/dynatrace-install.log
    EOF
  )
  tags = {
    Name = "Dynatrace-EC2-Instance"
  }
}
