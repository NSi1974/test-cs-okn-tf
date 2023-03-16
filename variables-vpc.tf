variable "client" {
  default = "okn"
}

variable "client_projet" {
  # variable dynamique, a commenter si besoin
  # default = "test-tags"
}

variable "client_env" {
  default = "prod"
}

variable "main_vpc_cidr" {
  # variable dynamique, a commenter si besoin
  # default = "172.80.0.0/16"
}

variable "nats" {
  default = 2
}

variable "client_flowlog_role" {
  default = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

variable "FlowLogsPolicy" {
  default = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

variable "pubsubnets_cidr" {
  type    = list(any)
  # variable dynamique, a commenter si besoin
  # default = ["172.80.100.0/24", "172.80.200.0/24"]
}

variable "privsubnets_cidr" {
  type    = list(any)
  # variable dynamique, a commenter si besoin
  # default = ["172.80.10.0/24", "172.80.20.0/24"]
}

variable "azs" {
  type    = list(any)
  default = ["eu-west-3a", "eu-west-3b"]
}
