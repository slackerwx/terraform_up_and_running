provider "aws" {
    region = "us-east-1"
}

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"

    cluster_name            = "webserver-stage"
    db_remote_state_bucket  = "terraform-up-and-running-bucket"
    db_remote_state_key     = "prodt/data-stores/mysql/terraform.tfstate"

    #instance_type = "m4.large" 
    instance_type = "t2.micro"
    min_size = 2
    max_size = 10
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
    scheduled_action_name    = "scale-out-during-business-hours"
    min_size                = 2
    max_size                = 10
    #desired_capacity       = 10 
    desired_capacity        = 3
    recurrence              = "0 9 * * *"

    autoscaling_group_name  = "${module.webserver_cluster.asg_name}"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
    scheduled_action_name    = "scale-in-at-night"
    min_size                = 2
    max_size                = 10
    desired_capacity        = 2
    recurrence              = "0 17 * * *"

    autoscaling_group_name  = "${module.webserver_cluster.asg_name}"
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}
