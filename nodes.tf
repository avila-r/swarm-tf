resource "aws_instance" "managers" {
  count = length(aws_subnet.publics)

  subnet_id = aws_subnet.publics[count.index].id

  ami = data.aws_ami.amz_2.id
  instance_type = local.available_type_in_az[
    aws_subnet.publics[count.index].availability_zone
  ]

  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.main.id]

  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${var.key_name}.pem")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "SWARM_JOIN_CMD=$(docker swarm init | grep -oP 'docker swarm join.*' | head -n 1)",
      "touch /home/ec2-user/swarm_join_cmd.txt",
      "echo $SWARM_JOIN_CMD > /home/ec2-user/swarm_join_cmd.txt"
    ]
  }

  tags = {
    Name = "${var.project_name}-manager-node-${(count.index + 1)}"
  }
}

resource "aws_instance" "workers" {
  count = length(aws_subnet.publics) * 3

  subnet_id = aws_subnet.publics[floor(count.index / 3)].id

  ami = data.aws_ami.amz_2.id
  instance_type = local.available_type_in_az[
    aws_subnet.publics[floor(count.index / 3)].availability_zone
  ]

  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.main.id
  ]

  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${var.key_name}.pem")
  }

  provisioner "file" {
    source      = "${var.key_name}.pem"
    destination = "/home/ec2-user/${var.key_name}.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /home/ec2-user/${var.key_name}.pem",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "JOIN_CMD=$(ssh -o StrictHostKeyChecking=no -i /home/ec2-user/${var.key_name}.pem ec2-user@${aws_instance.managers[floor(count.index / 3)].public_ip} 'cat /home/ec2-user/swarm_join_cmd.txt')",
      "eval $JOIN_CMD"
    ]
  }

  tags = {
    Name = "${var.project_name}-worker-node-${(floor(count.index / 3) + 1)}.${(count.index % 3 + 1)}"
  }
}
