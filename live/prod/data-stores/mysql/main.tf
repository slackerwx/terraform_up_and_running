provider "aws" {
    region = "us-east-1"
}

module "aws_db_instance" "example" {
    source = "../../../../modules/data-stores/mysql"

    db_instance_type    = "db.t2.micro"
    db_name             = "prod_database"
    db_username         = "admin"
    db_password         = "${var.db_password}"
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}
