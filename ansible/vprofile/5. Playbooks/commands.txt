Ansible Commands Used

Use YUM package installer to install htppd
ansible web01 -m ansible.builtin.yum -a "name=httpd state=present" -i inventory --become

Enable this service
ansible web01 -m ansible.builtin.service -a "name=httpd state=started enabled=yes" -i inventory --become

Copy a file
ansible web01 -m ansible.builtin.copy -a "src=index.html dest=/var/www/html/index.html" -i inventory --become
