module "label" {
  source    = "cloudposse/label/terraform"
  version   = "v0.5.1"
  namespace = var.namespace
  stage     = var.stage
  name      = "etcd"
  tags      = var.tags
}

/* Retrieve AWS credentials from env variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY */
provider "aws" {
  region = var.region
}

/* Get the VPC ID*/
data "aws_subnet" "etcd" {
  id = element(var.subnet_ids, 0)
}

/* IAM */
data "template_file" "etcd_policy_json" {
  template = file(format("%v/iam/etcd-policy.json.tpl", path.module))
  vars     = {}
}

resource "aws_iam_policy" "etcd_policy" {
  name        = module.label.id
  path        = "/"
  description = "Policy for role etcd"
  policy      = data.template_file.etcd_policy_json.rendered
}

resource "aws_iam_role" "etcd_role" {
  name               = module.label.id
  assume_role_policy = file("${path.module}/iam/assume-role.json")
}

resource "aws_iam_policy_attachment" "etcd-attach" {
  name       = module.label.id
  roles      = [aws_iam_role.etcd_role.name]
  policy_arn = aws_iam_policy.etcd_policy.arn
}

resource "aws_iam_instance_profile" "etcd_profile" {
  name = module.label.id
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
    etcd_index         = count.index
    domain_name        = var.hosted_zone
    namespace          = module.label.namespace
    member_name        = format("member-%s", count.index)
    member_domain_name = format("%s-%s-%s.%s", module.label.namespace, module.label.name, count.index, var.hosted_zone)
  }
}

data "template_file" "cloud_init_config" {
  count    = var.members_count
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
    content      = element(data.template_file.cloud_init_config.*.rendered, count.index)
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
      "Name" = join("-", [module.label.id, count.index])
    },
    {
      "Role" = module.label.id
    },
    module.label.tags,
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
    "Role" = module.label.id
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
  name    = format("%s-%s-%s.%s.", module.label.namespace, module.label.name, count.index, var.hosted_zone)
  type    = "A"
  ttl     = "300"
  records = [element(aws_instance.etcd.*.private_ip, count.index)]
  zone_id = data.aws_route53_zone.dns_zone.zone_id
}
resource "aws_route53_record" "etcd_discovery_ssl_server" {
  name = format("_etcd-server-ssl._tcp.%s", var.hosted_zone)
  type = "SRV"
  ttl  = "300"
  records = [
    for i in range(var.members_count) : format("0 0 2380 %s-%s-%s.%s.", module.label.namespace, module.label.name, i, var.hosted_zone)
  ]
  zone_id = data.aws_route53_zone.dns_zone.zone_id
}

resource "aws_route53_record" "etcd_discovery_ssl_client" {
  name = format("_etcd-client-ssl._tcp.%s", var.hosted_zone)
  type = "SRV"
  ttl  = "300"
  records = [
    for i in range(var.members_count) : format("0 0 2379 %s-%s-%s.%s.", module.label.namespace, module.label.name, i, var.hosted_zone)
  ]
  zone_id = data.aws_route53_zone.dns_zone.zone_id
}


resource "null_resource" "write_tls" {
  count = var.members_count
  connection {
    timeout      = "10m"
    host         = element(aws_instance.etcd.*.private_ip, count.index)
    user         = var.ssh_user
    bastion_user = var.ssh_user
    bastion_host = var.bastion_host
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/etcd/tls",
      format("sudo chown -R %s. /etc/etcd", var.ssh_user)
    ]
  }

  provisioner "file" {
    content     = module.tls.tls_certs[format("%s-%s-%s.%s", module.label.namespace, module.label.name, count.index, var.hosted_zone)]
    destination = "/etc/etcd/tls/tls.pem"
  }
  provisioner "file" {
    content     = module.tls.tls_keys[format("%s-%s-%s.%s", module.label.namespace, module.label.name, count.index, var.hosted_zone)]
    destination = "/etc/etcd/tls/tls.key"
  }
  provisioner "file" {
    content     = module.tls.ca_cert_pem
    destination = "/etc/etcd/tls/ca.pem"
  }
}


/* Security groups */

resource "aws_security_group" "etcd" {
  description = "Security group for the etcd cluster"
  name        = module.label.id
  tags        = module.label.tags
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

# Allow SSH connections from given CIDR
resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
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

# Allow clients from given CIDR to access to etcd
resource "aws_security_group_rule" "ingress_etcd" {
  type              = "ingress"
  from_port         = 2379
  to_port           = 2380
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ingress_cidr
  security_group_id = aws_security_group.etcd.id
}
