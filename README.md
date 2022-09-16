## AWS GameDay Terragrunt Template

This is a template for a Terragrunt configuration for AWS GameDay. It is intended to be used to create the basic account infrastructure for a GameDay event.

How to use this template:
 1. Clone the repository locally.
 2. Run the preflight check `make preflight check`
 3. Configure your aws profile `make configure aws profile`
 4. Update account id in `production/account.hcl`

We have provided a make file for those not familiar with terragrunt commands.

### Okay let's get started. 🏁

In the terminal run `make vpc`

>This will create a three layer highly available VPC. With 2048 Available IP Addresses. Each subnet has been allocated 128 IP's so that leaves you 896 available IP's for any other resources you may need.
>>A bit like this: But with a much smaller CIDR range. https://docs.aws.amazon.com/quickstart/latest/vpc/architecture.html

The VPC has been configured with three NAT Gateways and a Internet Gateway. The NAT Gateway is used to allow the private subnets to access the internet. The Internet Gateway is used to allow the public subnets to access the internet.

VPC flow logs are enabled and you can see them in cloudwatch.

### Logging and more logging. 📚

Now that we have our VPC up and running lets create more logging!! 

Logging is essential on gameday to be able to see whats actually gone wrong, be warned, the game day will include some *chaos*!!

In the terminal run `make log buckets`

>This will create two s3 buckets, one for s3 access logs (who's been in my bucket?') and one for public load balancer logs.

### Compute *"i need more power scotty!"* 🔋

At some point we will definitely need more power. It is Rainbow Day after all. ECS clusters (Fargate Provider) are free unless you run something on them so it cant hurt to stand up one of those. 

In the terminal run `make cluster`

>This will spin up an ECS cluster for running fargate tasks. 

We have tried to get you some cheeky points by setting half as on demand and the other half as spot. 

Its game day, they can't artificially change a regional spot price, can they? 

Hmm. Well if they do, you can change the balance between spot and on demand here. 
`production/us-east-1/network/clusters/ecs/common/application.yml`

### If your not on the list, you ain't coming in 📝

Right lets get some security in place, we don't want to be hacked on gameday do we?

In the terminal run `make security groups`

>This will create security groups for the public load balancer. ecs service, autoscaling group, rds database and vpc endpoints. 

You can completely customise these, just remember that you score points for well architected. So don't go full cowboy ;-). 

### How about we don't use the internet? 🚫

Now we are going to be using aws managed services. Its just a fact of life, something is going to have be kept in secrets or parameter store and you dont want to send all of your valuable logs ect out over the public internet so its time to create some private connections between these services and your VPC.

In the terminal run `make vpc endpoints`

>This will create vpc endpoints for a ton of services. You can check them out in the console. I have attached a policy where needed and set a condition to deny any traffic not originating for your VPC. 

If you are interested the docs for endpoints are here. https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html

**Awazing! ;-). we have a network.**

Not much use at the moment as we need to expose the services we are going to build to the outside world.

### It's time to go public! 🍾

Let's create a load balancer.

In the terminal run `make public load balancer`

>This will create a public load balancer with a listener on port 80. You can add more listeners if you need to. I haven't added one for 443 as you will need to provision an ACM certificate for that.

Not hopeful for this on the day as im pretty confident they won't provide us with a domain. but you never know.

If they do. Jump in the console and add a 443 listener, redirect all traffic to the 80 listener. 

Don't forget to add the path, host and query greedy params if you do.

Docs are here. https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html [Redirect actions]

I have added a listener rule to 80 with an instance target group standing by for us. Whats this for? Big hint is the word instance, we can use this target group for EC2 autoscaling groups. Its set to position 1 so any new listeners you add should take priority over this one. If not move it to the bottom in the console or traffic will flow to this one. 

### With great power, comes great responsibility (Decision time). 💭

For running your applications, we have set up two options.

1. EC2 autoscaling group with a launch template.
2. ECS Fargate service.

Its upto you. you can use both or either. Or start with one and migrate to the other. There are alternatives to these available eg Elastic Beanstalk, Lambda and Elastic Kubernetes Service (EKS).

>Choose wisely. This is game day, get something working, then make it right, then make it as fast, highly available, redundant and secure as you can. But, MAKE IT WORK first. 

you can build the autoscaling group with `make autoscaling group`

once its up you can navigate to the load balancer public endpoint and see the response by using curl or the browser.

You can build the ecs service with `make ecs service`

once its up you can navigate to the load balancer public endpoint and see the response by using curl or the browser.

### Opps! I need somewhere to store my stuff. (database) 📦

Now you may or may not need a database. But if you do, you can use this template to create one.

>"Decision paralysis"

We have tried to give you a broad spectrum of options here.

#### RDS

We have the tried and trusted rds. We have set this up as a autoscaling, postgres multi AZ instance. I haven't set up a read replica, if you need one you can do that in the console with two clicks.

If you need to create a mysql instance you can do that by changing the values here.

`production/us-east-1/database/rds/terragrunt.hcl`

We have left the mysql values in a comment to the right of the postgres ones. Don't forget to change the port, parameters and enabled_cloudwatch_logs_exports values .. ;-).

Okay we can spice things up a bit with option 2.

#### Aurora Serverless.

This is a highly available fully scaling database.

You can create this with `make aurora serverless`

Again this has been set up as a postgres db, but you can change the values here to mysql and we have left the comments just as we did for rds.

`production/us-east-1/database/aurora/terragrunt.hcl`

> Be warned. Databases take 20 min's to spin up!. So use that time wisely. There are some suggestions for additional services you can configure in the console at the end.

**Don't panic if you choose rds and then want aurora later on. You can convert rds to aurora ect reasonably easily in the console.**

>One *GOTCHA* with aurora. The database creds are generated for you. These are sensitive so you wont see them in the console or the terminal after a plan.

We've got you covered.

Use `make get aurora database credentials` once the database is up and running and we will fetch them for you in to your terminal in plain text. 

Finally, we have a wild card.

#### DynamoDB. NonSQL.

If you need one, we have laid out a fully autoscaling dynamodb with a global secondary index.

Open the file here. `production/us-east-1/database/dynamo/terragrunt.hcl` and change the value to keys that work for you.

You can create this with `make dynamodb`

This isn't a fully optimised dynamodb with local secondary indexes ect. But for game day its will be more than quick enough should you need a non sql database. IF you end up with a read heavy dynamodb consider using DAX. ;-).

All databases are encrypted and have automated backup / maintenance. We haven't added cross region replication as for the rds databases that would require a customer managed kms key.

We have tried to keep this simple and easy to work with. If you fancy going all SUPER highly redundant and replicating your backups to another Region have at it!.
### Take a break, you've earned it ☕️.

Once you have your infra up and running, get a brew and have a look at all the other services AWS has to offer. 

We have compiled a list that are easy to configure in the console (click the big orange get started button) and will score you points on game day. 

>Additional Services:
>* WAF
>* Security Hub
>* Config
>* Guard Duty
>* Macie
>* Trusted Advisor
>* Cloud Trail
>* Inspector
>* Shield
>* AWS Compute Optimizer
>* Detective
>* RDS Proxy

### Additional Info:
If you are suing the aws cli then it may be helpful to set the default profile, this will prevent you from having to pass in the --profile flag with each command.

`make set aws cli default profile`

------------------------------------------------------------------------------------------------------------------------------
### TODO
1. [x] Create S3 Access Log Bucket
2. [x] Create VPC
3. [x] Create ECS Cluster
4. [x] Create Public ALB Log bucket
5. [x] Create Public ALB Security Group
6. [x] Create AutoScaling Group Security Group
7. [x] Create ECS Service Security Group
8. [x] Create RDS Security Group
9. [x] Create VPC Endpoints Security Group
10. [x] Create VPC Endpoints
11. [x] Create Public ALB
12. [x] Create AutoScaling Group
13. [ ] Create Fargate ECS Service
14. [x] Create DynamoDB Table
15. [x] Create Aurora DB
16. [x] Create RDS DB
------------------------------------------------------------------------

