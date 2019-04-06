provider "aws" {
    region = "us-east-1"
}

resource "aws_db_instance" "example" {
    engine              = "mysql"
    allocated_storage   = 10
    instance_class      = "db.t2.micro"
    name                = "example_database"
    username            = "admin"
    password            = "${var.db_password}"
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}
