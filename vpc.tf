######################Creation du VPC
resource "aws_vpc" "client_vpc" {
  cidr_block       = var.main_vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "${var.client}-${var.client_projet}-vpc"
  }
}

output "client_vpc_id" {
  value       = aws_vpc.client_vpc.id
}

######################Activation des Flows Logs 
resource "aws_flow_log" "client_flow_log" {
  iam_role_arn    = data.aws_iam_role.client_flowlog_role.arn
  log_destination = aws_cloudwatch_log_group.client_cloudwatch_flow_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.client_vpc.id
  tags = {
    Name = "${var.client}-${var.client_projet}-flowlogs"
  }
}
#####################Creation des Flow Logs
resource "aws_cloudwatch_log_group" "client_cloudwatch_flow_log_group" {
  name = "${var.client}-${var.client_projet}-flowlogs"
  tags = {
    Name = "${var.client}-${var.client_projet}-flowlogs"
  }
}
data "aws_iam_role" "client_flowlog_role" {
  name               = "flowlogsRole"
}
###################Creation de l' IGW et attachement
resource "aws_internet_gateway" "client_igw" {
  vpc_id = aws_vpc.client_vpc.id
  tags = {
    Name = "${var.client}-${var.client_projet}-igw"
  }
}
####################Creation des subnets publics

resource "aws_subnet" "pubsubnets_cidr" {
  count             = length(var.pubsubnets_cidr)
  vpc_id            = aws_vpc.client_vpc.id
  cidr_block        = element(var.pubsubnets_cidr, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "${var.client}-${var.client_projet}-pub-${count.index + 1}"
  }
}

####################Creation des subnets prives

resource "aws_subnet" "privsubnets_cidr" {
  count             = length(var.privsubnets_cidr)
  vpc_id            = aws_vpc.client_vpc.id
  cidr_block        = element(var.privsubnets_cidr, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "${var.client}-${var.client_projet}-priv-${count.index + 1}"
  }
}

#####################Creation de EIP et de la NAT Gateway
resource "aws_eip" "nats" {
  count = var.nats
  vpc   = true
  tags = {
    Name = "${var.client}-${var.client_projet}-eip"
  }
}

resource "aws_nat_gateway" "nat_priv_subnets" {
  count         = var.nats
  allocation_id = element(aws_eip.nats.*.id, count.index)
  subnet_id     = element(aws_subnet.pubsubnets_cidr.*.id, count.index)
  tags = {
    Name = "${var.client}-${var.client_projet}-natgw-${count.index + 1}"
  }
}

#####################Creation des Route Tables

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.client_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.client_igw.id
  }
  tags = {
    Name = "${var.client}-${var.client_projet}-pub-rt"
  }
}

resource "aws_route_table" "private_rt" {
  count  = var.nats
  vpc_id = aws_vpc.client_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_priv_subnets.*.id, count.index)
  }
  tags = {
    Name = "${var.client}-${var.client_projet}-priv-rt-${count.index + 1}"
  }
}

##################### Association des Routes Tables 

resource "aws_route_table_association" "public_rt_association" {
  count          = length(var.pubsubnets_cidr)
  subnet_id      = element(aws_subnet.pubsubnets_cidr.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rt_association" {
  count          = length(var.privsubnets_cidr)
  subnet_id      = element(aws_subnet.privsubnets_cidr.*.id, count.index)
  route_table_id = aws_route_table.private_rt[count.index].id
}

