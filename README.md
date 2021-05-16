# IaC related files are in this folder

## Main file is mount-fuji.tf - this builds an EC2 instance , load balancer and assign a front end web address to the instance. The security groups are quite strict to access to the web service is limited.

### Pre-reqs
1) install terraform on your computer
2) install aws client
3) configure access to the AWS zone you're working in using aws configure
4) get your external web address by going to https://whatismyipaddress.com/
5) edit mount-fuji.tf file and add/modify your external IP to the load balancer security group on line 79
6) you can change the name of the website on line 123 and make the name to suit your preference
7) save the mount-fuji.tf file and exit

### Building the instance

After downloading the code from git , initialise terraform as follows (to download the plugins and providers)

$ terraform init

Next check validity of the terraform file(s) , mount-fuji.tf as follows

$ terraform validate

If this comes back clean you can continue

$ terraform apply
...
...

A summary of the build is given and at the prompt type yes to continue to do the build

The build will output some details like web address, internal/external IP's and can take a couple of minutes to complete

There is no https certificate installed but this can be added if required

Once build is complete, an number of outputs are given for information purposes ,  goto a web browser and using the DNS record name (https://srehan-httpd.ping.fuji.com:443) added type

http://\<DNS RECORD\>.ping.fuji.com:443/

You will probably need to wait a few minutes for the EC2 instance to fully build and the load balancer to complete health checks and show the instance as up
After the interval you should see the three repositories setup to do the three exercises.

If you want you can ssh to the ec2 instance using the external IP from the output as follows

$ ssh -i mount-fuji.pem ec2-user@[external IP]

##  Removing all the components

Once your complete with reading all the details , all the components in this build can be easily deleted as follows

$ terraform destroy
...
..

A summary of the components to delete will be presented, say yes at the prompt and this will ONLY delete what was build above and nothing else will be touched.
