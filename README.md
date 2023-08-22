## Pre-requisite
- Install [terraform v1.5.2](https://www.terraform.io/downloads.html)
- Setup the [aws cli credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) with `default` profile name.

## Setup

1. Apply the terraform project.
```bash
terraform init; terraform apply
```

2. SSH into the master/puppetserver node to sign all agent certificate requests. (_ssh command is displayed in the output of the above step_)
```bash
sudo /opt/puppetlabs/bin/puppetserver ca sign --all
```
