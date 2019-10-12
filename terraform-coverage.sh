#!/usr/bin/env bash 
set -euo pipefail

AWS_REGION=${AWS_REGION:-"us-east-1"}
MANAGED_TAG=${MANAGED_TAG:-"Terraform"}
BADGES_S3_BUCKET_NAME=${BADGES_S3_BUCKET_NAME:-"terraform-infra-as-code-coverage-badges"}
OUTPUT_PATH=${OUTPUT_PATH:-/tmp}

create_coverage_badge () {
  UNTAGGED=$1
  TOTAL=$2
  BADGE_EVAL=$3
  
  if (( $TOTAL > 0)); then
    PERCENT_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED}/${TOTAL}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
    TOTAL_COVERED=$(( TOTAL - UNTAGGED ))
    PERCENT_COVERED=$(( 100 - PERCENT_REMAINING ))

    if (( $PERCENT_COVERED == 100 )); then
      COLOR=green
    elif (( $PERCENT_COVERED >= 67 )) && (( $PERCENT_COVERED <= 99 )); then
      COLOR=yellow
    elif (( $PERCENT_COVERED >= 34 )) && (( $PERCENT_COVERED <= 66 )); then
      COLOR=orange
    else
      COLOR=red
    fi
  else
    PERCENT_COVERED=100
    COLOR=green
  fi

  eval echo $BADGE_EVAL
}

# Instances
find_all_instances () {
  aws ec2 describe-instances --region $AWS_REGION --query "Reservations[].Instances[].{ID: InstanceId}" --output text
}

find_untagged_instances () {
  aws ec2 describe-instances --region $AWS_REGION --query "Reservations[].Instances[].{ID: InstanceId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_ec2_instances_badge () {
  create_coverage_badge \
    $(find_untagged_instances | wc -l) \
    $(find_all_instances | wc -l) \
    'https://img.shields.io/badge/managed--ec2--instances-$PERCENT_COVERED%25-$COLOR.svg'
}

write_ec2_instances_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/ec2-instances-current-coverage.svg" $(create_ec2_instances_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/ec2-instances-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-ec2-instances-current-coverage.svg
}

# Security Groups
find_all_security_groups () {
  aws ec2 describe-security-groups --region $AWS_REGION --query "SecurityGroups[].{ID: GroupId}"  --output text
}

find_untagged_security_groups () {
  aws ec2 describe-security-groups --region $AWS_REGION --query "SecurityGroups[].{ID: GroupId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_ec2_security_groups_badge () {
  create_coverage_badge \
    $(find_untagged_security_groups | wc -l) \
    $(find_all_security_groups | wc -l) \
    'https://img.shields.io/badge/managed--ec2--security--groups-$PERCENT_COVERED%25-$COLOR.svg'
}

write_ec2_security_groups_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/ec2-security-groups-current-coverage.svg" $(create_ec2_security_groups_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/ec2-security-groups-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-ec2-security-groups-current-coverage.svg
}

# AMIs
find_aws_account_id () {
  aws sts get-caller-identity --region $AWS_REGION --output text --query 'Account'
}

find_all_amis () {
  aws ec2 describe-images --region $AWS_REGION --owners $(find_aws_account_id) --query "Images[].ImageId" --output text
}

find_untagged_amis () {
  aws ec2 describe-images --region $AWS_REGION --owners $(find_aws_account_id)  --query "Images[].{ID: ImageId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_ec2_amis_badge () {
  create_coverage_badge \
    $(find_untagged_amis | wc -l) \
    $(find_all_amis | wc -l) \
    'https://img.shields.io/badge/managed--ec2--amis-$PERCENT_COVERED%25-$COLOR.svg'
}

write_ec2_amis_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/ec2-ami-current-coverage.svg" $(create_ec2_amis_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/ec2-ami-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-ec2-ami-current-coverage.svg
}

# Volumes
find_all_volumes () {
  aws ec2 describe-volumes --region $AWS_REGION --query "Volumes[].{ID: VolumeId}" --output text
}

find_untagged_volumes () {
  aws ec2 describe-volumes --region $AWS_REGION --query "Volumes[].{ID: VolumeId}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_ec2_volumes_badge () {
  create_coverage_badge \
    $(find_untagged_volumes | wc -l) \
    $(find_all_volumes | wc -l) \
    'https://img.shields.io/badge/managed--ec2--volumes-$PERCENT_COVERED%25-$COLOR.svg'
}

write_ec2_volumes_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/ec2-volumes-current-coverage.svg" $(create_ec2_volumes_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/ec2-volumes-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-ec2-volumes-current-coverage.svg
}

# ALBs
find_all_albs () {
  aws elbv2 describe-load-balancers --region $AWS_REGION --query "LoadBalancers[].{ID: LoadBalancerArn}" --output text
}

find_untagged_albs () {
  aws elbv2 describe-load-balancers --region $AWS_REGION --query "LoadBalancers[].{ID: LoadBalancerArn}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_ec2_albs_badge () {
  create_coverage_badge \
    $(find_untagged_albs | wc -l) \
    $(find_all_albs | wc -l) \
    'https://img.shields.io/badge/managed--ec2--albs-$PERCENT_COVERED%25-$COLOR.svg'
}

write_ec2_albs_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/ec2-albs-current-coverage.svg" $(create_ec2_albs_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/ec2-albs-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-ec2-albs-current-coverage.svg
}

# ELBs
find_all_elbs () {
  aws elb describe-load-balancers --region $AWS_REGION --query "LoadBalancerDescriptions[].{ID: LoadBalancerName}" --output text
}

find_untagged_elbs () {
  local UNTAGGED=0
  for elb in `find_all_elbs`; do
    if
      aws elb describe-tags --region $AWS_REGION --load-balancer-names "${elb}" --query "TagDescriptions[].Tags[].Key" --output text | grep -v $MANAGED_TAG
    then
      ((UNTAGGED++))
    fi
  done
  echo $UNTAGGED
}

create_ec2_elbs_badge () {
  create_coverage_badge \
    $(find_untagged_elbs | tail -1) \
    $(find_all_elbs | wc -l) \
    'https://img.shields.io/badge/managed--ec2--elbs-$PERCENT_COVERED%25-$COLOR.svg'
}

write_ec2_elbs_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/ec2-elbs-current-coverage.svg" $(create_ec2_elbs_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/ec2-elbs-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-ec2-elbs-current-coverage.svg
}

# S3 Buckets
find_all_buckets () {
  BUCKET_LIST=$(aws s3api list-buckets --region $AWS_REGION --query "Buckets[].Name" --output text)
  echo $BUCKET_LIST | tr " " "\n"
}

find_untagged_s3_buckets () {
  local UNTAGGED=0
  for bucket in `find_all_buckets`; do
    if
      ! aws s3api get-bucket-tagging --region $AWS_REGION --bucket $bucket --query "TagSet[].Key[]" 2> /dev/null | sed 's/[][]//g' | grep -v $MANAGED_TAG
    then
      ((UNTAGGED++))
    fi
  done
  echo $UNTAGGED
}

create_s3_buckets_badge () {
  create_coverage_badge \
    $(find_untagged_s3_buckets | tail -1) \
    $(find_all_buckets | wc -l) \
    'https://img.shields.io/badge/managed--s3--buckets-$PERCENT_COVERED%25-$COLOR.svg'
}

write_s3_buckets_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/s3-buckets-current-coverage.svg" $(create_s3_buckets_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/s3-buckets-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-s3-buckets-current-coverage.svg
}

# Lambda Functions
find_all_lambda_functions () {
  aws lambda list-functions --region $AWS_REGION --query "Functions[].{ID: FunctionArn}" --output text
}

find_untagged_lambda_functions () {
  local UNTAGGED=0
  for func in `find_all_lambda_functions`; do
    if
      ! aws lambda list-functions --region $AWS_REGION --query "TagDescriptions[].Tags[].Key" | sed 's/[][]//g' | grep -v $MANAGED_TAG
    then
      ((UNTAGGED++))
    fi
  done
  echo $UNTAGGED
}

create_lambda_functions_badge () {
  create_coverage_badge \
    $(find_untagged_lambda_functions | tail -1) \
    $(find_all_lambda_functions| wc -l) \
    'https://img.shields.io/badge/managed--lambda--functions-$PERCENT_COVERED%25-$COLOR.svg'
}

write_lambda_functions_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/lambda-functions-current-coverage.svg" $(create_lambda_functions_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/lambda-functions-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-lambda-functions-current-coverage.svg
}

# RDS
find_all_rds_instances () {
  aws rds describe-db-instances --region $AWS_REGION --query "DBInstances[].{ID: DBInstanceArn}" --output text
}

find_untagged_rds_instances () {
  local UNTAGGED=0
  for db in `find_all_rds_instances`; do
    if
      ! aws rds list-tags-for-resource --region $AWS_REGION --resource-name $db --query "TagList[].Key" | grep -v $MANAGED_TAG
    then
      ((UNTAGGED++))
    fi
  done
  echo $UNTAGGED
}

create_rds_instances_badge () {
  create_coverage_badge \
  $(find_untagged_rds_instances | tail -1) \
  $(find_all_rds_instances | wc -l) \
  'https://img.shields.io/badge/managed--rds--instances-$PERCENT_COVERED%25-$COLOR.svg'
}

write_rds_instances_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/rds-instances-current-coverage.svg" $(create_rds_instances_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/rds-instances-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-rds-instances-current-coverage.svg
}

# VPC
find_all_vpcs () {
  aws ec2 describe-vpcs --region $AWS_REGION --query "Vpcs[].{ID: VpcId}" --output text
}

find_untagged_vpcs () {
  aws ec2 describe-vpcs --region $AWS_REGION --query "Vpcs[].{ID: VpcId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_vpc_badge () {
  create_coverage_badge \
  $(find_untagged_vpcs | wc -l) \
  $(find_all_vpcs| wc -l) \
  'https://img.shields.io/badge/managed--vpcs-$PERCENT_COVERED%25-$COLOR.svg'
}

write_vpcs_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/vpcs-current-coverage.svg" $(create_vpc_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/vpcs-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-vpcs-current-coverage.svg
}

# SUBNETS
find_all_subnets () {
  aws ec2 describe-subnets --region $AWS_REGION --query "Subnets[].{ID: SubnetId}" --output text
}

find_untagged_subnets () {
  aws ec2 describe-subnets --region $AWS_REGION --query "Subnets[].{ID: SubnetId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_subnets_badge () {
  create_coverage_badge \
  $(find_untagged_subnets | wc -l) \
  $(find_all_subnets| wc -l) \
  'https://img.shields.io/badge/managed--subnets-$PERCENT_COVERED%25-$COLOR.svg'
}

write_subnets_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/subnets-current-coverage.svg" $(create_subnets_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/subnets-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-subnets-current-coverage.svg
}

# ROUTE_TABLES
find_all_route_tables () {
  aws ec2 describe-route-tables --region $AWS_REGION --query "RouteTables[].{ID: RouteTableId}" --output text
}

find_untagged_route_tables () {
  aws ec2 describe-route-tables --region $AWS_REGION --query "RouteTables[].{ID: RouteTableId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_route_tables_badge () {
  create_coverage_badge \
    $(find_untagged_route_tables | wc -l) \
    $(find_all_route_tables| wc -l) \
    'https://img.shields.io/badge/managed--route--tables-$PERCENT_COVERED%25-$COLOR.svg'
}

write_route_tables_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/route-tables-current-coverage.svg" $(create_route_tables_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/route-tables-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-route-tables-current-coverage.svg
}
# INTERNET GATEWAY
find_all_igws () {
  aws ec2 describe-internet-gateways --region $AWS_REGION --query "InternetGateways[].{ID: InternetGatewayId}" --output text
}

find_untagged_igws () {
  aws ec2 describe-internet-gateways --region $AWS_REGION --query "InternetGateways[].{ID: InternetGatewayId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_igws_badge () {
  create_coverage_badge \
    $(find_untagged_igws | wc -l) \
    $(find_all_igws | wc -l) \
    'https://img.shields.io/badge/managed--internet--gateways-$PERCENT_COVERED%25-$COLOR.svg'
}

write_igws_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/internet-gateways-current-coverage.svg" $(create_igws_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/internet-gateways-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-internet-gateways-current-coverage.svg
}

# DHCP OPTION SETS
find_all_dhcp_opts () {
  aws ec2 describe-dhcp-options --region $AWS_REGION --query "DhcpOptions[].{ID: DhcpOptionsId}" --output text
}

find_untagged_dhcp_opts () {
  aws ec2 describe-dhcp-options --region $AWS_REGION --query "DhcpOptions[].{ID: DhcpOptionsId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_dhcp_opts_badge () {
  create_coverage_badge \
  $(find_untagged_dhcp_opts | wc -l) \
  $(find_all_dhcp_opts | wc -l) \
  'https://img.shields.io/badge/managed--dhcp--option--sets-$PERCENT_COVERED%25-$COLOR.svg'
}

write_dhcp_opts_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/dhcp-opts-current-coverage.svg" $(create_dhcp_opts_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/dhcp-opts-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-dhcp-opts-current-coverage.svg
}

# NETWORK ACLS
find_all_network_acls () {
  aws ec2 describe-network-acls --region $AWS_REGION --query "NetworkAcls[].{ID: NetworkAclId}" --output text
}

find_untagged_network_acls () {
  aws ec2 describe-network-acls --region $AWS_REGION --query "NetworkAcls[].{ID: NetworkAclId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_network_acls_badge () {
  create_coverage_badge \
    $(find_untagged_network_acls | wc -l) \
    $(find_all_network_acls| wc -l) \
    'https://img.shields.io/badge/managed--network--acls-$PERCENT_COVERED%25-$COLOR.svg'
}

write_network_acls_badge_to_s3 () {
  wget -O "$OUTPUT_PATH/network-acls-current-coverage.svg" $(create_network_acls_badge) >/dev/null 2>&1
  aws s3 mv --quiet --acl public-read --cache-control max-age=60 "${OUTPUT_PATH}/network-acls-current-coverage.svg" s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-network-acls-current-coverage.svg
}

write_dhcp_opts_badge_to_s3 &
write_ec2_albs_badge_to_s3 &
write_ec2_amis_badge_to_s3 &
write_ec2_elbs_badge_to_s3 &
write_ec2_instances_badge_to_s3 &
write_ec2_security_groups_badge_to_s3 &
write_ec2_volumes_badge_to_s3 &
write_igws_badge_to_s3 &
write_lambda_functions_badge_to_s3 &
write_network_acls_badge_to_s3 &
write_rds_instances_badge_to_s3 &
write_route_tables_badge_to_s3 &
write_s3_buckets_badge_to_s3 &
write_subnets_badge_to_s3 &
write_vpcs_badge_to_s3 &

wait
