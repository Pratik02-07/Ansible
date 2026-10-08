[servers]

%{ name } ansible_host= { IP }
%{ name } ansible_user= { user_name }

[all:vars]
ansible_ssh_private_key_file= { ssh_key_file  }
ansible_python_interpreter= { python_version }
ansible_hoste_key_check=false
