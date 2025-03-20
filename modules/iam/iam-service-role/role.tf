#ec2 Role
resource "aws_iam_role" "ec2-iam-role" {
  name ="aws-iam-${var.stage}-${var.servicename}-ec2-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = var.tags

}

resource "aws_iam_instance_profile" "ec2-iam-role-profile" {
  name = "aws-iam-${var.stage}-${var.servicename}-ec2-role-profile"
  role = aws_iam_role.ec2-iam-role.name
}

/*resource "aws_iam_role" "terraform_backend_role" {
  name = "TerraformS3Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.aws_account_id}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "terraform_backend_attach" {
  role       = aws_iam_role.terraform_backend_role.name
  policy_arn = aws_iam_policy.terraform_backend_policy.arn
}*/