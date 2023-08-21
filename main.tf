provider "aws" {
  region  = "us-east-1"
  profile = "default"
  default_tags {
    tags = {
      Organisation = "Asmigar"
      Environment  = "dev"
    }
  }
}

data "http" "my_public_ip" {
	url = "https://ipv4.icanhazip.com"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${chomp(data.http.my_public_ip.response_body)}/32"]
  }

  ingress {
    description      = "https puppet"
    from_port        = 8140
    to_port          = 8140
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.public.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "puppet"
  public_key = tls_private_key.this.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.this.private_key_openssh}' > ~/.ssh/${self.key_name}.pem; chmod 400 ~/.ssh/${self.key_name}.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ~/.ssh/${self.key_name}.pem"
  }
}


resource "aws_instance" "master" {
  ami           = var.image_id
  instance_type = "t2.micro"

  tags = {
    Name = "master"
  }

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id              = aws_subnet.public.id
  key_name               = aws_key_pair.this.key_name
  user_data = <<-EOT
		#!/bin/bash
		# Installing Puppet Server/Master
		apt-get update
		wget https://apt.puppetlabs.com/puppet6-release-bionic.deb
		dpkg -i puppet6-release-bionic.deb
		apt update
		apt-get install -y puppetserver

		# Installing Puppet Development Kit for modules development
		wget https://apt.puppet.com/puppet-tools-release-bionic.deb
		dpkg -i puppet-tools-release-bionic.deb
		apt-get update
		apt-get install -y pdk

		# Create entry for puppet master in /etc/hosts
		echo "$(hostname -i) puppet" >> /etc/hosts

		# Generate a root and intermediate signing CA for Puppet Server
		/opt/puppetlabs/bin/puppetserver ca setup
		sed -i.bak "s/-Xms2g -Xmx2g/-Xms512m -Xmx512m/" /etc/default/puppetserver
		echo -e "[main]\nserver=puppet" >> /etc/puppetlabs/puppet/puppet.conf
		systemctl start puppetserver
		EOT
}

resource "aws_instance" "agent" {
  count         = var.agents
  ami           = var.image_id
  instance_type = "t2.micro"

  tags = {
    Name = "agent-${count.index}"
  }

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id              = aws_subnet.public.id
  key_name               = aws_key_pair.this.key_name
  user_data = <<-EOT
		#!/bin/bash
		# Installing Puppet Agent
		apt-get update
		wget https://apt.puppetlabs.com/puppet6-release-bionic.deb
		dpkg -i puppet6-release-bionic.deb
		apt update
		apt-get install -y puppet-agent

		echo "${aws_instance.master.private_ip} puppet" >> /etc/hosts
		echo -e "[main]\nserver=puppet" >> /etc/puppetlabs/puppet/puppet.conf
		/opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
		systemctl restart puppet
		EOT
}
