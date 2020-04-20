# ECS based Ads service

This is a simple NodeJS Ads service application with following endpoints

- `GET /ad`
- `POST /ad-event`

## Service infrastructure
The app is containerized and deployed in AWS ECS.
Service infrastrucute is built using Terraform and majority infrastructure components are build using Terraform modules by [Terrafom AWS Modules](https://github.com/terraform-aws-modules)

### Features provided by setup
1. Creates ECS instances cluster in a new VPC based on the latest official Amazon ECS AMI (docker 1.12 support)
1. Creates IAM instance roles to enable access to EC2, CloudWatch, ECS,  and Autoscaling services for the ECS container instances.
1. Creates ECS task and service for ads-app micro service application (nodejs-app)
1. The resulting service is accessible via internet-facing ALB's DNS. 
1. Provides service level load balancing via ALB (single access point for the service)
1. Provides fault-tolerance and self-healing; failed ECS cluster instance will be removed from it's Autoscaling group and new one launched to replace it

### If had more time (TODO)
Setup does not provide following features and  
1. Auto-scaling on ECS instances cluster and ECS service level (cpu and memory based triggered by Cloudwatch)
1. R53 Hosted zone setup, and creating ALB DNS record in new hosted zone.
1. ACM SSL certificate and integration with ALB
1. CI/CD pipline setup

## Setup infrastrucutre
### Install dependencies
Requires following programs to be installed
* terraform (version `0.12.16`)
* aws cli (version `1.15.58`)
* docker (version `19.03.8`)

### AWS credentials
Store your AWS credentials in environment variables or aws credentials file which is usually located at `~/.aws/credentials`

### Terraform vars
Open `terraform.tfvars` file and adjust the values according to your requirements.

### Create infrastructure
```
terraform init
terraform plan
terraform apply
```
This will output
* ECR repo URL to be used in [Deployment](#deployment) scripts.
* ALB DNS to access ads-app

## Deployment

### Create container image
For any new version of application create a new docker container image 
```bash
cd app
docker build -t ads-app .
```
### GET ECR login
To push new docker container image to ECR repo we need to get ECR login first using AWS CLI
```
aws ecr get-login-password --region <aws-region> | docker login --username AWS --a-stdin <aws-account-id>.dkr.ecr.<aws-region>.amazonaws.com/ads-app
```

### Push container image
```
docker tag ads-app:latest <aws-account-id>.dkr.ecr.<aws-region>.amazonaws.com/ads-app:latest
docker push <aws-account-id>.dkr.ecr.<aws-region>.amazonaws.com/ads-app:latest
```

### Deploy new version
Deploy a new app version `0.1` to ECS 
```
cd app
docker build -t ads-app .
docker tag ads-app:latest <aws-account-id>.dkr.ecr.<aws-region>.amazonaws.com/ads-app:0.1
docker push <aws-account-id>.dkr.ecr.<aws-region>.amazonaws.com/ads-app:0.1
cd ../deployment
CONTAINER_VERSION=0.1 sh deploy.sh
```
**Note:**
1. Deployment script may require you to install `jq`
1. If new version is not updated by ECS service, uncomment last line in `deploy.sh` to force deploy new version. (to be investigated)

## Destroy setup
```
terraform destroy
```
