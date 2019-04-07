variable "db_name"{
    description = "The name of the database"
}

variable "db_username" {
    description = "The username for the database"
}

variable "db_password" {
    description = "The password for the database"
}

variable "db_instance_type" {
    description = "The type of RDS Instance to run (e.g. db.t2.micro)"
}
