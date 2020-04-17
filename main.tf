provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

# ----- IAM ---------
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
  tags = {
    Name = "blog.vpc"
  }
}
#------ Internet Gateway
resource "aws_internet_gateway" "blog_internet_gateway" {
  vpc_id = "${aws_vpc.blog_vpc.id}"
  tags = {
    Name = "blog_igw"
  }
}

# ------- Public route table
resource "aws_route_table" "blog_public_rt" {
  vpc_id = "${aws_vpc.blog_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.blog_internet_gateway.id}"
  }
  tags = {
    Name = "blog.public"
  }
}

# ------- Private route table
resource "aws_default_route_table" "blog_private_rt" {
  default_route_table_id = "${aws_vpc.blog_vpc.default_route_table_id}"
  tags = {
    Name = "blog.private"
  }
}

# -------- Subnets
resource "aws_subnet" "blog_public1_subnet" {
  vpc_id                  = "${aws_vpc.blog_vpc.id}"
  cidr_block              = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]})"
  tags = {
    Name = "blog_public1_subnet"
  }
}

resource "aws_subnet" "blog_public2_subnet" {
  vpc_id                  = "${aws_vpc.blog_vpc.id}"
  cidr_block              = "${var.cidrs["public2"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]})"
  tags = {
    Name = "blog_public2_subnet"
  }
}

resource "aws_subnet" "blog_private1_subnet" {
  vpc_id                  = "${aws_vpc.blog_vpc.id}"
  cidr_block              = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]})"
  tags = {
    Name = "blog_private1_subnet"
  }
}

resource "aws_subnet" "blog_private2_subnet" {
  vpc_id                  = "${aws_vpc.blog_vpc.id}"
  cidr_block              = "${var.cidrs["private2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]})"
  tags = {
    Name = "blog_private2_subnet"
  }
}


resource "aws_subnet" "blog_rds1_subnet" {
  vpc_id                  = "${aws_vpc.blog_vpc.id}"
  cidr_block              = "${var.cidrs["rds1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]})"
  tags = {
    Name = "blog_rds1_subnet"
  }
}

resource "aws_subnet" "blog_rds2_subnet" {
  vpc_id                  = "${aws_vpc.blog_vpc.id}"
  cidr_block              = "${var.cidrs["rds2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]})"
  tags = {
    Name = "blog_rds2_subnet"
  }
}

resource "aws_subnet" "blog_rds3_subnet" {
  vpc_id                  = "${aws_vpc.blog_vpc.id}"
  cidr_block              = "${var.cidrs["rds3"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[2]})"
  tags = {
    Name = "blog_rds3_subnet"
  }
}

# -------#rds subnet group
resource "aws_db_subnet_group" "blog_rds_subnetgroup" {
  name = "blog_rds_subnetgroup"
  subnet_ids = ["${aws_subnet.blog_rds1_subnet.id}",
    "${aws_subnet.blog_rds2_subnet.id}",
    "${aws_subnet.blog_rds3_subnet.id}"
  ]
  tags = {
    Name = "blog_rds_subnetgroup"
  }
}


# ------ Subnet associations
resource "aws_route_table_association" "blog_public1_association" {
  subnet_id      = "${aws_subnet.blog_public1_subnet.id}"
  route_table_id = "${aws_route_table.blog_public_rt.id}"
}

resource "aws_route_table_association" "blog_public2_association" {
  subnet_id      = "${aws_subnet.blog_public2_subnet.id}"
  route_table_id = "${aws_route_table.blog_public_rt.id}"
}

resource "aws_route_table_association" "blog_private1_association" {
  subnet_id      = "${aws_subnet.blog_private1_subnet.id}"
  route_table_id = "${aws_default_route_table.blog_private_rt.id}"
}

resource "aws_route_table_association" "blog_private2_association" {
  subnet_id      = "${aws_subnet.blog_private2_subnet.id}"
  route_table_id = "${aws_default_route_table.blog_private_rt.id}"
}


# -------- Security groups

resource "aws_security_group" "blog_dev_sg" {
  name        = "blog_dev_sg"
  description = "Used for access to the dev instance"
  vpc_id      = "${aws_vpc.blog_vpc.id}"
  #------SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.localip}"]
    #------http
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.localip}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ------ Public Security group

resource "aws_security_group" "blog_public_sg" {
  name        = "blog_public_sg"
  description = "Used for ELB for public access"
  vpc_id      = "${aws_vpc.blog_vpc.id}"

  #HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "blog_private_sg" {
  name        = "blog_private_sg"
  description = "Used for private instances"
  vpc_id      = "${aws_vpc.blog_vpc.id}"

  #HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "blog_rds_sg" {
  name        = "blog_rds_sg"
  description = "Used for rds instances"
  vpc_id      = "${aws_vpc.blog_vpc.id}"

  #SQL access from public/private sgs
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = ["${aws_security_group.blog_dev_sg.id}",
      "${aws_security_group.blog_public_sg.id}",
      "${aws_security_group.blog_private_sg.id}"
    ]
  }
}
