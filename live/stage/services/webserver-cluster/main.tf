provider "aws" {
    region = "us-east-1"
}

module "webserver_cluster" {
    source                  = "../../../../modules/services/webserver-cluster"

    ami                     = "ami-40d28157"
    server_text             = "New Server Text"

    cluster_name            = "webserver-stage"
    db_remote_state_bucket  = "terraform-up-and-running-bucket"
    db_remote_state_key     = "live/stage/data-stores/mysql/terraform.tfstate"

    instance_type           = "t2.micro"
    min_size                = 2
    max_size                = 2

    enable_autoscaling      = false
}


terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}