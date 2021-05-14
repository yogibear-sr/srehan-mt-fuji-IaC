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
}

# create EC2 instance on default subnet
resource "aws_instance" "mount-fuji" {
  ami               = "ami-077e31c4939f6a2f3"
  instance_type     = "t2.micro"
  availability_zone = "us-east-2a"
  security_groups   = ["${aws_security_group.mount-fuji-ssh-http.name}"]
  key_name = "mount-fuji"
  user_data = <<-EOF
                #! /bin/bash
                sudo yum install httpd -y
                sudo yum install git -y
                rm /etc/httpd/conf.d/welcome.conf
                local_ip==$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
                echo "$local_ip        mount-fuji"   >> /etc/hosts
                mkdir /var/www/mount-fuji
                cd /var/www/mount-fuji
                git clone https://yogibear-sr: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@github.com/yogibear-sr/sre-fuji-pingcloud.git
                git clone https://yogibear-sr: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@github.com/yogibear-sr/fuji-app-python_module.git
                git clone https://yogibear-sr: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@github.com/yogibear-sr/sre-mt-fuji-misc.git
                echo -e "User-agent: *\nDisallow: /" > /var/www/mount-fuji/robots.txt
                cp /var/www/mount-fuji/sre-mt-fuji-misc/mount-fuji.conf /etc/httpd/conf.d
                chown -R apache:apache /var/www/mount-fuji
                sudo systemctl start httpd
                sudo systemctl enable httpd
  EOF


  tags = {
        Name = "mount-fuji-webserver"
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
    Name = "mount-fuji-elb"
  }
}

#resource "aws_route53_record" "mount-fuji-sr" {
#  zone_id = aws_route53_zone.awscloud.pingidentity.net.zone_id
#  name    = "mount-fuji-sr"
#  type    = "CNAME"
#  ttl     = "60"
#  records = [aws_lb.mount-fuji-elb.dns_name]
#}

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
