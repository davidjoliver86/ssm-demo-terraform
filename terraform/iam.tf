# Standard instance profile

data "aws_iam_policy_document" "ec2_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "ec2"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust_policy.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "ec2"
  role = aws_iam_role.ec2.id
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# "Users"

data "aws_iam_user" "me" {
  user_name = "david.oliver"
}

data "aws_iam_policy_document" "allow_myself_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_user.me.arn]
    }
  }
}

resource "aws_iam_role" "dev_leads" {
  name               = "dev-leads"
  assume_role_policy = data.aws_iam_policy_document.allow_myself_assume_role.json

  tags = merge(var.default_tags, {
    Name = "dev-leads"
  })
}

resource "aws_iam_role" "devs" {
  name               = "devs"
  assume_role_policy = data.aws_iam_policy_document.allow_myself_assume_role.json

  tags = merge(var.default_tags, {
    Name = "devs"
  })
}

data "aws_iam_policy_document" "base" {
  statement {
    actions = [
      "ssm:ResumeSession",
      "ssm:TerminateSession",
    ]
    resources = ["arn:aws:ssm:::session/$${aws:username}-*"]
  }

  statement {
    actions = [
      "ec2:Describe*",
      "ssm:Describe*"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ssm_connect_dev" {
  statement {
    actions   = ["ssm:StartSession"]
    resources = ["arn:aws:ec2:::instance/*"]

    condition {
      test     = "StringEquals"
      variable = "ssm:resourceTag/env"
      values   = ["dev"]
    }
  }
}

data "aws_iam_policy_document" "ssm_connect_prod" {
  statement {
    actions   = ["ssm:StartSession"]
    resources = ["arn:aws:ec2:::instance/*"]

    condition {
      test     = "StringEquals"
      variable = "ssm:resourceTag/env"
      values   = ["prod"]
    }
  }
}

resource "aws_iam_policy" "base" {
  name   = "base"
  policy = data.aws_iam_policy_document.base.json

  tags = merge(var.default_tags, {
    Name = "ssm-base"
  })
}

resource "aws_iam_policy" "ssm_connect_dev" {
  name   = "ssm-dev"
  policy = data.aws_iam_policy_document.ssm_connect_dev.json

  tags = merge(var.default_tags, {
    Name = "ssm-dev"
  })
}

resource "aws_iam_policy" "ssm_connect_prod" {
  name   = "ssm-prod"
  policy = data.aws_iam_policy_document.ssm_connect_prod.json

  tags = merge(var.default_tags, {
    Name = "ssm-prod"
  })
}

resource "aws_iam_policy_attachment" "base" {
  name       = "base"
  policy_arn = aws_iam_policy.base.arn

  roles = [
    aws_iam_role.devs.id,
    aws_iam_role.dev_leads.id,
  ]
}

resource "aws_iam_policy_attachment" "ssm_connect_dev" {
  name       = "ssm-dev"
  policy_arn = aws_iam_policy.ssm_connect_dev.arn

  roles = [
    aws_iam_role.devs.id,
    aws_iam_role.dev_leads.id,
  ]
}

resource "aws_iam_policy_attachment" "ssm_connect_prod" {
  name       = "ssm-prod"
  policy_arn = aws_iam_policy.ssm_connect_prod.arn

  roles = [
    aws_iam_role.dev_leads.id
  ]
}
