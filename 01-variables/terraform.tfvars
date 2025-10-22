# terraform.tfvars
# Hier werden konkrete Werte für die Variablen gesetzt

aws_region      = "eu-north-1"
instance_name   = "prod-web"
instance_count  = 3
enable_public_ip = false



instance_tags = {
  Environment = "development"
  Team        = "DevOps"
}

instance_config = {
  instance_type = "t3.micro"
  volume_size   = 20
}
allowed_ssh_cidrs = ["10.0.0.0/8"]
allowed_http_cidrs = ["0.0.0.0/0"]

environment = "development"
