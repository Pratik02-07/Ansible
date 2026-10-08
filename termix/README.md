# 📦 Termix: AWS EC2 Control Node Automation Bundle
## cross-os automation

This directory is a self-contained production package designed to be copied directly onto your **AWS Control Node EC2 instance**.

## 📁 Directory Layout

```
termix/ 
├── hosts.ini                  # Cluster inventory mapping private IPs
├── keys/                      # SSH private key folder
│   └── terra-key-ansible.example
└── playbooks/
    ├── install_docker.yml     # Master playbook targeting multi-OS workers
    └── roles/
        └── docker/            # Enterprise multi-OS Docker installation role
            ├── defaults/main.yml
            ├── handlers/main.yml
            ├── meta/main.yml
            ├── tasks/
            │   ├── main.yml         # Dynamic OS dispatcher
            │   ├── install_ubuntu.yml
            │   ├── install_redhat.yml
            │   └── install_amazon.yml
            └── vars/main.yml
```

---

## 🚀 Quick Start on Control Node

```bash
# 1. Place your private SSH key inside keys/ and set strict permissions
chmod 400 keys/terra-key-ansible

# 2. Test connectivity across all workers (Ubuntu, RHEL, Amazon Linux)
ansible -i hosts.ini workers -m ping

# 3. Deploy Docker across the entire multi-OS cluster with a single command
ansible-playbook -i hosts.ini playbooks/install_docker.yml
```

