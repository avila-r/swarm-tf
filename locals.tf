locals {
  available_type_in_az = {
    for az, details in data.aws_ec2_instance_type_offering.available_types :
    az => details.instance_type
  }
}
