variable "user_names" {
  description = "Create IAM users with these names"
  type = "list"
  default = ["neo", "triniy", "morpheus"]
}

variable "give_neo_cloudwatch_full_access" {
  description = "If true, Neo gets full access to CloudWatch"
}