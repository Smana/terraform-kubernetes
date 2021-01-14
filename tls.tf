module "tls" {
  source = "./modules/tls"

  ca = {
    common_name           = "kubeadm"
    organization          = "kubernetes"
    validity_period_hours = 10000
    early_renewal_hours   = 800
  }

  bucket_name = "tlsstore"

  user_role_arns  = []
  admin_role_arns = ["arn:aws:iam::606334646925:user/smana"]

  kms = {
    deletion_window_in_days = 30
    enable_key_rotation     = false
  }

  tags = {}
}
