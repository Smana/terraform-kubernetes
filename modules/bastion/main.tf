/* Retrieve AWS credentials from env variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY */
provider "aws" {
  region = var.region
}

# Find VPC details based on bastion subnets
data "aws_subnet" "bastion_subnet" {
  id = element(var.subnet_ids, 0)
}

resource "random_pet" "prefix" {}

locals {
  prefix = var.name != null ? var.name : random_pet.prefix.id
}

data "template_file" "bastion_policy_json" {
  template = file(format("%v/iam/bastion-policy.json.tpl", path.module))
  vars     = {}
}

resource "aws_iam_policy" "bastion_policy" {
  name        = format("%v-bastion", local.prefix)
  path        = "/"
  description = "Policy for role ${local.prefix}-bastion"
  policy      = data.template_file.bastion_policy_json.rendered
}

resource "aws_iam_role" "bastion_role" {
  name               = "bastion"
  assume_role_policy = file("${path.module}/iam/assume-role.json")
}

resource "aws_iam_policy_attachment" "bastion-attach" {
  name       = "bastion-attachment"
  roles      = [aws_iam_role.bastion_role.name]
  policy_arn = aws_iam_policy.bastion_policy.arn
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = format("%v-bastion", local.prefix)
  role = aws_iam_role.bastion_role.name
}

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"] # AWS account ID of Canonical
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

/* Bastion */
data "template_file" "cloud_init_config" {
  template = file(format("%v/scripts/cloudinit-config.yaml", path.module))
  vars     = {}
}

data "template_file" "init_bastion" {
  template = file(format("%v/scripts/init_bastion.sh", path.module))

  vars = {}
}

data "template_cloudinit_config" "bastion_cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-init-config.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud_init_config.rendered
  }

  part {
    filename     = "init-bastion.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.init_bastion.rendered
  }
}

resource "aws_launch_configuration" "bastion" {
  name_prefix          = format("%v-bastion", local.prefix)
  image_id             = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  key_name             = var.keypair_name
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name

  security_groups = [
    aws_security_group.bastion.id,
  ]

  user_data = data.template_cloudinit_config.bastion_cloud_init.rendered

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "20"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [user_data]
  }
}

resource "aws_autoscaling_group" "bastion" {
  vpc_zone_identifier = var.subnet_ids

  name                 = format("%v-bastion", local.prefix)
  max_size             = var.autoscaling.max
  min_size             = var.autoscaling.min
  desired_capacity     = var.autoscaling.min
  launch_configuration = aws_launch_configuration.bastion.name

  tags = concat(
    [
      {
        key                 = "Name"
        value               = format("%v-bastion", local.prefix)
        propagate_at_launch = true
    }],
    var.autoscaling.tags,
  )

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_autoscaling_attachment" "bastion" {
  autoscaling_group_name = aws_autoscaling_group.bastion.id
  elb                    = aws_elb.bastion.id
}

resource "aws_elb" "bastion" {
  health_check {
    healthy_threshold   = 2
    interval            = 10
    target              = "TCP:22"
    timeout             = 5
    unhealthy_threshold = 2
  }
  idle_timeout = 300
  listener {
    instance_port      = 22
    instance_protocol  = "TCP"
    lb_port            = 22
    lb_protocol        = "TCP"
    ssl_certificate_id = ""
  }
  name            = format("%v-bastion", local.prefix)
  security_groups = [aws_security_group.bastion-elb.id]
  subnets         = var.subnet_ids
  tags            = var.tags
}

resource "aws_security_group" "bastion-elb" {
  description = "Security group for bastion ELB"
  name        = format("%v-bastion-elb", local.prefix)
  tags        = var.tags
  vpc_id      = data.aws_subnet.bastion_subnet.vpc_id
}

resource "aws_security_group" "bastion" {
  description = "Security group for bastion"
  name        = format("%v-bastion", local.prefix)
  tags        = var.tags
  vpc_id      = data.aws_subnet.bastion_subnet.vpc_id
}

resource "aws_security_group" "private_instances_security_group" {
  description = "Enable SSH access to the Private instances from the bastion via SSH port"
  name        = format("%v-priv-instances", local.prefix)
  vpc_id      = data.aws_subnet.bastion_subnet.vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "bastion-egress" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.bastion.id
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "bastion-elb-egress" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.bastion-elb.id
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "ssh-elb-to-bastion" {
  from_port                = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.bastion.id
  source_security_group_id = aws_security_group.bastion-elb.id
  to_port                  = 22
  type                     = "ingress"
}

resource "aws_security_group_rule" "ssh-external-to-bastion-elb-0-0-0-0--0" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.bastion-elb.id
  to_port           = 22
  type              = "ingress"
}

resource "aws_security_group_rule" "bastion-to-cluster-ssh" {
  from_port                = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private_instances_security_group.id
  source_security_group_id = aws_security_group.bastion.id
  to_port                  = 22
  type                     = "ingress"
}

/* DNS record */
data "aws_route53_zone" "bastion_zone" {
  name = format("%s.", var.hosted_zone)
}

resource "aws_route53_record" "bastion" {
  alias {
    evaluate_target_health = false
    name                   = aws_elb.bastion.dns_name
    zone_id                = aws_elb.bastion.zone_id
  }
  name    = format("%s-bastion.%s", local.prefix, var.hosted_zone)
  type    = "A"
  zone_id = data.aws_route53_zone.bastion_zone.zone_id
}
