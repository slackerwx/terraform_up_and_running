provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_user" "example" {
  count = "${length(var.user_names)}"
  name  = "${element(var.user_names, count.index)}"
}

data "aws_iam_policy_document" "ec2_read_only" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:Describe"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_read_only" {
  name = "ec2-read-only"
  policy = "${data.aws_iam_policy_document.ec2_read_only.json}"
}

resource "aws_iam_policy_attachment" "ec2_access" {
  name        = "ec2-access"
  count       = "${length(length(var.user_names))}"
  user        = "${element(aws_iam_user.example.*.name, count.index)}"
  policy_arn  = "${aws_iam_policy.ec2_read_only.arn}"
}

data "aws_iam_policy_document" "cloudwatch_read_only" {
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:Describe*", "cloudwatch:Get*",]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudwatch_read_only" {
  name    = "cloudwatch-read-only"
  policy  = "${data.aws_iam_policy_document.cloudwatch_read_only.json}"
}

data "aws_iam_policy_document" "cloudwatch_full_access" {
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudwatch_full_access" {
  name    = "cloudwatch-full-access"
  policy  = "${data.aws_iam_policy_document.cloudwatch_full_access.json}"
}

# Only be created if var.give_neo_cloudwatch_full_access = true (this is the if-clause)
resource "aws_iam_policy_document" "neo_cloudwatch_full_access" {
  count       = "${var.give_neo_cloudwatch_full_access}"

  user        = "${aws_iam_user.example.0.name}"
  policy_arn  = "${aws_iam_policy.cloudwatch_full_access.arn}"
}

# Only be created if var.give_neo_cloudwatch_full_access = false (this is the else-clause)
resource "aws_iam_policy_document" "neo_cloudwatch_ready_only" {
  count       = "${1 - var.give_neo_cloudwatch_full_access}"

  user        = "${aws_iam_user.example.0.name}"
  policy_arn  = "${aws_iam_policy.cloudwatch_full_access.arn}"
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}
