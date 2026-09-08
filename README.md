# AWS VPC Bash Script

This project creates a basic AWS network using Bash and AWS CLI.

## What it creates

- VPC
- Public subnet
- Private subnet
- Internet Gateway
- NAT Gateway
- Public route table
- Private route table

## Network

VPC: `10.0.0.0/16`

Public subnet: `10.0.1.0/24`

Private subnet: `10.0.2.0/24`

The public subnet connects to the internet through the Internet Gateway.

The private subnet uses the NAT Gateway for internet access.

## Files

`aws_script.sh` - creates the AWS resources.

`variables.sh` - contains the network settings.

## Run

```bash
chmod +x aws_script.sh
./aws_script.sh