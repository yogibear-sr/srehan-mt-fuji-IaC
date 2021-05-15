# mount-fuji IaC exercise
# author: Subhash Rehan
provider "aws" {
  region = "us-east-2"
}

# setup EC2 instance security group"
resource "aws_security_group" "mount-fuji-ssh-http" {
  name        = "mount-fuji-ssh-http"
  description = "allow ssh and http traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["86.21.204.249/32"]
    description = "Allow ssh access from Subhash IP only"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
    description = "Allow ssh access from servers on local LAN"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["86.21.204.249/32", "172.31.0.0/16"]
    description = "Allow http access from Subhash IP and the load balancer"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    description = "Allow All outgoing access"
  }


  tags = {
        Name = "Project-mount-fuji"
  }

}

# create EC2 instance on default subnet and do some post build tasks
resource "aws_instance" "mount-fuji" {
  ami               = "ami-077e31c4939f6a2f3"
  instance_type     = "t2.micro"
  availability_zone = "us-east-2a"
  security_groups   = ["${aws_security_group.mount-fuji-ssh-http.name}"]
  key_name = "mount-fuji"
  user_data = <<-EOF
                #! /bin/bash
                # install apache2 server and git cli
                sudo yum install httpd -y
                sudo yum install git -y
                #
                # web server setup
                rm /etc/httpd/conf.d/welcome.conf
                sed -i 's/README\*//g'  /etc/httpd/conf.d/autoindex.conf
                local_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
                echo "$local_ip        mount-fuji"   >> /etc/hosts
                html_folder="/var/www/mount-fuji"
                [[ ! -e $html_folder ]] && mkdir $html_folder
                # create archives of git repo's
                cd $html_folder
                for REPO in srehan-mt-fuji-IaC srehan-mt-fuji-App_Module srehan-mt-fuji-docker
                    do
                         git clone https://yogibear-sr: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@github.com/yogibear-sr/$REPO.git
                         (cd $REPO/ ; git archive main --format=tgz --output=../$REPO.tgz)
                         [[ -e $REPO/mount-fuji.conf ]] && cp $REPO/mount-fuji.conf /etc/httpd/conf.d
                         [[ -e $REPO ]] && rm -rf $REPO
                    done
                echo -e "User-agent: *\nDisallow: /" > /var/www/mount-fuji/robots.txt
                chown -R apache:apache $html_folder
                # enable from boot and start web service
                sudo systemctl start httpd
                sudo systemctl enable httpd
  EOF


  tags = {
        Name = "Project-mount-fuji"
  }

}

# set load balancer security group along with access rules

resource "aws_security_group" "mount-fuji-elbsg" {
  name        = "mount-fuji-elbsg"
  description = "allow http traffic"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["86.21.204.249/32"]
    description = "Allow 443 access from Subhash IP"
  }


  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    description = "Allow All outgoing access"
  }

  tags = {
        Name = "Project-mount-fuji"
  }
}


# create simple classic load balancer

resource "aws_elb" "mount-fuji-elb" {
  name               = "mount-fuji-elb"
  availability_zones = ["us-east-2a"]
  security_groups = ["${aws_security_group.mount-fuji-elbsg.id}"]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 443
    lb_protocol       = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
  instances                   = ["${aws_instance.mount-fuji.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "Project-mount-fuji"
  }
}

# create web server DNS record pointing to load balancer

resource "aws_route53_record" "srehan-httpd" {
  zone_id = "Z06224173B7VHTT03FQWR"
  name    = "srehan-httpd"
  type    = "A"

  alias {
    name                   = "${aws_elb.mount-fuji-elb.dns_name}"
    zone_id                = "${aws_elb.mount-fuji-elb.zone_id}"
    evaluate_target_health = true
  }
}

output "alias_name" {
  value = tolist(aws_route53_record.srehan-httpd.alias.*.name)[0]
}

output "elb-dns" {
   value = "${aws_elb.mount-fuji-elb.dns_name}"
}

output "mount-fuji_ip" {
    value = [aws_instance.mount-fuji.*.private_ip]
}


output "mount-fuji_ip_public" {
    value = [aws_instance.mount-fuji.*.public_ip]
}


output "mount-fuji_name" {
    value = [aws_instance.mount-fuji.*.tags.Name]
}

