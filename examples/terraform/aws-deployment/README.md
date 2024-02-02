# AWS example Terraform deployment

> [!CAUTION]
> The basic example here does not configure TLS support for example brevity and should be used for testing purposes only.
> For further information please see [TLS Notes](#tls-notes)

This Terraform example shows a minimal Anaml deployment in AWS. It will deploy Anaml to an EKS cluster and make the application available through a public [ALB](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) using the EKS [aws-load-balancer-conrtoller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/).

Anaml has a Terraform module repository at https://github.com/simple-machines/anaml-terraform-registry. This example uses the [app-all](https://github.com/simple-machines/anaml-terraform-registry/tree/main/modules/app-all) module for deploying Anaml on top of EKS.



## AWS Resource created
This Terraform will create the below billable resource in AWS

 - [RDS](https://aws.amazon.com/rds/) PostgreSQL database
 - [EKS](https://aws.amazon.com/eks/) Kubernetes cluster
 - [ALB](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) Application Load Balancer
 - [S3](https://aws.amazon.com/s3/) bucket


## File description
  - [anaml.tf](./anaml.tf). This file contains Terraform code for deploying Anaml to a EKS cluster and setting Anaml configuration vales.
  - [aws_eks.tf](./aws_eks.tf). This file contains Terraform code to create a EKS cluster. If you are deploying to an exiting EKS cluster you can remove this file.
  - [aws_rds](./aws_rds.tf). This file contains Terraform code to create a RDS PostgreSQL instance. If you are deploying to an existing PostgreSQL server, you can remove this file.
  - [aws_vpc.tf](./aws_vpc.tf). This file contains Terraform code for create a VPC needed for EKS. If you are deploying to an existing VPC on to an existing EKS cluster you can remove this file.
  - [aws_s3.tf](./aws_s3.tf). This file contains Terraform code to create a bucket for Anaml checkpoint data.

## Checkpoint bucket
Anaml requires a s3 bucket to store internal anaml checkpoint metadata. You must provide a unique bucket name when asked by Terraform

## Deploying Terraform
[TODO]

## Post deploy setup
- [TODO] Notes on configuring source / destinations. Links to docs?
- [TODO] links to a tutorial / walkthrough?

## TLS Notes
For quick-start brevity, this example does not configure Anaml to use TLS. TLS requires you to own a domain name and the exact setup depends on your DNS and certificate authority which vary greatly between users.

With no TLS, all usernames/passwords sent through the login form will be sent plain text over the internet and viewable by third parties. All data showed in the UI will also be viewable by third parties. We recommend all deployments enable TLS and non TLS only use non sensitive test date.

To enable TLS you will need to own a domain name which you have access to control the DNS. We recommend using [AWS Certificate Manager](https://aws.amazon.com/certificate-manager) and the [aws-load-balancer-conrtoller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/guide/ingress/annotations/#tls) TLS support by adding the below annotation to the [anaml.tf](./anaml.tf) `kubernetes_ingress_annotations` definition:

```
alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-west-2:xxxxx:certificate/xxxxxxx
```

We also recommend removing the below lines from the `anaml.tf` file once a certificate is set up:

```
  override_anaml_server_enable_secure_cookies = false
  override_anaml_server_enable_hsts           = false
```

And finally adding the host name of the certificate to the `anaml.tf` file, i.e.:
```
hostname = www.example.com
```

See the [hostname](https://github.com/simple-machines/anaml-terraform-registry/tree/main/modules/app-all#input_hostname) documentation.

### Bastion host access
If you do not have access to a domain and certificate you can change the `alb.ingress.kubernetes.io/scheme` value to `internal` in `anaml.tf` `kubernetes_ingress_annotations` and then use a bastion host as SOCKS proxy.
This restricts access to anaml from inside the private VPC only.


#### Step One: Create a key pair
First create a key pair as described [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html).

#### Step Two: Crate a bastion host in the VPC public subnet
Then use the below Terraform replacing `key_name` value with the name of the key pair you just created.

```
data "aws_ami" "amazon-linux-2" {
 most_recent = true


 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }


 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

resource "aws_security_group" "allow_bastion_ssh" {
  name        = "allow_bastion_ssh"
  description = "Allow external SSH access to the bastion host"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "anaml"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_to_bastion" {
  security_group_id = aws_security_group.allow_bastion_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_bastion_egress" {
  security_group_id = aws_security_group.allow_bastion_ssh.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t3.micro"
  associate_public_ip_address = true
  subnet_id = module.vpc.public_subnets[0]

  vpc_security_group_ids = [
    aws_security_group.allow_bastion_ssh.id
  ]

  key_name = "changeme"

  tags = {
    Name = "bastion"
  }
}
```

#### Step four: Copy the ALB dns name

  1. Open the load balancers page in the AWS Console
  2. Select the `k8s-anaml` load balancer
  3. Copy the **DNS name** for subsequent steps. i.e. "k8s-anaml-anaml-80127eaf11-0000000000.ap-southeast-2.elb.amazonaws.com"

#### Step five: Configure proxy settings
Setup an SSH Tunnel using local port forwarding, replace `DNS_NAME` with the value copied in the previous step and `BASTION_IP_ADDRESS` with the public ipv4 displayed in the ec2 console for the bastion host we created

```
ssh -i mykeypair.pem -N -L 8157:DNS_NAME:80 ec2-user@BASTION_IP_ADDRESS
```

#### Step six: Open Anaml in web browser
Open a web browser and visit http://localhost:8175