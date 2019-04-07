provider "aws" {
    region = "us-east-1"
}

resource "aws_db_instance" "example" {
    engine              = "mysql"
    allocated_storage   = 10
    instance_class      = "${var.db_instance_type}"
    name                = "${var.db_name}"
    username            = "${var.db_username}"
    password            = "${var.db_password}"
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}
