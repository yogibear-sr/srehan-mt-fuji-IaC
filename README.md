# IaC related files are in this folder

## Main file is mount-fuji.tf - this builds an EC2 instance , load balancer and assign a front end web address to the instance. The security groups are quite strict to access to the web service is limited.

Pre-reqs
1) install terraform on your computer
2) install aws client
3) configure access to the AWS zone you're working in using aws configure
4) get your external web address by going to https://whatismyipaddress.com/
5) edit mount-fuji.tf file and add/modify your external IP to the load balancer security group on line 79
6) you can change the name of the website on line 123 and make the name to suit your preference
7) save the mount-fuji.tf file and exit

Building the instance
First check the validity of the terraform files as follows
terraform validate

If this comes back clean you can continue

terraform apply
...
...

A summary of the build is given and at the prompt type yes to continue to do the build

The build will output some details like web address, internal/external IP's and can take a couple of minutes to complete

There is no https certificate installed but this can be added if required

Once complete goto a web browser and type

http://srehan-httpd.ping.fuji.com:443/

Give the load balance a few minutes to do the heathchecks and show the instance as up and you should see the three repositories setup to do the three exercises.
