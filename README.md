# DEMO

## AWS

#### US-EAST-1

![ec2-instances-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-ec2-instances-current-coverage.svg?maxAge=60) ![ec2-sgs-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-ec2-security-groups-current-coverage.svg?maxAge=60) ![ec2-ami-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-ec2-ami-current-coverage.svg?maxAge=60) ![ec2-volumes-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-ec2-volumes-current-coverage.svg?maxAge=60) ![ec2-albs-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-ec2-albs-current-coverage.svg?maxAge=60) ![ec2-elbs-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-ec2-elbs-current-coverage.svg?maxAge=60) ![lambda-functions-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-lambda-functions-current-coverage.svg?maxAge=60) ![rds-instances-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-rds-instances-current-coverage.svg?maxAge=60) ![vpcs-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-vpcs-current-coverage.svg?maxAge=60) ![subnets-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-subnets-current-coverage.svg?maxAge=60) ![route-tables-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-route-tables-current-coverage.svg?maxAge=60) ![internet-gateways-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-internet-gateways-current-coverage.svg?maxAge=60) ![dhcp-option-sets-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-dhcp-opts-current-coverage.svg?maxAge=60) ![network-acls-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-network-acls-current-coverage.svg?maxAge=60) ![s3-buckets-coverage](https://s3-us-west-2.amazonaws.com/terraform-infra-as-code-coverage-badges/us-east-1-s3-buckets-current-coverage.svg?maxAge=60) 

# WHAT
A small script that is useful to track the level of 'infrastructure-as-code' coverage; ie how much of your AWS infrastructure is managed by Terraform?

It checks the following AWS resources:
- EC2 Instances
- EC2 Security Groups
- EC2 AMIs
- EC2 Volumes
- EC2 ALBs
- EC2 ELBs
- Lambda Functions
- RDS Instances
- VPCs
- VPC Subnets
- VPC Route Tables
- VPC IGWs
- VPC DHCP Options
- VPC Network ACLs
- S3 Buckets

# WHY
It can be difficult track the status of existing AWS resources when attempting to import a large existing project into Terraform managed infrastructure-as-code. One of the challenges is identifying what AWS resources are currently managed by Terraform and which ones still need to be imported. This script is an initial attempt.

# HOW
A series of bash functions that call the AWS API, performs some basic mathematics as needed, and writes the output to a badge using [http://shields.io/](http://shields.io/)

- `git clone` this repo
- be sure to export any AWS_* environment variables (such as AWS_PROFILE or AWS_REGION)
  - OUTPUT_DIR defaults to `/tmp`
	- AWS_REGION defaults to `us-east-1`
	- AWS_PROFILE has no default, so if it is not given, then AWS_ACCESS_KEY_ID and AWS_SECRET_KEY will need to be given
  - BADGES_S3_BUCKET_NAME defaults to `terraform-infra-as-code-coverage-badges`
- run the script
  - it will make the AWS API calls, checking all AWS resources in the specified region of your specified account for the existence of the specified tag.
  - it will calculate the total number of resources vs the total number of tagged resources
  - it will use the output of the above function as the input for the badges.io API to create coverage badges
  - it will write the badges to the specified S3 bucket
- you can point to the URL of the S3 badges in order to embed anywhere you want, see above Demo for an example.

# REQUIREMENTS
- An existing AWS account.
  - Permissions: Create S3 bucket
  - what else?
- Locally configured [AWS profile](http://docs.aws.amazon.com/cli/latest/userguide/cli-multiple-profiles.html) with AWS credentials
- AWS resources that are consistently identified via a single tag
    - tag is configurable. Our example is "Terraform = True"
    - Any resource containing this tag is assumed to be managed via Terraform
- jq

# FAQ
- Q) Why bash?
  - A) I like bash. It's simple and is easy for coders of all levels to contribute to.
- Q) Does this show my coverage for ALL AWS resources?
  - A) No. It currently checks for over a dozen resources that 1) support AWS tags & 2) Have Terraform support for reading/writing AWS tags.
- Q) Do you plan on extending this?
  - A) Sure, see the TODO section.

# TODO
[Issues](https://github.com/chrisanthropic/terraform-infra-as-code-coverage-badges/issues?q=is%3Aopen+is%3Aissue+label%3Aenhancement)
