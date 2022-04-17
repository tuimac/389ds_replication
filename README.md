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
After the changing the variable, you execute the utility script `sudo ./ldap.sh server-inatall`.

### 3. Create the consumer
You have to log into the secondary server through SSH. Then, you execute the utility `sudo ./ldap.sh secondary` in 389ds_replication/ directory. The command create the replication manager to handle the replication.<br/>
```bash
[ec2-user@secondary 389ds_replication]$ sudo ./ldap.sh secondary
Enter password for cn=Directory Manager on ldaps://secondary.tuimac.com: <- ex) P@sssw0rd
Enter replication manager password: <- ex) P@sssw0rd
Confirm replication manager password: <- ex) P@sssw0rd 
Successfully created replication manager: cn=replication manager,cn=config
Enter password for cn=Directory Manager on ldaps://secondary.tuimac.com: <- ex) P@sssw0rd
Replication successfully enabled for "dc=tuimac,dc=com"
```
Second, you switch to log into the primary server, go to 389ds_replication/ directory and you do `sudo ./ldap.sh primary` to create the replication manager and the replication agreement to send the user information from primary to secondary.<br/>
```bash
[ec2-user@primary 389ds_replication]$ sudo ./ldap.sh primary
Enter password for cn=Directory Manager on ldaps://primary.tuimac.com: <- ex) P@sssw0rd
Enter replication manager password: <- ex) P@sssw0rd
Confirm replication manager password: <- ex) P@sssw0rd
Successfully created replication manager: cn=replication manager,cn=config
Enter password for cn=Directory Manager on ldaps://primary.tuimac.com: <- ex) P@sssw0rd
Replication successfully enabled for "dc=tuimac,dc=com"
Enter password for cn=Directory Manager on ldaps://primary.tuimac.com: <- ex) P@sssw0rd
Successfully created replication agreement "test"
Agreement initialization started...

```
To check the replication status, you can execute `./ldap.sh rep-monitor`. For example, you receive the result from the command like below.<br/>
```json
{
    "type": "list",
    "items": [
        {
            "agmt-name": [
                "test"
            ],
            "replica": [
                "secondary.tuimac.com:389"
            ],
            "replica-enabled": [
                "on"
            ],
            "update-in-progress": [
                "FALSE"
            ],
            "last-update-start": [
                "20220417110412Z"
            ],
            "last-update-end": [
                "20220417110412Z"
            ],
            "number-changes-sent": [
                "2:3/0 "
            ],
            "number-changes-skipped": [
                "unavailable"
            ],
            "last-update-status": [
                "Error (0) Replica acquired successfully: Incremental update succeeded"
            ],
            "last-init-start": [
                "20220417105407Z"
            ],
            "last-init-end": [
                "20220417105410Z"
            ],
            "last-init-status": [
                "Error (0) Total update succeeded"
            ],
            "reap-active": [
                "0"
            ],
            "replication-status": [
                "Not in Synchronization: supplier (625bf1d0000000020000) consumer (Unavailable) State (green) Reason (error (0) replica acquired successfully: incremental update succeeded)"
            ],
            "replication-lag-time": [
                "unavailable"
            ]
        }
    ]
}
```
