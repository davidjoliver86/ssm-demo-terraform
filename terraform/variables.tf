variable "default_tags" {
  type = map(string)
  default = {
    Name    = "ssm-demo"
    project = "ssm-demo"
  }
}

variable "subnets" {
  type        = map(map(string))
  description = "Subnet CIDR blocks"
  default = {
    public = {
      us-east-1a = "192.168.0.0/24"
      us-east-1b = "192.168.1.0/24"
    }
    private = {
      us-east-1a = "192.168.100.0/24"
      us-east-1b = "192.168.101.0/24"
    }
  }
}
