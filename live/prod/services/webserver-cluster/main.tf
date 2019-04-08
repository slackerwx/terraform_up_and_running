provider "aws" {
    region = "us-east-1"
}

module "webserver_cluster" {
    source = "git::https://github.com/slackerwx/terraform_up_and_running.git//modules/services/webserver-cluster"

    cluster_name            = "webserver-prod"
    db_remote_state_bucket  = "terraform-up-and-running-bucket"
    db_remote_state_key     = "live/prod/data-stores/mysql/terraform.tfstate"

    #instance_type = "m4.large" 
    instance_type = "t2.micro"
    min_size = 2
    max_size = 10

    enable_autoscaling      = true
    enable_new_user_data    = false
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}
