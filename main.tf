provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "s3_access"
  role = "${aws_iam_role.s3_access_role.name}"
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = "${aws_iam_role.s3_access_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
     }
    ]
}
EOF
}

resource "aws_iam_role" "s3_access_role" {
  name               = "s3_access_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "ec2.amazonaws.come"
  },
    "Effect": "Allow",
    "Sid": ""
    }
  ]

}
EOF
}

#------- VPC ----------
resource "aws_vpc" "blog_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags {
    Name = "blog_vpc"
  }

}
#------ Internet Gateway
resource "aws_internet_gateway" "blog_internet_gateway" {
  vpc_id = "${aws_vpc.blog_vpc.id}"
  tags {
    Name = "blog_vpc"
  }
}
