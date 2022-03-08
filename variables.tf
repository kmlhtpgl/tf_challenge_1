variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = string
  default     = "created-by-kemal"
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t2.micro"
}

variable "aws_region" {
    type = string
    default = "us-east-1"
}

variable "server_port" {
  description = "The port the web server will be listening"
  type        = number
  default     = 80
}

variable "elb_port" {
  description = "The port the elb will be listening"
  type        = number
  default     = 80
}