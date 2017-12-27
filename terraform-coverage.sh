#!/bin/bash 
#set -euo pipefail

###
## VARS
###
AWS_PROFILE="default"
AWS_REGION="us-east-1"
MANAGED_TAG="Terraform"
BADGES_S3_BUCKET_NAME="terraform-infra-as-code-coverage-badges"

###
## FUNCTIONS
###

# Instances
find_all_instances () {
  aws ec2 describe-instances --region $AWS_REGION --profile "${AWS_PROFILE}" --query "Reservations[].Instances[].{ID: InstanceId}" --output text
}

find_untagged_instances () {
  aws ec2 describe-instances --region $AWS_REGION --profile "${AWS_PROFILE}" --query "Reservations[].Instances[].{ID: InstanceId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_ec2_instances_badge () {
  TOTAL_INSTANCES="$(find_all_instances | wc -l)"
  UNTAGGED_INSTANCES="$(find_untagged_instances | wc -l)"
  PERCENT_INSTANCES_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_INSTANCES}/${TOTAL_INSTANCES}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
  TOTAL_INSTANCES_COVERED=$(( TOTAL_INSTANCES - UNTAGGED_INSTANCES ))
  PERCENT_INSTANCES_COVERED=$(( 100 - PERCENT_INSTANCES_REMAINING ))
  
  if (( $PERCENT_INSTANCES_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_INSTANCES_COVERED >= 67 )) && (( $PERCENT_INSTANCES_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_INSTANCES_COVERED >= 34 )) && (( $PERCENT_INSTANCES_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi
  
  echo "https://img.shields.io/badge/managed--ec2--instances-$PERCENT_INSTANCES_COVERED%25-$COLOR.svg"
}

write_ec2_instances_badge_to_s3 () {
  wget -O '/tmp/ec2-instances-current-coverage.svg' $(create_ec2_instances_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/ec2-instances-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-ec2-instances-current-coverage.svg
}

# Security Groups
find_all_security_groups () {
  aws ec2 describe-security-groups --region $AWS_REGION --profile "${AWS_PROFILE}" --query "SecurityGroups[].{ID: GroupId}"  --output text
}

find_untagged_security_groups () {
  aws ec2 describe-security-groups --region $AWS_REGION --profile "${AWS_PROFILE}"  --query "SecurityGroups[].{ID: GroupId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_ec2_security_groups_badge () {
  TOTAL_SGS="$(find_all_security_groups | wc -l)"
  UNTAGGED_SGS="$(find_untagged_security_groups | wc -l)"
  PERCENT_SGS_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_SGS}/${TOTAL_SGS}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
  TOTAL_SGS_COVERED=$(( TOTAL_SGS - UNTAGGED_SGS ))
  PERCENT_SGS_COVERED=$(( 100 - PERCENT_SGS_REMAINING ))

  if (( $PERCENT_SGS_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_SGS_COVERED >= 67 )) && (( $PERCENT_SGS_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_SGS_COVERED >= 34 )) && (( $PERCENT_SGS_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi

  echo "https://img.shields.io/badge/managed--ec2--security--groups-$PERCENT_SGS_COVERED%25-$COLOR.svg"
}

write_ec2_security_groups_badge_to_s3 () {
  wget -O '/tmp/ec2-security-groups-current-coverage.svg' $(create_ec2_security_groups_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/ec2-security-groups-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-ec2-security-groups-current-coverage.svg
}

# AMIs
find_aws_account_id () {
  aws sts get-caller-identity --output text --query 'Account'
}

find_all_amis () {
  aws ec2 describe-images --region $AWS_REGION --profile "${AWS_PROFILE}" --owners $(find_aws_account_id) --query "Images[].ImageId" --output text
}

find_untagged_amis () {
  aws ec2 describe-images --region $AWS_REGION --profile "${AWS_PROFILE}" --owners $(find_aws_account_id)  --query "Images[].{ID: ImageId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_ec2_amis_badge () {
  TOTAL_AMIS="$(find_all_amis | wc -l)"
  UNTAGGED_AMIS="$(find_untagged_amis | wc -l)"
  PERCENT_AMIS_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_AMIS}/${TOTAL_AMIS}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
  TOTAL_AMIS_COVERED=$(( TOTAL_AMIS - UNTAGGED_AMIS ))
  PERCENT_AMIS_COVERED=$(( 100 - PERCENT_AMIS_REMAINING ))
  
  if (( $PERCENT_AMIS_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_AMIS_COVERED >= 67 )) && (( $PERCENT_AMIS_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_AMIS_COVERED >= 34 )) && (( $PERCENT_AMIS_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi

  echo "https://img.shields.io/badge/managed--ec2--amis-$PERCENT_AMIS_COVERED%25-$COLOR.svg"
}

write_ec2_amis_badge_to_s3 () {
  wget -O '/tmp/ec2-ami-current-coverage.svg' $(create_ec2_amis_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/ec2-ami-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-ec2-ami-current-coverage.svg
}

# Volumes
find_all_volumes () {
  aws ec2 describe-volumes --region $AWS_REGION --profile "${AWS_PROFILE}" --query "Volumes[].{ID: VolumeId}" --output text
}

find_untagged_volumes () {
  aws ec2 describe-volumes --region $AWS_REGION --profile "${AWS_PROFILE}"  --query "Volumes[].{ID: VolumeId}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_ec2_volumes_badge () {
  TOTAL_VOLUMES="$(find_all_volumes | wc -l)"
  UNTAGGED_VOLUMES="$(find_untagged_volumes | wc -l)"
  PERCENT_VOLUMES_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_VOLUMES}/${TOTAL_VOLUMES}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
  TOTAL_VOLUMES_COVERED=$(( TOTAL_VOLUMES - UNTAGGED_VOLUMES ))
  PERCENT_VOLUMES_COVERED=$(( 100 - PERCENT_VOLUMES_REMAINING ))
  
  if (( $PERCENT_VOLUMES_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_VOLUMES_COVERED >= 67 )) && (( $PERCENT_VOLUMES_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_VOLUMES_COVERED >= 34 )) && (( $PERCENT_VOLUMES_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi

  echo "https://img.shields.io/badge/managed--ec2--volumes-$PERCENT_VOLUMES_COVERED%25-$COLOR.svg"
}

write_ec2_volumes_badge_to_s3 () {
  wget -O '/tmp/ec2-volumes-current-coverage.svg' $(create_ec2_volumes_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/ec2-volumes-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-ec2-volumes-current-coverage.svg
}

# ALBs
find_all_albs () {
  aws elbv2 describe-load-balancers --region $AWS_REGION --profile "${AWS_PROFILE}" --query "LoadBalancers[].{ID: LoadBalancerArn}" --output text
}

find_untagged_albs () {
  aws elbv2 describe-load-balancers --region $AWS_REGION --profile "${AWS_PROFILE}" --query "LoadBalancers[].{ID: LoadBalancerArn}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_ec2_albs_badge () {
  TOTAL_ALBS="$(find_all_albs | wc -l)"
  UNTAGGED_ALBS="$(find_untagged_albs | wc -l)"
  PERCENT_ALBS_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_ALBS}/${TOTAL_ALBS}; i=int(pc); print (pc-i<0.5)?i:i+1 }" 2> /dev/null)
  TOTAL_ALBS_COVERED=$(( TOTAL_ALBS - UNTAGGED_ALBS ))
  PERCENT_ALBS_COVERED=$(( 100 - PERCENT_ALBS_REMAINING ))
  
  if (( $PERCENT_ALBS_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_ALBS_COVERED >= 67 )) && (( $PERCENT_ALBS_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_ALBS_COVERED >= 34 )) && (( $PERCENT_ALBS_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi

  echo "https://img.shields.io/badge/managed--ec2--albs-$PERCENT_ALBS_COVERED%25-$COLOR.svg"
}

write_ec2_albs_badge_to_s3 () {
  wget -O '/tmp/ec2-albs-current-coverage.svg' $(create_ec2_albs_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/ec2-albs-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-ec2-albs-current-coverage.svg
}

# ELBs
find_all_elbs () {
  aws elb describe-load-balancers --region $AWS_REGION --profile "${AWS_PROFILE}" --query "LoadBalancerDescriptions[].{ID: LoadBalancerName}" --output text
}

find_untagged_elbs () {
UNTAGGED=0
  for elb in `find_all_elbs`; do
    if
      aws elb describe-tags --region $AWS_REGION --profile "${AWS_PROFILE}" --load-balancer-names "${elb}" --query "TagDescriptions[].Tags[].Key" --output text | grep -v $MANAGED_TAG
    then
      ((UNTAGGED++))
    fi
  done
    echo $UNTAGGED
}

create_ec2_elbs_badge () {
  TOTAL_ELBS="$(find_all_elbs | wc -l)"
  UNTAGGED_ELBS="$(find_untagged_elbs | tail -1)"
  PERCENT_ELBS_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_ELBS}/${TOTAL_ELBS}; i=int(pc); print (pc-i<0.5)?i:i+1 }" 2> /dev/null)
  TOTAL_ELBS_COVERED=$(( TOTAL_ELBS - UNTAGGED_ELBS ))
  PERCENT_ELBS_COVERED=$(( 100 - PERCENT_ELBS_REMAINING ))
  
  if (( $PERCENT_ELBS_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_ELBS_COVERED >= 67 )) && (( $PERCENT_ELBS_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_ELBS_COVERED >= 34 )) && (( $PERCENT_ELBS_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi

  echo "https://img.shields.io/badge/managed--ec2--elbs-$PERCENT_ELBS_COVERED%25-$COLOR.svg"
}

write_ec2_elbs_badge_to_s3 () {
  wget -O '/tmp/ec2-elbs-current-coverage.svg' $(create_ec2_elbs_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/ec2-elbs-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-ec2-elbs-current-coverage.svg
}

# S3 Buckets
find_all_buckets () {
  BUCKET_LIST=$(aws s3api list-buckets --region $AWS_REGION --profile "${AWS_PROFILE}" --query "Buckets[].Name" --output text)
  echo $BUCKET_LIST | tr " " "\n"
}

find_untagged_s3_buckets () {
  for bucket in `find_all_buckets`; do
    if
      ! aws s3api get-bucket-tagging --region $AWS_REGION --profile "${AWS_PROFILE}" --bucket $bucket --query "TagSet[].Key[]" 2> /dev/null | sed 's/[][]//g' | grep -v $MANAGED_TAG
    then
      ((UNTAGGED++))
    fi
  done
    echo $UNTAGGED
}

create_s3_buckets_badge () {
  TOTAL_BUCKETS="$(find_all_buckets | wc -l)"
  UNTAGGED_BUCKETS="$(find_untagged_s3_buckets | tail -1)"
  
  PERCENT_BUCKETS_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_BUCKETS}/${TOTAL_BUCKETS}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
  TOTAL_BUCKETS_COVERED=$(( TOTAL_BUCKETS - UNTAGGED_BUCKETS ))
  PERCENT_BUCKETS_COVERED=$(( 100 - PERCENT_BUCKETS_REMAINING ))
  
  if (( $PERCENT_BUCKETS_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_BUCKETS_COVERED >= 67 )) && (( $PERCENT_BUCKETS_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_BUCKETS_COVERED >= 34 )) && (( $PERCENT_BUCKETS_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi

  echo "https://img.shields.io/badge/managed--s3--buckets-$PERCENT_BUCKETS_COVERED%25-$COLOR.svg"
}

write_s3_buckets_badge_to_s3 () {
  wget -O '/tmp/s3-buckets-current-coverage.svg' $(create_s3_buckets_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/s3-buckets-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-s3-buckets-current-coverage.svg
}

# Lambda Functions
find_all_lambda_functions () {
  aws lambda list-functions --profile "${AWS_PROFILE}" --region $AWS_REGION --query "Functions[].{ID: FunctionArn}" --output text
}

find_untagged_lambda_functions () {
  for func in `find_all_lambda_functions`; do
    if
      ! aws lambda list-functions --profile "${AWS_PROFILE}" --region $AWS_REGION --query "TagDescriptions[].Tags[].Key" | sed 's/[][]//g' | grep -v $MANAGED_TAG
    then
      ((UNTAGGED++))
    fi
  done
    echo $UNTAGGED
}

create_lambda_functions_badge () {
  TOTAL_FUNCS="$(find_all_lambda_functions| wc -l)"
  UNTAGGED_FUNCS="$(find_untagged_lambda_functions | tail -1)"
  PERCENT_FUNCS_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_FUNCS}/${TOTAL_FUNCS}; i=int(pc); print (pc-i<0.5)?i:i+1 }" 2> /dev/null)
  TOTAL_FUNCS_COVERED=$(( TOTAL_FUNCS - UNTAGGED_FUNCS ))
  PERCENT_FUNCS_COVERED=$(( 100 - PERCENT_FUNCS_REMAINING ))
  
  if (( $PERCENT_FUNCS_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_FUNCS_COVERED >= 67 )) && (( $PERCENT_FUNCS_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_FUNCS_COVERED >= 34 )) && (( $PERCENT_FUNCS_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi

  echo "https://img.shields.io/badge/managed--lambda--functions-$PERCENT_FUNCS_COVERED%25-$COLOR.svg"
}

write_lambda_functions_badge_to_s3 () {
  wget -O '/tmp/lambda-functions-current-coverage.svg' $(create_lambda_functions_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/lambda-functions-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-lambda-functions-current-coverage.svg
}

# RDS
find_all_rds_instances () {
  aws rds describe-db-instances --profile "${AWS_PROFILE}" --region $AWS_REGION --query "DBInstances[].{ID: DBInstanceArn}" --output text
}

find_untagged_rds_instances () {
  for db in `find_all_rds_instances`; do
    if
      ! aws rds list-tags-for-resource --profile "${AWS_PROFILE}" --region $AWS_REGION --resource-name $db --query "TagList[].Key" | grep -v $MANAGED_TAG
    then
      ((UNTAGGED++))
    fi
  done
    echo $UNTAGGED
}

create_rds_instances_badge () {
  TOTAL_RDS="$(find_all_rds_instances | wc -l)"
  UNTAGGED_RDS="$(find_untagged_rds_instances | tail -1)"
  PERCENT_RDS_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_RDS}/${TOTAL_RDS}; i=int(pc); print (pc-i<0.5)?i:i+1 }" 2> /dev/null)
  TOTAL_RDS_COVERED=$(( TOTAL_RDS - UNTAGGED_RDS ))
  PERCENT_RDS_COVERED=$(( 100 - PERCENT_RDS_REMAINING ))
  
  if (( $PERCENT_RDS_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_RDS_COVERED >= 67 )) && (( $PERCENT_RDS_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_RDS_COVERED >= 34 )) && (( $PERCENT_RDS_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi

  echo "https://img.shields.io/badge/managed--rds--instances-$PERCENT_RDS_COVERED%25-$COLOR.svg"
}

write_rds_instances_badge_to_s3 () {
  wget -O '/tmp/rds-instances-current-coverage.svg' $(create_rds_instances_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/rds-instances-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-rds-instances-current-coverage.svg
}

# VPC
find_all_vpcs () {
  aws ec2 describe-vpcs --profile "${AWS_PROFILE}" --region $AWS_REGION --query "Vpcs[].{ID: VpcId}" --output text
}

find_untagged_vpcs () {
  aws ec2 describe-vpcs --profile "${AWS_PROFILE}" --region $AWS_REGION --query "Vpcs[].{ID: VpcId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_vpc_badge () {
  TOTAL_VPC="$(find_all_vpcs| wc -l)"
  UNTAGGED_VPC="$(find_untagged_vpcs | wc -l)"
  PERCENT_VPC_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_VPC}/${TOTAL_VPC}; i=int(pc); print (pc-i<0.5)?i:i+1 }" 2> /dev/null)
  TOTAL_VPC_COVERED=$(( TOTAL_VPC - UNTAGGED_VPC ))
  PERCENT_VPC_COVERED=$(( 100 - PERCENT_VPC_REMAINING ))
  
  if (( $PERCENT_VPC_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_VPC_COVERED >= 67 )) && (( $PERCENT_VPC_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_VPC_COVERED >= 34 )) && (( $PERCENT_VPC_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi

  echo "https://img.shields.io/badge/managed--vpcs-$PERCENT_VPC_COVERED%25-$COLOR.svg"
}

write_vpcs_badge_to_s3 () {
  wget -O '/tmp/vpcs-current-coverage.svg' $(create_vpc_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/vpcs-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-vpcs-current-coverage.svg
}

# SUBNETS
find_all_subnets () {
  aws ec2 describe-subnets --profile "${AWS_PROFILE}" --region $AWS_REGION --query "Subnets[].{ID: SubnetId}" --output text
}

find_untagged_subnets () {
  aws ec2 describe-subnets --profile "${AWS_PROFILE}" --region $AWS_REGION --query "Subnets[].{ID: SubnetId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_subnets_badge () {
  TOTAL_SUBNETS="$(find_all_subnets| wc -l)"
  UNTAGGED_SUBNETS="$(find_untagged_subnets | wc -l)"
  PERCENT_SUBNETS_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_SUBNETS}/${TOTAL_SUBNETS}; i=int(pc); print (pc-i<0.5)?i:i+1 }" )
  TOTAL_SUBNETS_COVERED=$(( TOTAL_SUBNETS - UNTAGGED_SUBNETS ))
  PERCENT_SUBNETS_COVERED=$(( 100 - PERCENT_SUBNETS_REMAINING ))
  
  if (( $PERCENT_SUBNETS_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_SUBNETS_COVERED >= 67 )) && (( $PERCENT_SUBNETS_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_SUBNETS_COVERED >= 34 )) && (( $PERCENT_SUBNETS_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi

  echo "https://img.shields.io/badge/managed--subnets-$PERCENT_SUBNETS_COVERED%25-$COLOR.svg"
}

write_subnets_badge_to_s3 () {
  wget -O '/tmp/subnets-current-coverage.svg' $(create_subnets_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/subnets-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-subnets-current-coverage.svg
}

# ROUTE_TABLES
find_all_route_tables () {
  aws ec2 describe-route-tables --profile "${AWS_PROFILE}" --region $AWS_REGION --query "RouteTables[].{ID: RouteTableId}" --output text
}

find_untagged_route_tables () {
  aws ec2 describe-route-tables --profile "${AWS_PROFILE}" --region $AWS_REGION --query "RouteTables[].{ID: RouteTableId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_route_tables_badge () {
  TOTAL_ROUTE_TABLES="$(find_all_route_tables| wc -l)"
  UNTAGGED_ROUTE_TABLES="$(find_untagged_route_tables | wc -l)"
  PERCENT_ROUTE_TABLES_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_ROUTE_TABLES}/${TOTAL_ROUTE_TABLES}; i=int(pc); print (pc-i<0.5)?i:i+1 }" )
  TOTAL_ROUTE_TABLES_COVERED=$(( TOTAL_ROUTE_TABLES - UNTAGGED_ROUTE_TABLES ))
  PERCENT_ROUTE_TABLES_COVERED=$(( 100 - PERCENT_ROUTE_TABLES_REMAINING ))
  
  if (( $PERCENT_ROUTE_TABLES_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_ROUTE_TABLES_COVERED >= 67 )) && (( $PERCENT_ROUTE_TABLES_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_ROUTE_TABLES_COVERED >= 34 )) && (( $PERCENT_ROUTE_TABLES_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi

  echo "https://img.shields.io/badge/managed--route--tables-$PERCENT_ROUTE_TABLES_COVERED%25-$COLOR.svg"
}

write_route_tables_badge_to_s3 () {
  wget -O '/tmp/route-tables-current-coverage.svg' $(create_route_tables_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/route-tables-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-route-tables-current-coverage.svg
}
# INTERNET GATEWAY
find_all_igws () {
  aws ec2 describe-internet-gateways --profile "${AWS_PROFILE}" --region $AWS_REGION --query "InternetGateways[].{ID: InternetGatewayId}" --output text
}

find_untagged_igws () {
  aws ec2 describe-internet-gateways --profile "${AWS_PROFILE}" --region $AWS_REGION --query "InternetGateways[].{ID: InternetGatewayId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_igws_badge () {
  TOTAL_IGWS="$(find_all_igws | wc -l)"
  UNTAGGED_IGWS="$(find_untagged_igws | wc -l)"
  PERCENT_IGWS_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_IGWS}/${TOTAL_IGWS}; i=int(pc); print (pc-i<0.5)?i:i+1 }" )
  TOTAL_IGWS_COVERED=$(( TOTAL_IGWS - UNTAGGED_IGWS ))
  PERCENT_IGWS_COVERED=$(( 100 - PERCENT_IGWS_REMAINING ))
  
  if (( $PERCENT_IGWS_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_IGWS_COVERED >= 67 )) && (( $PERCENT_IGWS_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_IGWS_COVERED >= 34 )) && (( $PERCENT_IGWS_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi

  echo "https://img.shields.io/badge/managed--internet--gateways-$PERCENT_IGWS_COVERED%25-$COLOR.svg"
}

write_igws_badge_to_s3 () {
  wget -O '/tmp/internet-gateways-current-coverage.svg' $(create_igws_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/internet-gateways-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-internet-gateways-current-coverage.svg
}

# DHCP OPTION SETS
find_all_dhcp_opts () {
  aws ec2 describe-dhcp-options --profile "${AWS_PROFILE}" --region $AWS_REGION --query "DhcpOptions[].{ID: DhcpOptionsId}" --output text
}

find_untagged_dhcp_opts () {
  aws ec2 describe-dhcp-options --profile "${AWS_PROFILE}" --region $AWS_REGION --query "DhcpOptions[].{ID: DhcpOptionsId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_dhcp_opts_badge () {
  TOTAL_DHCP_OPTS="$(find_all_dhcp_opts | wc -l)"
  UNTAGGED_DHCP_OPTS="$(find_untagged_dhcp_opts | wc -l)"
  PERCENT_DHCP_OPTS_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_DHCP_OPTS}/${TOTAL_DHCP_OPTS}; i=int(pc); print (pc-i<0.5)?i:i+1 }" )
  TOTAL_DHCP_OPTS_COVERED=$(( TOTAL_DHCP_OPTS - UNTAGGED_DHCP_OPTS ))
  PERCENT_DHCP_OPTS_COVERED=$(( 100 - PERCENT_DHCP_OPTS_REMAINING ))
  
  if (( $PERCENT_DHCP_OPTS_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_DHCP_OPTS_COVERED >= 67 )) && (( $PERCENT_DHCP_OPTS_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_DHCP_OPTS_COVERED >= 34 )) && (( $PERCENT_DHCP_OPTS_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi

  echo "https://img.shields.io/badge/managed--dhcp--option--sets-$PERCENT_DHCP_OPTS_COVERED%25-$COLOR.svg"
}

write_dhcp_opts_badge_to_s3 () {
  wget -O '/tmp/dhcp-opts-current-coverage.svg' $(create_dhcp_opts_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/dhcp-opts-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-dhcp-opts-current-coverage.svg
}

# NETWORK ACLS
find_all_network_acls () {
  aws ec2 describe-network-acls --profile "${AWS_PROFILE}" --region $AWS_REGION --query "NetworkAcls[].{ID: NetworkAclId}" --output text
}

find_untagged_network_acls () {
  aws ec2 describe-network-acls --profile "${AWS_PROFILE}" --region $AWS_REGION --query "NetworkAcls[].{ID: NetworkAclId, Tag: Tags[].Key}" --output json | jq -c '.[]' | grep -v $MANAGED_TAG
}

create_network_acls_badge () {
  TOTAL_NETWORK_ACLS="$(find_all_network_acls| wc -l)"
  UNTAGGED_NETWORK_ACLS="$(find_untagged_network_acls | wc -l)"
  PERCENT_NETWORK_ACLS_REMAINING=$(awk "BEGIN { pc=100*${UNTAGGED_NETWORK_ACLS}/${TOTAL_NETWORK_ACLS}; i=int(pc); print (pc-i<0.5)?i:i+1 }" )
  TOTAL_NETWORK_ACLS_COVERED=$(( TOTAL_NETWORK_ACLS - UNTAGGED_NETWORK_ACLS ))
  PERCENT_NETWORK_ACLS_COVERED=$(( 100 - PERCENT_NETWORK_ACLS_REMAINING ))
  
  if (( $PERCENT_NETWORK_ACLS_COVERED == 100 )); then
    COLOR=green
  elif (( $PERCENT_NETWORK_ACLS_COVERED >= 67 )) && (( $PERCENT_NETWORK_ACLS_COVERED <= 99 )); then
      COLOR=yellow
  elif (( $PERCENT_NETWORK_ACLS_COVERED >= 34 )) && (( $PERCENT_NETWORK_ACLS_COVERED <= 66 )); then
      COLOR=orange
  else
      COLOR=red
  fi

  echo "https://img.shields.io/badge/managed--network--acls-$PERCENT_NETWORK_ACLS_COVERED%25-$COLOR.svg"
}

write_network_acls_badge_to_s3 () {
  wget -O '/tmp/network-acls-current-coverage.svg' $(create_network_acls_badge) >/dev/null 2>&1
  aws s3 mv --profile "${AWS_PROFILE}" --quiet --acl public-read --cache-control max-age=60 /tmp/network-acls-current-coverage.svg s3://"$BADGES_S3_BUCKET_NAME"/"$AWS_REGION"-network-acls-current-coverage.svg
}

# CLOUDFRONT
find_all_cloudfront_distros () {
  aws cloudfront list-distributions --profile "${AWS_PROFILE}" --region $AWS_REGION
}

###
## What DO?
###

write_ec2_instances_badge_to_s3 &
write_ec2_security_groups_badge_to_s3 &
write_ec2_amis_badge_to_s3 &
write_ec2_volumes_badge_to_s3 &
write_ec2_albs_badge_to_s3 &
write_ec2_elbs_badge_to_s3 &
write_lambda_functions_badge_to_s3 &
write_rds_instances_badge_to_s3 &
write_vpcs_badge_to_s3 &
write_subnets_badge_to_s3 &
write_route_tables_badge_to_s3 &
write_igws_badge_to_s3 &
write_dhcp_opts_badge_to_s3 &
write_network_acls_badge_to_s3 &
write_s3_buckets_badge_to_s3 

###
## WHAT NEXT?
###

## CLOUDFRONT DISTROS
#find_all_cloudfront_distros

## CLOUDTRAIL TRAILS
## SQS
 
