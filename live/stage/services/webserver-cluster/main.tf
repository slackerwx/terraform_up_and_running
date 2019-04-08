provider "aws" {
    region = "${var.aws_region}"
}

module "webserver_cluster" {
    source                  = "../../../../modules/services/webserver-cluster"

    ami                     = "ami-40d28157"
    server_text             = "New Server Text"
    aws_region              = "${var.aws_region}"

    cluster_name            = "${var.cluster_name}"
    db_remote_state_bucket  = "${var.db_remote_state_bucket}"
    db_remote_state_key     = "${var.db_remote_state_key}"

    instance_type           = "t2.micro"
    min_size                = 2
    max_size                = 2

    enable_autoscaling      = false
}


terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}