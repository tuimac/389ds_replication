# The replication of 389 directory service
This repository have the tools of the test 389 directory service replication environment on EC2 instance AWS.
Operation system is Red Hat Enterprise Linux 8.4 whose amazon machine image ID is on template.yml parameter.

## How to use
### 1. Build Infrastructure
First things first, you need to clone this repository into your client environment. This repository have the cloudformation template to build the replication environment. There is the details on `template.yml`. <br/>
Before you create the stack, you have to have the valid authorization of createstack. You can configure that on IAM.<br/>
After you get the authorization of CreateStack, you just to execute `./launch.sh`.
