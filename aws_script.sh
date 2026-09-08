#!/bin/bash

# Load variables
source variables.sh

echo "Starting AWS VPC setup..."

# Ask for AWS credentials
read -p "Enter your AWS Access Key: " AWS_ACCESS_KEY_ID
read -s -p "Enter your AWS Secret Key: " AWS_SECRET_ACCESS_KEY
echo

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

# Check AWS connection
echo "Checking AWS connection..."

aws sts get-caller-identity --region "$REGION"

# Create VPC
echo "Creating VPC..."

VPC_ID=$(aws ec2 create-vpc \
    --cidr-block "$VPC_CIDR" \
    --region "$REGION" \
    --query 'Vpc.VpcId' \
    --output text)

echo "VPC created: $VPC_ID"

# Create Public Subnet
echo "Creating public subnet..."

PUBLIC_SUBNET=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block "$PUBLIC_SUBNET_CIDR" \
    --availability-zone "$AVAILABILITY_ZONE" \
    --region "$REGION" \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Public subnet created: $PUBLIC_SUBNET"

# Create Private Subnet
echo "Creating private subnet..."

PRIVATE_SUBNET=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block "$PRIVATE_SUBNET_CIDR" \
    --availability-zone "$AVAILABILITY_ZONE" \
    --region "$REGION" \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Private subnet created: $PRIVATE_SUBNET"

# Create Internet Gateway
echo "Creating Internet Gateway..."

IGW_ID=$(aws ec2 create-internet-gateway \
    --region "$REGION" \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

echo "Internet Gateway created: $IGW_ID"

# Attach Internet Gateway
aws ec2 attach-internet-gateway \
    --vpc-id "$VPC_ID" \
    --internet-gateway-id "$IGW_ID" \
    --region "$REGION"

echo "Internet Gateway attached."

# Create Public Route Table
echo "Creating public route table..."

PUBLIC_ROUTE_TABLE=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --region "$REGION" \
    --query 'RouteTable.RouteTableId' \
    --output text)

# Add internet route
aws ec2 create-route \
    --route-table-id "$PUBLIC_ROUTE_TABLE" \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id "$IGW_ID" \
    --region "$REGION"

# Connect public subnet
aws ec2 associate-route-table \
    --route-table-id "$PUBLIC_ROUTE_TABLE" \
    --subnet-id "$PUBLIC_SUBNET" \
    --region "$REGION"

echo "Public route table configured."

# Create Elastic IP
echo "Creating Elastic IP..."

ALLOCATION_ID=$(aws ec2 allocate-address \
    --domain vpc \
    --region "$REGION" \
    --query 'AllocationId' \
    --output text)

# Create NAT Gateway
echo "Creating NAT Gateway..."

NAT_GATEWAY=$(aws ec2 create-nat-gateway \
    --subnet-id "$PUBLIC_SUBNET" \
    --allocation-id "$ALLOCATION_ID" \
    --region "$REGION" \
    --query 'NatGateway.NatGatewayId' \
    --output text)

echo "NAT Gateway created: $NAT_GATEWAY"

# Wait for NAT Gateway
echo "Waiting for NAT Gateway..."

aws ec2 wait nat-gateway-available \
    --nat-gateway-ids "$NAT_GATEWAY" \
    --region "$REGION"

# Create Private Route Table
echo "Creating private route table..."

PRIVATE_ROUTE_TABLE=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --region "$REGION" \
    --query 'RouteTable.RouteTableId' \
    --output text)

# Send private traffic through NAT Gateway
aws ec2 create-route \
    --route-table-id "$PRIVATE_ROUTE_TABLE" \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id "$NAT_GATEWAY" \
    --region "$REGION"

# Connect private subnet
aws ec2 associate-route-table \
    --route-table-id "$PRIVATE_ROUTE_TABLE" \
    --subnet-id "$PRIVATE_SUBNET" \
    --region "$REGION"

echo "Private route table configured."

echo ""
echo "=============================="
echo " AWS VPC SETUP COMPLETED"
echo "=============================="
echo "VPC:              $VPC_ID"
echo "Public Subnet:    $PUBLIC_SUBNET"
echo "Private Subnet:   $PRIVATE_SUBNET"
echo "Internet Gateway: $IGW_ID"
echo "NAT Gateway:      $NAT_GATEWAY"
echo "=============================="
