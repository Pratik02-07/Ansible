## A playbook can contain multiple plays.
```
Playbook
   │
   ├── Play 1 → Web servers
   │       ├── Tasks
   │       └── Task
   │
   └── Play 2 → Database servers
           ├── Task
           └── Task
```

----
## Ansible Execution Flow
~~~
                 Playbook
                    │
                    ▼
                Inventory
                    │
                    ▼
              Target Hosts
                    │
                    ▼
                 Modules
                    │
                    ▼
                SSH Connection
                    │
                    ▼
             Managed Nodes
                    │
                    ▼
             Desired State
~~~
---
"Install Nginx on web servers"
             ↓
       Ansible Playbook
             ↓
       Inventory → web
             ↓
        SSH → EC2 servers
             ↓
       apt module
             ↓
        Nginx installed

---

chmod 400 terra-key-ec2

ansible aws_servers -i hosts -m ping
