variable "region" {
  default     = "us-east-1"
}

variable "zone" {
  default     = "us-east-1a"
}

variable "amiID" {
  type = map
  default = {
    us-east-1 = "ami-020cba7c55df1f615"
    us-east-2 = "ami-0d1b5a8c13042c939"
  }
}