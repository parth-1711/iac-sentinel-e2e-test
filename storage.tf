# --- Violates: security/public_s3_buckets (public ACL) ---
# --- Remediated: added the mandatory Owner & Project governance tags ---
resource "aws_s3_bucket" "app_logs" {
  bucket = "iac-sentinel-demo-app-logs"
  acl    = "public-read"

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "iac-sentinel-demo"
  }
}

# --- Violates: security/public_s3_buckets (public access block disabled) ---
resource "aws_s3_bucket_public_access_block" "app_logs_pab" {
  bucket = aws_s3_bucket.app_logs.id

  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true
}

# --- Violates: security/unencrypted_volumes (standalone EBS volume) ---
resource "aws_ebs_volume" "app_data" {
  availability_zone = "us-east-1a"
  size              = 100
  encrypted         = false

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "iac-sentinel-demo"
  }
}
