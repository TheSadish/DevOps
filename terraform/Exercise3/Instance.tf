resource "aws_instance" "web" {
  ami                    = var.amiID[var.region]
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  availability_zone      = var.zone


  tags = {
    Name    = "My-Terra-Instance"
    Project = "Terra-Project"
  }

  provisioner "file" {
    source      = "web.sh"
    destination = "/tmp/web.sh"
  }

  connection {
    type     = "ssh"
    user     = var.username
    private_key = file("keys")
    host     = self.public_ip
  }  

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/web.sh",
      "sudo ./tmp/web.sh"
    ]
  }

}


resource "aws_ec2_instance_state" "web_state" {
  instance_id = aws_instance.web.id
  state       = "stopped"
}
