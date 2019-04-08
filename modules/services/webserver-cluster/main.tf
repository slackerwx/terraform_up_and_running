provider "aws" {
  region    = "us-east-1"
}

# By default, AWS does not allow any incoming or outgoing traffic from an EC2 Instance
resource "aws_security_group" "instance"{
    name = "${var.cluster_name}-instance"

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_security_group_rule" "allow_http_requests" {
    type                = "ingress"
    security_group_id   = "${aws_security_group.instance.id}"
    from_port           = "${var.server_port}"
    to_port             = "${var.server_port}"
    protocol            = "tcp"

    #CIDR blocks are a concise way to specify IP address
    cidr_blocks         = ["0.0.0.0/0"]
}

resource "aws_launch_configuration" "example" {
    image_id = "ami-40d28157"
    instance_type = "${var.instance_type}"

    #we need to tell the EC2 Instance to use it
    security_groups = ["${aws_security_group.instance.id}"]

    # Takes the list returned by the inner part, which will be of length 1,
    # and uses the element function to extract that one value
    user_data = "${data.template_file.user_data.rendered}"

    lifecycle {
        create_before_destroy = true
    }
}

data "template_file" "user_data" {
    template = "${file("${path.module}/user-data.sh")}"

    vars {
        server_port = "${var.server_port}"
        db_address  = "${data.terraform_remote_state.db.address}"
        db_port     = "${data.terraform_remote_state.db.port}"
        server_text = "${var.server_text}"
    }
}

# You can use this data source to fetch the Terraform state
# file stored by another set of Terraform configurations 
# in completeley read-only manner
data "terraform_remote_state" "db" {
    backend = "s3"

    config {
        bucket = "${var.db_remote_state_bucket}"
        key    = "${var.db_remote_state_key}"
        region = "us-east-1"
    }
}

data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "example"{
    name                    = "${var.cluster_name}-${aws_launch_configuration.example.name}"

    launch_configuration = "${aws_launch_configuration.example.id}"
    availability_zones   = ["${data.aws_availability_zones.all.names}"]

    # to tell the ASG to register each Instance in the ELB when that Instance is booting
    load_balancers      = ["${aws_elb.example.name}"]
    health_check_type    = "ELB"

    min_size = "${var.min_size}"
    max_size = "${var.max_size}"
    min_elb_capacity = "${var.min_size}"

    lifecycle {
        create_before_destroy = true
    }

    tag {
        key                 = "Name"
        value               = "${var.cluster_name}-asg"
        propagate_at_launch = true
    }
}

# By default, ELB don't allow any incoming or outgoing traffic (just like EC2 Instance)
resource "aws_security_group" "elb" {
    name = "${var.cluster_name}-elb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
    type                = "ingress"
    security_group_id   = "${aws_security_group.elb.id}"
    from_port           = 80
    to_port             = 80
    protocol            = "tcp"
    cidr_blocks         = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {

    # Outbound requests (to allow health check requests)
    type                = "egress"
    security_group_id   = "${aws_security_group.elb.id}"
    from_port           = 0
    to_port             = 0
    protocol            = -1
    cidr_blocks         = ["0.0.0.0/0"]
}

resource "aws_elb" "example" {
    name                = "${var.cluster_name}-asg"
    availability_zones  = ["${data.aws_availability_zones.all.names}"]
    security_groups     = ["${aws_security_group.elb.id}"]

    listener {
        lb_port             = 80
        lb_protocol         = "http"
        instance_port       = "${var.server_port}"
        instance_protocol   = "http"
    }

    health_check {
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 3
        interval            = 30 #seconds
        target              = "HTTP:${var.server_port}/"
    }
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
    // If is true, the count parameter for each of the aws_autoscaling_schedule resources
    // will be set to 1, so one of each will be created
    count                   = "${var.enable_autoscaling}"

    scheduled_action_name   = "scale-out-during-business-hours"
    min_size                = 2
    max_size                = 10
    #desired_capacity       = 10
    desired_capacity        = 3
    recurrence              = "0 9 * * *"

    autoscaling_group_name  = "${aws_autoscaling_group.example.name}"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
    // If is true, the count parameter for each of the aws_autoscaling_schedule resources
    // will be set to 1, so one of each will be created
    count                   = "${var.enable_autoscaling}"

    scheduled_action_name   = "scale-in-at-night"
    min_size                = 2
    max_size                = 10
    desired_capacity        = 2
    recurrence              = "0 17 * * *"

    autoscaling_group_name  = "${aws_autoscaling_group.example.name}"
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
    alarm_name          = "${var.cluster_name}-high-cpu-utilization"
    namespace           = "AWS/EC2"
    metric_name         = "CPUUtilization"
    dimensions = {
        AutoScalingGroupName = "${aws_autoscaling_group.example.name}"
    }
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    period              = 300 #seconds
    statistic           = "Maximum"
    threshold           = 90
    unit                = "Percent"
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
    # produces 1 for instance types that start with “t” and a 0 otherwise,
    # ensuring the alarm is only created for instance types that actually
    # have a CPUCreditBalance metric.
//    count               = "${replace(replace(var.instance_type, "/^[^t].*/", "0" ),"/^t.*$", "1")}"
    count               = "${format("%.1s", var.instance_type) == "t" ? 1 : 0}"

    alarm_name          = "${var.cluster_name}-low-cpu-credit-balance"
    namespace           = "AWS/EC2"
    metric_name         = "CPUCreditBalance"
    dimensions = {
        AutoScalingGroupName = "${aws_autoscaling_group.example.name}"
    }
    comparison_operator = "LessThanThreshold"
    evaluation_periods  = 1
    period              = 300 #seconds
    statistic           = "Minimum"
    threshold           = 10
    unit                = "Count"
}
