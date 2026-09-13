# --- Violates: cost/oversized_instances ---
# --- Violates: security/unencrypted_volumes (root + attached EBS block devices) ---
resource "aws_instance" "worker" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "m5.4xlarge"

  root_block_device {
    encrypted = false
  }

  ebs_block_device {
    device_name = "/dev/sdh"
    volume_size = 50
    encrypted   = false
  }

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "iac-sentinel-demo"
  }
}

# --- Violates: cost/missing_auto_shutdown_tags (non-prod instance, no AutoShutdown/Schedule tag) ---
# --- Violates: governance/required_tags (missing Owner & Project) ---
resource "aws_instance" "dev_sandbox" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"

  tags = {
    Environment = "dev"
  }
}
