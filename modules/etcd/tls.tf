module "tls" {
  source = "./modules/tls"

  label = {
    name      = "etcd"
    namespace = var.namespace
    stage     = var.stage
  }

  bucket_name = "tlsstore"

  ca = {
    common_name           = var.tls.ca_common_name
    organization          = var.tls.ca_organization
    validity_period_hours = var.tls.ca_validity_period_hours
    early_renewal_hours   = var.tls.ca_early_renewal_hours
  }

  certs = concat([
    for i in range(var.members_count) :
    {
      common_name  = format("%s-%s-%s.%s", module.label.namespace, module.label.name, i, var.hosted_zone)
      ip_addresses = [element(aws_instance.etcd.*.private_ip, i)]
      uris         = []
      dns_names = [
        var.hosted_zone,
        format("%s-%s-%s", module.label.namespace, module.label.name, var.hosted_zone),
        format("%s-%s-%s.%s", module.label.namespace, module.label.name, i, var.hosted_zone)
      ]
      allowed_uses          = ["signing", "key encipherment", "server auth", "client auth"]
      validity_period_hours = var.tls.certs_validity_period_hours
      early_renewal_hours   = var.tls.certs_early_renewal_hours
    }
    ],
    [
      {
        common_name           = format("%s-%s-client.%s", module.label.namespace, module.label.name, var.hosted_zone)
        ip_addresses          = data.aws_instances.etcd.private_ips
        uris                  = []
        dns_names             = []
        allowed_uses          = ["signing", "key encipherment", "client auth"]
        validity_period_hours = var.tls.certs_validity_period_hours
        early_renewal_hours   = var.tls.certs_early_renewal_hours
      }
    ]
  )
  tags = var.tags
}
