variable "server_port" {
    description = "The port the server will use for HTTP requests"
    default = 8080
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket used for the database's remote state storage"
  default = "terraform-up-and-running-bucket"
}

variable "db_remote_state_key" {
  description = "The name of the key in the S3 bucket used for the database's remote state storage"
  default = "stage/data-stores/mysql/terraform.tfstate"
}
