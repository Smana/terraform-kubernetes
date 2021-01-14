data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

/* IAM */

data "aws_iam_policy_document" "tls_store_kms" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.current.account_id)]
    }
    actions = [
      "kms:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow access for Key Administrators"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.current.account_id)]
    }
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.user_role_arns
    content {
      sid    = "Allow use of the key for encryption"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.user_role_arns
      }
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.user_role_arns
    content {
      sid    = "Allow attachment of persistent resources"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.user_role_arns
      }
      actions = [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ]
      resources = ["*"]
      condition {
        test     = "Bool"
        variable = "kms:GrantIsForAWSResource"
        values   = ["true"]
      }
    }
  }
}

data "aws_iam_policy_document" "tls_store_s3" {
  statement {
    sid    = "EnforceSSL"
    effect = "Deny"
    resources = [
      format("arn:aws:s3:::%s/*", aws_s3_bucket.tls_store.id)
    ]
    actions = [
      "s3:*Object",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"

      values = [
        false
      ]
    }
  }
  statement {
    sid    = "DenyIncorrectEncryptionHeader"
    effect = "Deny"
    resources = [
      format("arn:aws:s3:::%s/*", aws_s3_bucket.tls_store.id)
    ]
    actions = [
      "s3:PutObject"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "aws:kms"
      ]
    }
  }
  statement {
    sid    = "DenyUnEncryptedObjectActions"
    effect = "Deny"
    resources = [
      format("arn:aws:s3:::%s/*", aws_s3_bucket.tls_store.id)
    ]
    actions = [
      "s3:PutObject"
    ]
    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "true"
      ]
    }
  }
  statement {
    sid    = "BucketList"
    effect = "Allow"
    resources = [
      format("arn:aws:s3:::%s/*", aws_s3_bucket.tls_store.id)
    ]
    actions = [
      "s3:ListBucket"
    ]
    principals {
      type        = "AWS"
      identifiers = concat(var.admin_role_arns, [format("arn:aws:iam::%s:root", data.aws_caller_identity.current.account_id)])
    }
  }
}

/* S3 */

data "aws_iam_policy_document" "tls_store_s3_admin" {
  statement {
    sid    = "FullAccess"
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
    actions = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "tls_store_s3_read" {
  statement {
    sid    = "ListAccess"
    effect = "Allow"
    resources = [
      "*"
    ]
    actions = [
      "s3:ListBucket",
      "s3:HeadBucket"
    ]
  }
  statement {
    sid    = "ReadAccess"
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
    actions = [
      "s3:GetObject*"
    ]
  }
  statement {
    sid    = "DecryptAccess"
    effect = "Allow"
    resources = [
      aws_kms_key.tls_store_s3_kms.arn
    ]
    actions = [
      "kms:Decrypt"
    ]
  }
}

resource "aws_iam_policy" "tls_store_s3_admin" {
  name        = format("%s-Admin", var.bucket_name)
  description = format("Provides admin access for %s bucket", var.bucket_name)
  policy      = data.aws_iam_policy_document.tls_store_s3_admin.json
}

resource "aws_iam_policy" "tls_store_s3_read" {
  name        = format("%s-Read", var.bucket_name)
  description = format("Provides read access for %s bucket", var.bucket_name)
  policy      = data.aws_iam_policy_document.tls_store_s3_read.json
}

/* Create a KMS key */
resource "aws_kms_key" "tls_store_s3_kms" {
  description             = "KMS key for the S3 bucket that stores the TLS certificates"
  deletion_window_in_days = var.kms.deletion_window_in_days
  policy                  = data.aws_iam_policy_document.tls_store_kms.json
  tags                    = var.tags
}

resource "aws_kms_alias" "tls_store_s3_kms" {
  name          = format("alias/%s-%s", module.label.stage, module.label.name)
  target_key_id = aws_kms_key.tls_store_s3_kms.id
}

/* S3 bucket where the certificates are stored */
resource "aws_s3_bucket" "tls_store" {
  bucket = format("%s-%s", module.label.id, var.bucket_name)
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.tls_store_s3_kms.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = module.label.tags
}

resource "aws_s3_bucket_public_access_block" "tls_store" {
  bucket = aws_s3_bucket.tls_store.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
