provider "aws" {
    region = "${var.aws_region}"
}

module "webserver_cluster" {
    source = "git::https://github.com/slackerwx/terraform_up_and_running.git//modules/services/webserver-cluster"

    ami                     = "${data.aws_ami.ubuntu.id}"
    server_text             = "Hello, Production Environment!"
    aws_region              = "${var.aws_region}"

    cluster_name            = "${var.cluster_name}"
    db_remote_state_bucket  = "${var.db_remote_state_bucket}"
    db_remote_state_key     = "${var.db_remote_state_key}"

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
