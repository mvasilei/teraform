# Define AWS provider
provider "aws" {
  region = "us-west-2" # Change to your desired region
}

# Create AWS VPC
resource "aws_vpc" "vpc_02930341" {
  cidr_block = "10.0.0.0/16" # Change to your desired CIDR block
}

# Create AWS subnets
resource "aws_subnet" "subnet_1_02930341" {
  vpc_id     = aws_vpc.vpc_02930341.id
  cidr_block = "10.0.1.0/24" # Change to your desired CIDR block
}

# Create security group for Palo Alto firewall and Panorama
resource "aws_security_group" "management_sg" {
  vpc_id = aws_vpc.vpc_02930341.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

#Create Internet Gateway
resource "aws_internet_gateway" "IG_02930341" {
  vpc_id = aws_vpc.vpc_02930341.id
}

#Create Route Table
resource "aws_route_table" "RTB_02930341" {
  vpc_id = aws_vpc.vpc_02930341.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IG_02930341.id
  }
}

#Associate RTB with Subnets
resource "aws_route_table_association" "subnet_1_02930341_assoc" {
  subnet_id      = aws_subnet.subnet_1_02930341.id
  route_table_id = aws_route_table.RTB_02930341.id
}

# Create Panorama instance
# To find AMI aws ec2 describe-images --filters "Name=product-code,Values=" Name=name,Values=PA-VM-AWS*  --region us-west-2 --output json
#resource "aws_instance" "panorama" {
#  ami                    = "ami-09ab2919408a213c3"
#  instance_type          = "c4.4xlarge"    # Change to your desired instance type
#  subnet_id              = aws_subnet.subnet_1_02930341.id
#  vpc_security_group_ids = [aws_security_group.management_sg.id]
#  associate_public_ip_address = true      # Change if public IP is not desired
#  private_ip             = "10.0.1.100"
#
#  key_name               = "KEY_NAME"  # Replace with the name of your AWS key pair
#
#  tags = {
#    Name = "panorama_02930341"
#  }
#}

# Create PA-VM instance
# To find AMI aws ec2 describe-images --filters "Name=product-code,Values=6njl1pau431dv1qxipg63mvah" Name=name,Values=PA-VM-AWS*  --region us-west-2 --output json
resource "aws_instance" "PA-VM_02930341" {
  ami                    = "ami-0db94286767a50bf4"
  instance_type          = "m4.xlarge"    # Change to your desired instance type
  subnet_id              = aws_subnet.subnet_1_02930341.id
  vpc_security_group_ids = [aws_security_group.management_sg.id]
  associate_public_ip_address = true      # Change if public IP is not desired
  private_ip             = "10.0.1.101"

  key_name               = "KEY_NAME"  # Replace with the name of your AWS key pair

  # auto registration id/ value # Genereate in CSP > Assets > Device Certificates > Generate Reg PIN
  user_data = <<-EOF
vm-series-auto-registration-pin-id=<PIN-ID>
vm-series-auto-registration-pin-value=<PIN-VALUE>
auth-key=_AQ__UNi0qUHCa4lILJSrMktaJ0_c7W
dgname = FIREWALL_DG
tplname=FW_TEMPLATE_STACK
plugin-op-commands=panorama-licensing-mode-on
panorama-server=10.0.1.223
  EOF

  tags = {
    Name = "PA-VM_02930341"
  }
}
