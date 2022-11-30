locals {
  instances = [
    {
      subnet    = aws_subnet.private["us-east-1a"].id
      name      = "dev"
      user_data = "ZWNobyAnZWNobyAiV2VsY29tZSB0byBkZXYiJyA+PiAvZXRjL3Byb2ZpbGU="
    },
    {
      subnet    = aws_subnet.private["us-east-1b"].id
      name      = "prod"
      user_data = "ZWNobyAnZWNobyAiV0VMQ09NRSBUTyBQUk9EISEhIicgPj4gL2V0Yy9wcm9maWxl"
    }
  ]
}

resource "aws_instance" "this" {
  count = length(local.instances)

  ami                  = "ami-06334a6e92bb3f864" # Ubuntu 20.04 us-east-1 arm64
  subnet_id            = local.instances[count.index].subnet
  instance_type        = "t4g.nano"
  iam_instance_profile = aws_iam_instance_profile.ec2.id
  user_data_base64     = local.instances[count.index].user_data

  tags = merge(var.default_tags, {
    Name = local.instances[count.index].name
    env  = local.instances[count.index].name
  })
}
