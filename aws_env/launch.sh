#!/bin/bash

STACK_NAME='rhel389dsmmr'

aws cloudformation create-stack --stack-name $STACK_NAME --region ap-northeast-3 --capabilities CAPABILITY_NAMED_IAM --template-body file://template.yml
