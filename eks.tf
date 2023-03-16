resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.client}-${var.client_projet}-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.privsubnets_cidr[0].id, aws_subnet.privsubnets_cidr[1].id, aws_subnet.pubsubnets_cidr[0].id, aws_subnet.pubsubnets_cidr[1].id]
    endpoint_private_access = "true"
  }
  
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  encryption_config {
    provider {
      key_arn = aws_kms_key.kms.arn
    }
    resources = ["secrets"]
  }
  provisioner "local-exec" {
    command = "eksctl create iamidentitymapping --cluster ${var.client}-${var.client_projet}-cluster --arn arn:aws:iam::172275755115:role/OKN-ACCESS_ADMIN_TO_OKN-DEPLOIEMENT --group system:masters --username eks-admin --region eu-west-3"
  }
  tags = {
    Name = "${var.client}-${var.client_projet}-cluster"
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.client}-${var.client_projet}-ServiceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [data.aws_iam_policy.AmazonEKSClusterPolicy.arn, data.aws_iam_policy.AmazonEKSVPCResourceController.arn,data.aws_iam_policy.Eks-cluster-PolicyCloudWatchMetrics.arn]
  tags = {
    Name = "${var.client}-${var.client_projet}-ServiceRole"
  }
}

data "aws_iam_policy" "AmazonEKSClusterPolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy" "AmazonEKSVPCResourceController" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

data "aws_iam_policy" "Eks-cluster-PolicyCloudWatchMetrics" {
  name = "Eks-cluster-PolicyCloudWatchMetrics"
}

data "aws_iam_policy" "Eks-cluster-PolicyELBPermissions" {
  name = "Eks-cluster-PolicyELBPermissions"
}

resource "aws_kms_key" "kms" {
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::172275755115:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::172275755115:role/aws-service-role/eks-nodegroup.amazonaws.com/AWSServiceRoleForAmazonEKSNodegroup",
                    "arn:aws:iam::172275755115:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS"
                ]
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::172275755115:role/aws-service-role/eks-nodegroup.amazonaws.com/AWSServiceRoleForAmazonEKSNodegroup",
                    "arn:aws:iam::172275755115:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS"
                ]
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                }
            }
        }
    ]
  })
  tags = {
    Name = "${var.client}-${var.client_projet}-cluster-key"
  }
}

resource "aws_kms_alias" "kms" {
  name = "alias/${var.client}-${var.client_projet}-cluster-key"
  target_key_id = aws_kms_key.kms.key_id
}


