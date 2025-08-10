resource "aws_instance" "web" {
  ami                    = var.amiID.[var.region]
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  availability_zone      = var.zone


  tags = {
    Name    = "My-Terra-Instance"
    Project = "Terra-Project"
  }
}

resource "aws_ec2_instance_state" "web_state" {
  instance_id = aws_instance.web.id
  state       = "stopped"
}
