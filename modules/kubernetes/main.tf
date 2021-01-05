/* Retrieve AWS credentials from env variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY */
provider "aws" {
  region = var.region
}

/* Get the VPC ID*/
data "aws_subnet" "cluster_subnet" {
  id = element(var.private_subnets, 0)
}

/*
kubeadm token
 See https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/
*/
resource "random_string" "token_id" {
  length  = 6
  special = false
  upper   = false
}
resource "random_string" "token_secret" {
  length  = 16
  special = false
  upper   = false
}

/* local variables */
locals {
  tags  = merge(var.tags, { "kubernetes.io/cluster" = var.cluster.name })
  token = "${random_string.token_id.result}.${random_string.token_secret.result}"
}

/* IAM */
data "template_file" "control-plane_policy_json" {
  template = file(format("%v/iam/control-plane-policy.json.tpl", path.module))
  vars     = {}
}

resource "aws_iam_policy" "control-plane_policy" {
  name        = format("%v-control-plane", var.cluster.name)
  path        = "/"
  description = "Policy for role ${var.cluster.name}-control-plane"
  policy      = data.template_file.control-plane_policy_json.rendered
}

resource "aws_iam_role" "control-plane_role" {
  name               = format("%v-control-plane", var.cluster.name)
  assume_role_policy = file("${path.module}/iam/assume-role.json")
}

resource "aws_iam_policy_attachment" "control-plane-attach" {
  name       = "control-plane-attachment"
  roles      = [aws_iam_role.control-plane_role.name]
  policy_arn = aws_iam_policy.control-plane_policy.arn
}

resource "aws_iam_instance_profile" "control-plane_profile" {
  name = format("%v-control-plane", var.cluster.name)
  role = aws_iam_role.control-plane_role.name
}

data "template_file" "worker_policy_json" {
  template = file(format("%v/iam/worker-policy.json.tpl", path.module))

  vars = {}
}

resource "aws_iam_policy" "worker_policy" {
  name        = format("%v-worker", var.cluster.name)
  path        = "/"
  description = format("Policy for role %v-worker", var.cluster.name)
  policy      = data.template_file.worker_policy_json.rendered
}

resource "aws_iam_role" "worker_role" {
  name               = format("%v-worker", var.cluster.name)
  assume_role_policy = file("${path.module}/iam/assume-role.json")
}

resource "aws_iam_policy_attachment" "worker-attach" {
  name       = "worker-attachment"
  roles      = [aws_iam_role.worker_role.name]
  policy_arn = aws_iam_policy.worker_policy.arn
}

resource "aws_iam_instance_profile" "worker_profile" {
  name = format("%v-worker", var.cluster.name)
  role = aws_iam_role.worker_role.name
}

# ----------------------------------------
/* EC2 instances */

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"] # AWS account ID of Canonical
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

/* control-plane instance */
data "template_file" "init_control-plane" {
  count    = var.cluster.control_plane.count
  template = file(format("%v/scripts/init_control-plane.sh", path.module))

  vars = {
    region              = var.region
    subnets             = join(" ", var.private_subnets)
    cluster_name        = var.cluster.name
    api_dns             = aws_route53_record.k8s-api.fqdn
    control_plane_index = count.index
    kubeadm_token       = local.token
  }
}

data "template_file" "cloud_init_config" {
  template = file(format("%v/scripts/cloudinit-config.yaml", path.module))
  vars     = {}
}

data "template_cloudinit_config" "control-plane_cloud_init" {
  count         = var.cluster.control_plane.count
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-init-config.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud_init_config.rendered
  }

  part {
    filename     = "init-control-plane.sh"
    content_type = "text/x-shellscript"
    content      = element(data.template_file.init_control-plane.*.rendered, count.index)
  }
}

resource "aws_instance" "control-plane" {
  count         = var.cluster.control_plane.count
  instance_type = var.cluster.control_plane.instance_type
  ami           = data.aws_ami.ubuntu.id
  key_name      = var.keypair_name
  subnet_id     = element(var.private_subnets, count.index)

  vpc_security_group_ids = [
    aws_security_group.kubernetes.id,
  ]

  iam_instance_profile = aws_iam_instance_profile.control-plane_profile.name

  user_data = element(data.template_cloudinit_config.control-plane_cloud_init.*.rendered, count.index)

  tags = merge(
    {
      "Name"                                               = join("-", [var.cluster.name, "control-plane", count.index])
      format("kubernetes.io/cluster/%v", var.cluster.name) = "owned"
    },
    {
      "Role"                                               = join("-", [var.cluster.name, "control-plane"])
      format("kubernetes.io/cluster/%v", var.cluster.name) = "owned"
    },
    var.tags,
  )

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data,
    ]
  }
}

resource "aws_elb_attachment" "k8s-api" {
  count    = var.cluster.control_plane.count
  elb      = aws_elb.k8s-api.id
  instance = element(aws_instance.control-plane.*.id, count.index)
}

data "aws_instances" "control-plane" {
  instance_tags = {
    "Role" = join("-", [var.cluster.name, "control-plane"])
  }

  filter {
    name   = "instance-id"
    values = aws_instance.control-plane.*.id
  }
}

data "aws_instances" "control-plane-0" {
  instance_tags = {
    "Name" = join("-", [var.cluster.name, "control-plane", "0"])
  }

  filter {
    name   = "instance-id"
    values = [aws_instance.control-plane[0].id]
  }
}

resource "aws_elb" "k8s-api" {
  cross_zone_load_balancing = false
  health_check {
    healthy_threshold   = 2
    interval            = 10
    target              = "SSL:6443"
    timeout             = 5
    unhealthy_threshold = 2
  }
  idle_timeout = 300
  listener {
    instance_port      = 6443
    instance_protocol  = "TCP"
    lb_port            = 443
    lb_protocol        = "TCP"
    ssl_certificate_id = ""
  }
  name            = format("%v-k8s-api", var.cluster.name)
  security_groups = [aws_security_group.k8s-api-elb.id]
  subnets         = var.public_subnets
  tags            = var.tags
}

/* worker instances */
data "template_file" "init_worker" {
  template = file("${path.module}/scripts/init_worker.sh")

  vars = {
    kubeadm_token = local.token
    api_dns       = aws_elb.k8s-api.dns_name
  }
}

data "template_cloudinit_config" "worker_cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-init-config.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud_init_config.rendered
  }

  part {
    filename     = "init-worker.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.init_worker.rendered
  }
}

resource "aws_launch_configuration" "worker" {
  name_prefix          = format("%s-worker-", var.cluster.name)
  image_id             = data.aws_ami.ubuntu.id
  instance_type        = var.cluster.worker.instance_type
  key_name             = var.keypair_name
  iam_instance_profile = aws_iam_instance_profile.worker_profile.name

  security_groups = [
    aws_security_group.kubernetes.id,
  ]

  user_data = data.template_cloudinit_config.worker_cloud_init.rendered

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [user_data]
  }
}

resource "aws_autoscaling_group" "worker" {
  vpc_zone_identifier = var.private_subnets

  name                 = format("%s-worker", var.cluster.name)
  max_size             = var.cluster.autoscaling.max
  min_size             = var.cluster.autoscaling.min
  desired_capacity     = var.cluster.autoscaling.min
  launch_configuration = aws_launch_configuration.worker.name

  tags = concat(
    [{
      key                 = "kubernetes.io/cluster/${var.cluster.name}"
      value               = "owned"
      propagate_at_launch = true
      },
      {
        key                 = "Name"
        value               = "${var.cluster.name}-worker"
        propagate_at_launch = true
    }],
    var.cluster.autoscaling.tags,
  )

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# ----------------------------------------
/* Security Groups */

resource "aws_security_group" "kubernetes" {
  vpc_id = data.aws_subnet.cluster_subnet.vpc_id
  name   = var.cluster.name

  tags = local.tags
}

# Allow outgoing connectivity
resource "aws_security_group_rule" "allow_all_outbound_from_kubernetes" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kubernetes.id
}

# Allow SSH connections from given CIDR
resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ingress_cidr.ssh
  security_group_id = aws_security_group.kubernetes.id
}

# Allow API connections only from specific CIDR's
resource "aws_security_group_rule" "allow_api_from_cidr" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ingress_cidr.api
  security_group_id = aws_security_group.kubernetes.id
}

# Allow the security group members to talk with each other without restrictions
resource "aws_security_group_rule" "allow_cluster_internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.kubernetes.id
  security_group_id        = aws_security_group.kubernetes.id
}

resource "aws_security_group" "k8s-api-elb" {
  description = "Security group for the Kubernetes API ELB"
  name        = format("%v-k8s-api-elb", var.cluster.name)
  tags        = var.tags
  vpc_id      = data.aws_subnet.cluster_subnet.vpc_id
}

resource "aws_security_group_rule" "k8s-api-elb-egress" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.k8s-api-elb.id
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "https-elb-to-api" {
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.kubernetes.id
  source_security_group_id = aws_security_group.k8s-api-elb.id
  to_port                  = 6443
  type                     = "ingress"
}

resource "aws_security_group_rule" "https-ingress-to-k8s-api-elb-0-0-0-0--0" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.k8s-api-elb.id
  to_port           = 443
  type              = "ingress"
}

/* DNS record */
data "aws_route53_zone" "k8s_zone" {
  name = format("%s.", var.hosted_zone)
}

resource "aws_route53_record" "k8s-api" {
  alias {
    evaluate_target_health = false
    name                   = aws_elb.k8s-api.dns_name
    zone_id                = aws_elb.k8s-api.zone_id
  }
  name    = format("api-%s.%s", var.cluster.name, var.hosted_zone)
  type    = "A"
  zone_id = data.aws_route53_zone.k8s_zone.zone_id
}

resource "null_resource" "wait_for_kubeadm_cloud_init" {
  connection {
    timeout = "10m"
    host    = aws_instance.control-plane[0].private_ip
    user    = var.ssh_user
    #private_key         = var.ssh_private_key
    bastion_user = var.ssh_user
    bastion_host = var.bastion_host
    #bastion_private_key = var.bastion_private_key
  }
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
  }
}

resource "null_resource" "download_kubeconfig" {
  connection {
    timeout = "10m"
    host    = aws_instance.control-plane[0].private_ip
    user    = var.ssh_user
    #private_key         = var.ssh_private_key
    bastion_user = var.ssh_user
    bastion_host = var.bastion_host
    #bastion_private_key = var.bastion_private_key
  }

  provisioner "local-exec" {
    command = format("scp -J %s@%s %s@%s:/home/ubuntu/admin.conf %s/%s-kubecfg.yaml",
    var.ssh_user, var.bastion_host, var.ssh_user, aws_instance.control-plane[0].private_ip, path.root, var.cluster.name)
  }

  depends_on = [null_resource.wait_for_kubeadm_cloud_init]
}
