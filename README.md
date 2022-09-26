## AWS GameDay Terragrunt Template

This is a template for a Terragrunt configuration for AWS GameDay. It is intended to be used to create the basic account infrastructure for a GameDay event.

How to use this template:
 1. Clone the repository locally.
 2. Run the preflight check `make preflight_check`
 3. Configure your aws profile `make configure_aws_profile`
 4. Update account id in `production/account.hcl`

We have provided a make file for those not familiar with terragrunt commands.

### Game Day Tip's.

The start of Game Day is hectic to say the least. 

Take a few minutes to read everything they give you.

Log into the account provided and create some CLI access and secret keys if they haven't been provided.

Don't go all least privileged too quick, attach the admin policy to your user and take a look around.

Take it for granted that if they give you infra... It's going to be a mess.

Get the team together, grab a whiteboard and draw out a plan, infra diagram and all.

List the steps to execute that plan and assign team members to each task (some have to be done in sequence, others can be done in parallel).

Don't be afraid to ask for help, the AWS staff and DevOps Team are there to help you.

### Game narrative:

Unicorn.Rental has overcome all the scandals and problems that have affected us in the past and is now becoming a successful start-up, reinforcing our status as the leader in the Legendary Animals Rental Market (LARM). Our success however is leading to new problems of scale. To address this, we have decided to move to a franchise operational model, where you and your counterparts will be operating one of our franchises. In addition to being able to launder funds through a myriad of shell companies ... I mean, provide a localized, community based front to our operations, this will allow us at HQ to invest in innovation and evolve our product offerings so that we remain number one!

Your main task is to build the infrastructure required to support the lease of unicorns, and then optimize that infrastructure and keep it running, You'll also need to manage the stock levels of unicorns and perform marketing-related tasks to promote your franchise and unlock new types of unicorns to rent out to the masses. You optionally might also have to physically track down unicorns that may have wandered out of our stables.

Time is of the essence though, because three hours after the game starts, will be the start of...

RAINBOW DAY!

You've heard of Black Friday and Cyber Monday, but those both pale in comparison to Rainbow Day! Rainbow Day will be our biggest customer event ever, and we expect to see the sky painted with rainbow-colored uni-contrails, but this will also have an impact on your franchise. During Rainbow Day, we expect you to have your infrastructure running and able to handle the load, to use AI services to ensure that you have the appropriate levels of stock on hand to ensure that unicorns get to hires, and to ensure that everyone knows how special Rainbow Day actually is! The franchises that do these tasks the best will have eternal glory bestowed upon them.

Key Objectives:

1. Build Infra for Unicorn.Rentals
2. Optimize Infra for Unicorn.Rentals
3. Keep Infra running for Unicorn.Rentals
4. Manage Unicorn Stock Levels
5. Perform Marketing Tasks
6. Track down Unicorns that have wandered out of the stables
7. Maintain service during Rainbow Day load.
8. Use AI services to ensure that you have the appropriate levels of stock on hand to ensure that unicorns get to hires.

The devops team believe that you are going to have to provision some compute (that can scale), expose the application running on that compute to the public.

You may need a database to store the unicorn stock levels and possibly a SES and some lambdas to handle marketing.

You may need to use some AI services (Sagemaker) to ensure that you have the appropriate levels of stock on hand to ensure that unicorns get to hires.

That's alot to stand up in three hours! Good luck! ☘️

### Okay let's get started. 🏁

In the terminal run `make vpc`

>This will create a three layer highly available VPC. With 2048 Available IP Addresses. Each subnet has been allocated 128 IPs so that leaves you 896 available IP's for any other resources you may need.
>>A bit like this: But with a much smaller CIDR range. https://docs.aws.amazon.com/quickstart/latest/vpc/architecture.html

The VPC has been configured with three NAT Gateways and an Internet Gateway. The NAT Gateway is used to allow the private subnets to access the internet. The Internet Gateway is used to allow the public subnets to access the internet.

VPC flow logs are enabled, and you can see them in cloudwatch.

### Logging and more logging. 📚

Now that we have our VPC up and running lets create more logging!! 

Logging is essential on gameday to be able to see what's actually gone wrong, be warned, the game day will include some *chaos*!!

In the terminal run `make log_buckets`

>This will create two s3 buckets, one for s3 access logs (who's been in my bucket?) and one for public load balancer logs.

### Compute *"I need more power scotty!"* 🔋

At some point we will definitely need more power. It is Rainbow Day after all. ECS clusters (Fargate Provider) are free unless you run something on them, so it cant hurt to stand up one of those. 

In the terminal run `make cluster`

>This will spin up an ECS cluster for running fargate tasks. 

We have tried to get you some cheeky points by setting half as on demand and the other half as spot. 

Its game day, they can't artificially change a regional spot price, can they? 

Hmm. Well if they do, you can change the balance between spot and on demand here. 
`production/us-east-1/network/clusters/ecs/common/application.yml`

### If you're not on the list, you ain't coming in 📝

Right lets get some security in place, we don't want to be hacked on gameday do we?

We will do this in phases, as some security groups reference another therefore, we must build them in a specific order.

In the terminal run `make security_groups_alb_endpoints`

When this is complete

In the terminal run `make security_groups_ecs_autoscaling_group`

When this is complete

In the terminal run `make security_groups_rds`

>This will create security groups for the public load balancer. ecs service, autoscaling group, rds database and vpc endpoints. 

You can completely customise these, just remember that you score points for well architected. So don't go full cowboy ;-). 

### Unicorns don't use the internet? 🚫

Now we are going to be using aws managed services. It's just a fact of life, something is going to have be kept in secrets or parameter store, and you don't want to send all of your valuable logs ect out over the public internet, it's time to create some private connections between these services and your VPC.

In the terminal run `make vpc_endpoints`

>This will create vpc endpoints for a ton of services. You can check them out in the console. I have attached a policy where needed and set a condition to deny any traffic not originating for your VPC. 

If you are interested the docs for endpoints are here. https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html

**Awazing! ;-). we have a network.**

Not much use at the moment as we need to expose the services we are going to build to the outside world.

### It's time to go public! 🍾

Let's create a load balancer.

In the terminal run `make public_load_balancer`

>This will create a public load balancer with a listener on port 80. You can add more listeners if you need to. I haven't added one for 443 as you will need to provision an ACM certificate for that.

Not hopeful for this on the day as im pretty confident they won't provide us with a domain. but you never know.

If they do. Jump in the console and add a 443 listener, redirect all traffic to the 80 listener. 

Don't forget to add the path, host and query greedy params if you do.

Docs are here. https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html [Redirect actions]

I have added a listener rule to 80 with an instance target group standing by for us. What's this for? Big hint is the word instance, we can use this target group for EC2 autoscaling groups. It's set to position 1 so any new listeners you add WONT take priority over this one. If you create a new listener move the existing one to the bottom in the console or traffic will flow to this one. 

### With great power, comes great responsibility (Decision time). 💭

For running your applications, we have set up two options.

1. EC2 autoscaling group with a launch template.
2. ECS Fargate service.

Its upto you. you can use both or either. Or start with one and migrate to the other. There are alternatives to these available e.g. Elastic Beanstalk, Lambda and Elastic Kubernetes Service (EKS).

>Choose wisely. This is game day, get something working, then make it right, then make it as fast, highly available, redundant and secure as you can. But, MAKE IT WORK first. 

#### Autoscaling Group

You can build the autoscaling group with `make autoscaling_group`

We have configured a default web app in the user data, you can change this to whatever you want. We would recommend using it for the first deployment to test e2e the that you are serving traffic. 

We have set this up to scale at 50% cpu load. In addition, it will spin up three t3.medium instances, one in each AZ and configure the machine using the user data template.

You can completely customise this configuration, by changing the variables in here: production/us-east-1/services/unicorn-rentals/autoscaling-group-ec2/terragrunt.hcl

We have left some obvious config options in the locals block for you.

Note that you can customise the machine configuration and install you applications in the templates/user_data.tftpl file. And we have commented out two alternative scaling options for you in the terragrunt.hcl file. 

If you wish to amend the scaling option un comment the one you wish to use and comment out the one you don't. Then re-run your makefile command.

Scaling options are:
* CPU - on by default.
* Predictive scaling: Tries to ramp up instances before you need them.
* Target Tracking: Sets a target value for a metric and scales up or down to meet that target. (This is the most elastic, but you will need to be able to calculate the request count on which to scale. Difficult to do without historic data..).

Once its up you can navigate to the load balancer public endpoint and see the response by using curl or the browser.

#### ECS Fargate

This should be more familiar. Containers! 

Now when we talk about scaling in terms of ec2 we talk in minutes. Even with a custom ami and no user data these things ain't exactly quick!

Containers on the other hand start in seconds. So all we need to wait for is the health check to pass.

We have to do some port shuffling here tho. With ec2 we can just expose the machine on port 80 no drama. 

For container its best practice to run these as non-root users. So we need to expose the container on a different port and then map that to port 80 on the container.

By different port we mean something above 3000 as all of those below are considered to be the OS ports. We have chosen 8443.

Therefore, we have set security-group rules and port mapping in the target group for 8443. If you are running you container on anything other than 8443 these will need to be changed.

>*Note: we have set the health check to /api/health this is the most common health check we can think of. It covers spring, apache, nginx ect. But that does not mean your app will pass on this path. You only need a status code of 200 or 302 to be returned so amend the path in the terragrunt to suit your needs.*
>>production/us-east-1/services/unicorn-rentals/ecs/service/terragrunt.hcl

You can build the ecs service with `make ecs_service`

>This will spin up an ecr for storing you container, an esc service powered by fargate and a couple of iam roles for the service and container.

Build your docker container locally. For those of you on a newish Mac ie ARM architecture you will need to use buildx with docker to create a linux/amd64 container.

Docs are here: https://docs.docker.com/desktop/multi-arch/

If you want to go all fancy you can create a multi arch container with manifest ect. Currently, all aws services except lambda support manifests. But be cautious. This won't score you any points with the AWS folk unless you specifically tell them you are doing it!

After you have your container you will need to push it to your ecr.

First we must authenticate against the ecr in your account. The command below will get authenticated credentials for you.

*Make sure you have the aws cli installed and the default profile set. See Additional info at the bottom to help here.*

`aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <repo url>`

Build your docker image:

`docker build --platform linux/amd64 -t devops-maintenance-page .`

*Note: In the above command I have set docker as an alias to buildx see docs here: https://docs.docker.com/desktop/multi-arch/*

Then tag you image as latest using the <repo url> as the container name. A bit like this:

`docker tag devops-maintenance-page:latest <repo url>:latest`

And finally push that image to the ecr.

`docker push <repo name>:latest`

Once the container has landed in the ecr you can deploy with a forced update.

Fargate will always deploy the container with the latest tag, so if you upload a new container make sure to force a new deployment in the console.

Docs are here: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/update-service.html

I have put a sample web app in the following public docker repo.

https://hub.docker.com/r/tim0git/devops-maintenance-page/tags

Once you have stood up the app you can navigate to the load balancer public endpoint and see the response by using curl or the browser.

After your infra is up you can work on your container and deploy it to the ecr.

>*Note: you will have to promote the listener rule for the ecs service above that of the autoscaling group. Do this in the console. Its two clicks. We have done this so if you choose ec2 autoscaling group to start with and move to ecs after you can migrate back and forth between the two easily by changing the rule priority.*
>>Docs are here: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/listener-update-rules.html [Reorder Rules]

For scaling we have added a target tracking policy that scales the desired count in relation to requests. We have set the scale out value at 300 request per target (although this may be too low). And set the maximum number of tasks to 24.

You are running on the smallest fargate task possible. 256 CPU and 512 MEMORY.

Now containers scale fast! So don't be afraid to tinker with these values to reach the optimum compute balance.

You can adjust these values in the local block here:

`production/us-east-1/services/unicorn-rentals/ecs/service/terragrunt.hcl`

Don't forget to run your make command again to update you're infra.

### Opps! I need somewhere to store my unicorns. (database) 📦

Now you may or may not need a database. But if you do, you can use this template to create one.

>"Decision paralysis"

We have tried to give you a broad spectrum of options here.

#### RDS

We have the tried and trusted rds. We have set this up as an autoscaling, postgres multi AZ instance.

You can create this with `make rds`

I haven't set up a read replica, if you need one you can do that in the console with two clicks.

Docs are here: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html

If you need to create a mysql instance you can do that by changing the values here.

`production/us-east-1/database/rds/terragrunt.hcl`

We have left the mysql values in a comment to the right of the postgres ones. 

Don't forget to change the port, parameters and enabled_cloudwatch_logs_exports values .. ;-).

Okay we can spice things up a bit with option 2.

#### Aurora Serverless.

This is a highly available fully scaling database.

You can create this with `make aurora_serverless`

Again this has been set up as a postgres db, but you can change the values here to mysql, and we have left the comments just as we did for rds.

`production/us-east-1/database/aurora/terragrunt.hcl`

> Be warned. Databases take 20 minutes to spin up!. So use that time wisely. There are some suggestions for additional services you can configure in the console at the end.

**Don't panic if you choose rds and then want aurora later on. You can convert rds to aurora reasonably easily in the console.**

Docs are here: https://aws.amazon.com/getting-started/hands-on/migrate-rdsmysql-to-auroramysql/

>One *GOTCHA* with databases. The database creds are generated for you. These are sensitive, so you won't see them in the console or the terminal after a plan.

We've got you covered.

Use `make get_aurora_database_credentials` or `make get_rds_database_credentials` once the database is up and running, and we will fetch them for you in to your terminal in plain text.

Finally, we have a wild card.

#### DynamoDB. NonSQL.

If you need one, we have laid out a fully autoscaling dynamodb with a global secondary index.

Open the file here. `production/us-east-1/database/dynamo/terragrunt.hcl` and change the value to keys that work for you.

You can create this with `make dynamodb`

This isn't a fully optimised dynamodb with local secondary indexes ect. But for game day it will be more than quick enough should you need a non sql database. IF you end up with a read heavy dynamodb consider using DAX. ;-).

All databases are encrypted and have automated backup / maintenance. We haven't added cross region replication as for the rds databases that would require a customer managed kms key.

We have tried to keep this simple and easy to work with. If you fancy going all SUPER highly redundant and replicating your backups to another Region have at it!.

#### RDS Proxy?

You may want to create an RDS proxy. 

This is a proxy that sits in front of your database and handles the connections. RDS Proxy is a great way to scale your database. It can also help with failover in your multi AZ deployment. For example you won't have to update the application with a new database url.

There is a 12-minute video here: https://www.youtube.com/watch?v=ULRnn6tIYu8

And it's easy to set up in the console. Docs are here: https://docs.amazonaws.cn/en_us/AmazonRDS/latest/UserGuide/rds-proxy-setup.html

#### Seeding your Database.

If we do have to create a database then it will need some data.

There are a million ways to get data into a database but here are a few links that may be of interest.

S3 Import: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PostgreSQL.S3Import.html

Database migration: https://docs.aws.amazon.com/dms/latest/sbs/dms-sbs-welcome.html

### Take a break, you've earned it ☕️.

We haven't added any lambda or api gateway modules to this template. For many of you this stuff is what you do every day therefore, you don't need help from us. If you want to use these services and are unfamiliar with them, please shout out on teams and we will mob it together.

Once you have your infra up and running, get a brew and have a look at all the other services AWS has to offer. 

We have compiled a list that are easy to configure in the console (click the big orange get started button) and will score you points on game day. 

>Additional Services:
>* WAF
>* Sagemaker
>* SES (Simple Email Service)
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

#### Set AWS Default Profile
If you are suing the aws cli then it may be helpful to set the default profile, this will prevent you from having to pass in the --profile flag with each command.

`make set_aws_cli_default_profile`

#### Detect drift

During the gameday AWS Staff may decide to inject a bit of chaos into your environment. This may involve changing network settings so that you are no longer serving traffic.

We have tried to help here.

Run `make detect_changes_to_security_groups` and or `make detect_changes_to_vpc` to allow to terraform to check for you.

You can fix the changes in the console or run the make commands for the specific resource and terraform will resolve the drift.

Alternatively AWS offer a service that can help diagnose network issues. Search in the console for Reach Analyser, it takes a few minutes to become familiar with but once you have used it a few times you will have full control over your network. 


#### Terraform local cache

If you need to remove local cache files and state lock then the below commands will recursively find these and remove them. 

`find . -type f -name ".terraform.lock.hcl" -prune -exec rm -rf {} \;`

`find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;`



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
13. [x] Create Fargate ECS Service
14. [x] Create DynamoDB Table
15. [x] Create Aurora DB
16. [x] Create RDS DB
------------------------------------------------------------------------
