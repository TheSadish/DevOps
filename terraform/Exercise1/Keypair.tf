resource "aws_key_pair" "my_key" {
  key_name   = "my_key_cli"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGfvrZBnRkrTQZecpgAFeW3vMdvni7V1PtF5TtOm4Iqb root@ip-172-31-25-173"
}
