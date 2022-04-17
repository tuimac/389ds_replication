# The replication of 389 directory service
This repository have the tools of the test 389 directory service replication environment on EC2 instance AWS.
Operation system is Red Hat Enterprise Linux 8.4 whose amazon machine image ID is on template.yml parameter.

## How to use
### 1. Build Infrastructure
First things first, you need to clone this repository into your client environment. This repository have the cloudformation template to build the replication environment. There is the details on `template.yml`.<br/>
Before you create the stack, you have to have the valid authorization of createstack. You can configure that on IAM.<br/>
After you get the authorization of CreateStack, you just to execute `./launch.sh`.
The cloudformation stack create the environment like below.

![Untitled Diagram drawio (3)](https://user-images.githubusercontent.com/18078024/163709454-0a81ca16-f14b-47fa-8d38-4797dbc21a8a.png)

### 2. Install 389 directory service
You can use the utility `ldap.sh` to install 389 directory service into your OS. But this utility script support only Red Hat Enterprise linux.<br/>
Before you use the utility, you have to change the variable `INSTANCE` to set 389ds instance name.
