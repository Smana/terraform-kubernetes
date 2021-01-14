/* Retrieve AWS credentials from env variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY */
provider "aws" {
  region = var.region
}

/* Get the VPC ID*/
data "aws_subnet" "etcd" {
  id = element(var.subnet_ids, 0)
}

resource "random_pet" "prefix" {}

locals {
  prefix = var.name != null ? var.name : random_pet.prefix.id
}

/* IAM */
data "template_file" "etcd_policy_json" {
  template = file(format("%v/iam/etcd-policy.json.tpl", path.module))
  vars     = {}
}

resource "aws_iam_policy" "etcd_policy" {
  name        = format("%v-etcd", local.prefix)
  path        = "/"
  description = "Policy for role ${local.prefix}-etcd"
  policy      = data.template_file.etcd_policy_json.rendered
}

resource "aws_iam_role" "etcd_role" {
  name               = format("%v-etcd", local.prefix)
  assume_role_policy = file("${path.module}/iam/assume-role.json")
}

resource "aws_iam_policy_attachment" "etcd-attach" {
  name       = "etcd-attachment"
  roles      = [aws_iam_role.etcd_role.name]
  policy_arn = aws_iam_policy.etcd_policy.arn
}

resource "aws_iam_instance_profile" "etcd_profile" {
  name = format("%v-etcd", local.prefix)
  role = aws_iam_role.etcd_role.name
}

/* EC2 instances */

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"] # AWS account ID of Canonical
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

data "template_file" "init_etcd" {
  count    = var.members_count
  template = file(format("%v/userdata/init_etcd.sh", path.module))

  vars = {
    etcd_index = count.index
  }
}

data "template_file" "cloud_init_config" {
  template = file(format("%v/userdata/cloudinit-config.yaml", path.module))
  vars     = {}
}

data "template_cloudinit_config" "etcd_cloud_init" {
  count         = var.members_count
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-init-config.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud_init_config.rendered
  }

  part {
    filename     = "init-etcd.sh"
    content_type = "text/x-shellscript"
    content      = element(data.template_file.init_etcd.*.rendered, count.index)
  }
}

resource "aws_instance" "etcd" {
  count         = var.members_count
  instance_type = var.instance_type
  ami           = data.aws_ami.ubuntu.id
  key_name      = var.keypair_name
  subnet_id     = element(var.subnet_ids, count.index)

  vpc_security_group_ids = [
    aws_security_group.etcd.id,
  ]

  iam_instance_profile = aws_iam_instance_profile.etcd_profile.name

  user_data = element(data.template_cloudinit_config.etcd_cloud_init.*.rendered, count.index)

  tags = merge(
    {
      "Name" = join("-", [local.prefix, "etcd", count.index])
    },
    {
      "Role" = join("-", [local.prefix, "etcd"])
    },
    var.tags,
  )

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "20"
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data,
    ]
  }
}

data "aws_instances" "etcd" {
  instance_tags = {
    "Role" = join("-", [local.prefix, "etcd"])
  }

  filter {
    name   = "instance-id"
    values = aws_instance.etcd.*.id
  }
}

/* DNS */
data "aws_route53_zone" "dns_zone" {
  name = format("%s.", var.hosted_zone)
}

resource "aws_route53_record" "etcd" {
  count   = var.members_count
  name    = format("%s-%s-%s", local.prefix, "etcd", count.index)
  type    = "A"
  ttl     = "300"
  records = [element(aws_instance.etcd.*.private_ip, count.index)]
  zone_id = data.aws_route53_zone.dns_zone.zone_id
}
resource "aws_route53_record" "etcd_discovery_ssl" {
  count = var.members_count
  name  = format("_etcd-server-ssl._tcp.%s", var.hosted_zone)
  type  = "SRV"
  ttl   = "300"
  records = concat(
    [
      for i in range(var.members_count) : format("0 0 2379 %s-%s-%s-%s.", local.prefix, "etcd", i, var.hosted_zone)
    ],
    [
      for i in range(var.members_count) : format("0 0 2380 %s-%s-%s-%s.", local.prefix, "etcd", i, var.hosted_zone)
    ]
  )
  zone_id = data.aws_route53_zone.dns_zone.zone_id
}


/* Security groups */

resource "aws_security_group" "etcd" {
  description = "Security group for the etcd cluster"
  name        = format("%v-etcd", local.prefix)
  tags        = var.tags
  vpc_id      = data.aws_subnet.etcd.vpc_id
}

# Allow outgoing connectivity
resource "aws_security_group_rule" "allow_all_outbound_from_instances" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.etcd.id
}

# Allow the security group members to talk with each other without restrictions
resource "aws_security_group_rule" "allow_etcd_internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.etcd.id
  security_group_id        = aws_security_group.etcd.id
}
