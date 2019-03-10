# Simple website on AWS using Terraform

## Prerequisites

1. [Registered domain](https://www.namecheap.com)
1. [AWS account](https://console.aws.amazon.com)
1. [Zoho/Fastmail/Gsuite account](https://www.zoho.com/signup.html)
1. [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)

## Setup

### AWS config

Before you start, it is recommended to an IAM user instead of using the root account.

Ensure that you have the following AWS configuration set up on your computer

``` bash
# ~/.aws/credentials
[example]
aws_access_key_id = INSERT_AWS_ACCESS_KEY_ID_HERE
aws_secret_access_key = INSERT_AWS_SECRET_ACCESS_KEY_HERE

# ~/.aws/config
[example]
region = INSERT_REGION
```

### Domain verification

Go to your email provider and register your custom domain. Most email hosting services allow multiple verification methods, so look for a "TXT Record method" and copy the record name into `email_verification_record` under `vars.tfvars`

## Usage

### Apply

You are now ready to apply the terraform configuration

```
terraform init && terraform apply -var-file="vars.tfvars"
```

When you apply the plan for the first time, the whole process will most likely pause at the ACM validation stage. Don't cancel, just let it wait and proceed to setting up the NS records

### Setup NS records

Go to Route53 and copy the NS configurations into your domain registrar's configuration page, overwriting the current NS records. You will need to wait for the NS records to propagate.

You can monitor the state of DNS propagation using `dig` or [whatsmydns](https://www.whatsmydns.net)

