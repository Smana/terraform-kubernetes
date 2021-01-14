module "label" {
  source    = "cloudposse/label/terraform"
  version   = "v0.5.1"
  namespace = var.label.namespace
  stage     = var.label.stage
  name      = var.label.name
  tags      = var.tags
}
