# 🚀 Ansible Infrastructure Automation

[![Ansible](https://img.shields.io/badge/Ansible-2.15+-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-844FBA?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Linux](https://img.shields.io/badge/Linux-Ubuntu_22.04-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](#)

 
> **Repository Purpose**: An end-to-end, production-oriented learning log and reference repository documenting Ansible automation from first principles (Control Node, Managed Nodes, Agentless Architecture) to advanced Playbooks, Inventory structures, AWS EC2 provisioning via Terraform, and configuration management.

---

## 📑 Table of Contents

1. [Ansible Fundamentals](#1-ansible-fundamentals)
   - [What is Ansible?](#what-is-ansible)
   - [Core Tenets: Control Node vs. Managed Node](#core-tenets-control-node-vs-managed-node)
   - [Why Agentless Architecture Matters](#why-agentless-architecture-matters)
   - [The Golden Rule: Idempotency](#the-golden-rule-idempotency)
2. [Ansible Architecture & Execution Flow](#2-ansible-architecture--execution-flow)
   - [High-Level Architecture Diagram](#high-level-architecture-diagram)
   - [Under the Hood: Execution Lifecycle](#under-the-hood-execution-lifecycle)
3. [Ansible Inventory Deep Dive](#3-ansible-inventory-deep-dive)
   - [Inventory Formats: INI vs YAML](#inventory-formats-ini-vs-yaml)
   - [Host Grouping & Hierarchical Groups (`:children`)](#host-grouping--hierarchical-groups-children)
   - [Assigning Host & Group Variables](#assigning-host--group-variables)
   - [Critical Connection Variables Explained](#critical-connection-variables-explained)
   - [Repository Inventory Walkthrough](#repository-inventory-walkthrough)
4. [Ansible Configuration (`ansible.cfg`)](#4-ansible-configuration-ansiblecfg)
5. [Ad-Hoc Commands: Word-by-Word Dissection](#5-ad-hoc-commands-word-by-word-dissection)
   - [Command 1: `ansible -i hosts.ini servers -m ping`](#command-1-ansible--i-hostsini-servers--m-ping)
   - [Command 2: `ansible -i hosts.ini servers -a "uptime"`](#command-2-ansible--i-hostsini-servers--a-uptime)
   - [`command` Module vs `shell` Module](#command-module-vs-shell-module)
6. [Playbooks Deep Dive](#6-playbooks-deep-dive)
   - [Playbook Anatomy & Keywords](#playbook-anatomy--keywords)
   - [Modules vs. Tasks](#modules-vs-tasks)
   - [Handlers & Event-Driven Triggers (`notify`)](#handlers--event-driven-triggers-notify)
   - [Playbook Execution Flow](#playbook-execution-flow)
7. [Playbook CLI Execution Breakdown](#7-playbook-cli-execution-breakdown)
   - [Command: `ansible-playbook -i ../hosts.ini hello.yaml`](#command-ansible-playbook--i-hostsini-helloyaml)
8. [Codebase Playbooks Walkthrough](#8-codebase-playbooks-walkthrough)
   - [`hello.yaml`: Variables & Command Execution](#helloyaml-variables--command-execution)
   - [`deploy_nginx.yml`: End-to-End Web Server Deployment](#deploy_nginxyml-end-to-end-web-server-deployment)
   - [`install_pkg.yaml`: Batch Package Loops & Conditionals](#install_pkgyaml-batch-package-loops--conditionals)
9. [End-to-End Workflow: Terraform + Ansible on AWS](#9-end-to-end-workflow-terraform--ansible-on-aws)
10. [DevOps Best Practices & Troubleshooting](#10-devops-best-practices--troubleshooting)

---

## 1. Ansible Fundamentals

### What is Ansible?
**Ansible** is an open-source IT automation engine that automates cloud provisioning, configuration management, application deployment, intraservice orchestration, and routine operational tasks.

Unlike imperative scripting (like raw Bash scripts), Ansible operates **declaratively**: you describe the desired end state of your systems, and Ansible handles the operations required to reach and maintain that state.

```
Bash (Imperative)  : "Download package -> unpack -> move files -> change config -> restart service"
Ansible (Declarative): "Ensure package is present, ensure config matches template, ensure service is started"
```

---

### Core Tenets: Control Node vs. Managed Node

| Entity | Role | Requirements | Operating System |
| :--- | :--- | :--- | :--- |
| **Control Node** | The management host where Ansible is installed and executed from. Commands and playbooks originate here. | Python 3.9+, Ansible core package, OpenSSH client. | Linux (Ubuntu, RHEL, Debian), macOS, WSL on Windows. *(Native Windows cannot act as a Control Node)*. |
| **Managed Node** | The target systems (virtual machines, bare-metal, EC2 instances, containers) being managed. | Standard SSH server (`sshd`), SFTP/SCP, Python 3.x installed. **No Ansible software installed**. | Linux, Unix, Windows (via WinRM/OpenSSH), Network devices. |

---

### Why Agentless Architecture Matters

Traditional configuration management tools (such as Puppet, Chef, or SaltStack in default mode) require a client-side agent daemon installed, running, and listening on every managed node.

```
Agent-based (Puppet/Chef) :  [Master Server] <--(Port 8140/Agent polling)--> [Agent Daemon running on Node]
Ansible (Agentless)        :  [Control Node]  ---(Standard SSH / Port 22)---> [Managed Node (Python runtime)]
```

#### DevOps Advantages of Agentless Architecture:
1. **Zero Agent Maintenance**: No need to patch, upgrade, or monitor background agent daemons across thousands of servers.
2. **Reduced Attack Surface**: No additional persistent background daemon or open listening ports; uses existing, hardened OpenSSH infrastructure.
3. **Low Resource Footprint**: Zero continuous CPU/RAM consumption on managed nodes when no task is running.
4. **Immediate Bootstrapping**: Any clean Linux server launched on AWS, GCP, or Azure can be configured instantly if SSH and Python are present.

---

### The Golden Rule: Idempotency

> **Idempotency** means an operation can be executed multiple times without changing the result beyond the initial application.

If you execute an Ansible playbook 1 time or 100 times against a server:
- **Run 1**: Nginx is missing $\rightarrow$ Ansible installs Nginx $\rightarrow$ Status: `changed`.
- **Run 2**: Nginx is already installed $\rightarrow$ Ansible verifies and takes no action $\rightarrow$ Status: `ok`.

This guarantees drift prevention, safe continuous deployments, and predictability in production pipelines.

---

## 2. Ansible Architecture & Execution Flow

### High-Level Architecture Diagram

```
+---------------------------------------------------------------------------------+
|                                CONTROL NODE                                     |
|                                                                                 |
|  +--------------------+    +---------------------+    +----------------------+  |
|  |    ansible.cfg     |    |   Inventory File    |    |  Playbooks / YAML    |  |
|  |  (Config defaults) |    | (hosts, hosts.ini)  |    |  (Tasks, Handlers)   |  |
|  +---------+----------+    +----------+----------+    +----------+-----------+  |
|            |                          |                          |              |
|            +--------------------------+--------------------------+              |
|                                       |                                         |
|                                       v                                         |
|                       +-------------------------------+                         |
|                       |  Ansible Engine / Ansiballz   |                         |
|                       |  (Packs modules into payload) |                         |
|                       +---------------+---------------+                         |
+---------------------------------------|-----------------------------------------+
                                        |  Secure SSH (Port 22)
                 +----------------------+----------------------+
                 |                                             |
                 v                                             v
  +-----------------------------+               +-----------------------------+
  |    MANAGED NODE 1 (EC2)     |               |    MANAGED NODE 2 (EC2)     |
  |                             |               |                             |
  |  1. Temp Payload extracted  |               |  1. Temp Payload extracted  |
  |     to ~/.ansible/tmp/      |               |     to ~/.ansible/tmp/      |
  |  2. Executed via Python     |               |  2. Executed via Python     |
  |  3. JSON response returned  |               |  3. JSON response returned  |
  |  4. Temp payload erased     |               |  4. Temp payload erased     |
  +-----------------------------+               +-----------------------------+
```

---

### Under the Hood: Execution Lifecycle

When you run `ansible` or `ansible-playbook`:

1. **Configuration Load**: Ansible reads configuration in order: `ANSIBLE_CONFIG` env var $\rightarrow$ `./ansible.cfg` $\rightarrow$ `~/.ansible.cfg` $\rightarrow$ `/etc/ansible/ansible.cfg`.
2. **Inventory Parsing**: Resolves target host patterns, groups, and assigns host/group variables.
3. **SSH Connection Initialization**: Authenticates with target nodes using specified credentials or SSH private keys (`ansible_ssh_private_key_file`).
4. **Fact Gathering (`setup` module)**: Unless disabled, gathers runtime facts about the target (OS distribution, IP addresses, CPU, memory, disk).
5. **Ansiballz Packaging**: Ansible packages the task's module code and parameters into a self-contained Python zip payload on the Control Node.
6. **Payload Transport**: Transports the payload over SFTP/SCP to the remote temporary directory (typically `~/.ansible/tmp/`).
7. **Remote Execution**: Invokes the remote Python interpreter (`/usr/bin/python3`) to execute the module.
8. **JSON Serialization & Return**: The module outputs a structured JSON response (e.g. `{"changed": true, "rc": 0}`) back to standard output over the SSH tunnel.
9. **Ephemeral Cleanup**: Ansible cleans up the temporary files from `~/.ansible/tmp/` on the managed node.
10. **Recap**: Aggregates output and displays colored status (`ok`, `changed`, `unreachable`, `failed`).

---

## 3. Ansible Inventory Deep Dive

An **Inventory** defines the managed nodes that Ansible automates. It maps hostnames or aliases to physical IP addresses, organizes servers into logical groups, and assigns variables.

### Inventory Formats: INI vs YAML

Ansible supports both **INI** and **YAML** formats. INI is concise and standard for ad-hoc and simple setups; YAML is hierarchical.

#### INI Syntax:
```ini
[web]
web1.production.com ansible_host=10.0.1.50
web2.production.com ansible_host=10.0.1.51

[db]
db1.production.com  ansible_host=10.0.2.100
```

---

### Host Grouping & Hierarchical Groups (`:children`)

You can create parent-child group hierarchies using the `:children` suffix. This allows targeting broad environments (like `production` or `us-east`) while maintaining granular sub-groups (`web`, `db`).

```ini
# Sub-group: Web Servers
[web]
web1 ansible_host=54.210.10.1
web2 ansible_host=54.210.10.2

# Sub-group: Database Servers
[db]
db1 ansible_host=10.0.2.20

# Parent Group: Production (Aggregates both web and db)
[production:children]
web
db
```

---

### Assigning Host & Group Variables

Variables can be assigned at two levels directly inside the inventory:

#### 1. Host-Level Variables
Assigned inline to a specific host on the same line:
```ini
worker-node-1 ansible_host=54.210.10.1 http_port=80 max_clients=200
worker-node-2 ansible_host=54.210.10.2 http_port=8080 max_clients=500
```

#### 2. Group-Level Variables (`[<group_name>:vars]`)
Assigned to all members belonging to that group:
```ini
[servers:vars]
ansible_user=ubuntu
deploy_env=staging
app_version=v2.1.0

# Variables applied globally across ALL hosts in inventory
[all:vars]
ansible_python_interpreter=/usr/bin/python3
ntp_server=pool.ntp.org
```

---

### Critical Connection Variables Explained

| Variable | Purpose | DevOps Use Case / Example |
| :--- | :--- | :--- |
| `ansible_host` | The actual IPv4/IPv6 address or DNS FQDN of the remote machine. | Decouples logical server name (`worker-1`) from dynamic public/private IP (`54.210.10.1`). |
| `ansible_user` | The remote SSH username used to log in. | Cloud AMIs use specific default users: Ubuntu uses `ubuntu`, Amazon Linux uses `ec2-user`, CentOS uses `centos`. |
| `ansible_ssh_private_key_file` | Absolute or relative path to the private SSH key file (`.pem` / RSA key). | Bypasses interactive password prompts for automated key-pair authentication. |
| `ansible_port` | Remote SSH port. | Used if SSH has been moved off default port 22 (e.g. `ansible_port=2222`). |
| `ansible_python_interpreter` | Explicit path to the remote Python binary. | Prevents discovery latency and ensures Ansible uses Python 3 (`/usr/bin/python3`) instead of legacy Python 2. |
| `ansible_ssh_common_args` | Extra SSH CLI flags (ProxyJump, Bastion host). | Connecting to private EC2 instances via a Bastion / Jump Host. |

---

### Repository Inventory Walkthrough

This repository contains two inventory references:

#### 1. [`inventory`] (Configured as default in `ansible.cfg`):
```ini
[web]
web1 ansible_host=54.x.x.x

[web:vars]
# Tell Ansible to connect as 'ubuntu' instead of local user
ansible_user=ubuntu

# Specify the path to the private key that matches the public key uploaded to AWS
ansible_ssh_private_key_file=./terra-key-ec2
```

#### 2. [`hosts`](file:///e:/PRATIK/Coding/AWS-DevOps/Ansible/hosts):
```ini
[servers]
worker-node-1 ansible_host=54.x.x.1
worker-node-2 ansible_host=54.x.x.2
worker-node-1 ansible_user=ubuntu
worker-node-2 ansible_user=ubuntu

[all:vars]
ansible_ssh_private_key_file=/home/pratik/Desktop/Ansible/Ansible-master-key
ansible_python_interpreter=/usr/bin/python3
```

---

## 4. Ansible Configuration (`ansible.cfg`)

The [`ansible.cfg`](file:///e:/PRATIK/Coding/AWS-DevOps/Ansible/ansible.cfg) file in the root directory customizes Ansible’s runtime behavior:

```ini
[defaults]
inventory = ./inventory
host_key_checking = False
interpreter_python = auto_silent
```

### Parameter Breakdown:
* **`inventory = ./inventory`**: Defines the default inventory path so you don't need to specify `-i ./inventory` in every command.
* **`host_key_checking = False`**: Disables the interactive SSH prompt (`Are you sure you want to continue connecting (yes/no/[fingerprint])?`). Essential in automated CI/CD pipelines and ephemeral cloud instances.
* **`interpreter_python = auto_silent`**: Automatically discovers the Python interpreter on the managed node and silences warning messages.

---

## 5. Ad-Hoc Commands: Word-by-Word Dissection

An **Ad-Hoc command** is a single, quick command used to perform a one-time task on one or more managed nodes without writing a playbook.

---

### Command 1: `ansible -i hosts.ini servers -m ping`

```bash
ansible -i hosts.ini servers -m ping
```

#### Complete Anatomical Breakdown:

| Token / Word | Type | In-Depth Engineering Explanation |
| :--- | :--- | :--- |
| **`ansible`** | Executable Binary | The primary CLI utility for running ad-hoc commands against target hosts. |
| **`-i`** | Flag / Option | Short for `--inventory`. Specifies the path to the inventory file containing target host definitions. *(If `ansible.cfg` has `inventory` defined, this flag is optional)*. |
| **`hosts.ini`** | Argument | The path to the inventory file to read hosts and connection parameters from. |
| **`servers`** | Host Pattern | The target identifier. Matches the `[servers]` group defined in the inventory file. Can also be a single hostname (`worker-node-1`), an IP, or the special keyword `all`. |
| **`-m`** | Flag / Option | Short for `--module-name`. Instructs Ansible which built-in module to load and execute on the target hosts. |
| **`ping`** | Module Name | The built-in Ansible `ansible.builtin.ping` module. |

> [!IMPORTANT]
> **Ansible `ping` is NOT an ICMP ping!**  
> Traditional ICMP `ping` only verifies network layer connectivity. Ansible's `ping` module connects via **SSH**, validates user authentication and permissions, verifies the remote **Python interpreter**, executes a tiny Python test payload, and expects a JSON response of:
> ```json
> {
>   "changed": false,
>   "ping": "pong"
> }
> ```

---

### Command 2: `ansible -i hosts.ini servers -a "uptime"`

```bash
ansible -i hosts.ini servers -a "uptime"
```

#### Complete Anatomical Breakdown:

| Token / Word | Type | In-Depth Engineering Explanation |
| :--- | :--- | :--- |
| **`ansible`** | Executable Binary | The ad-hoc CLI tool. |
| **`-i hosts.ini`** | Option + Arg | Points to the inventory file. |
| **`servers`** | Host Pattern | Directs the command to all hosts in the `servers` group. |
| **`-a`** | Flag / Option | Short for `--args` (module arguments). Passes string arguments to the module being executed. |
| **`"uptime"`** | Argument Value | The exact Linux command passed as an argument string to be executed on the remote system. |

#### 💡 The Default Module Magic:
Notice that `-m` was omitted! When you do **not** supply `-m <module>`, Ansible defaults to:
$$\text{Default Module} = \mathbf{command}$$

Therefore, the above command is 100% equivalent to:
```bash
ansible -i hosts.ini servers -m command -a "uptime"
```

#### Additional Practical Linux Diagnostic Ad-Hoc Commands:
```bash
# Check memory consumption across all servers
ansible -i hosts.ini servers -a "free -m"

# Check disk space utilization
ansible -i hosts.ini servers -a "df -h"

# Check Linux kernel version
ansible -i hosts.ini servers -a "uname -r"

# Check Nginx service status (requires sudo privileges: -b)
ansible -i hosts.ini servers -b -a "systemctl status nginx"
```

---

### `command` Module vs `shell` Module

A common pitfall in DevOps is choosing between `command` and `shell`:

| Feature | `command` Module (`-m command`) | `shell` Module (`-m shell`) |
| :--- | :--- | :--- |
| **Execution Method** | Executes binary directly (via `execve`) | Executes command through a subshell (`/bin/sh -c`) |
| **Shell Features** | ❌ No pipes (`\|`), redirects (`>`), wildcards (`*`) | ✅ Full support for pipes, redirects, wildcards |
| **Environment Vars** | ❌ Does not expand `$VAR` | ✅ Expands `$HOME`, `$PATH`, custom `$ENV` |
| **Security** | More secure (immune to shell injection) | Higher risk if user inputs are unvetted |
| **Example** | `ansible servers -a "cat /etc/os-release"` | `ansible servers -m shell -a "cat /var/log/syslog \| grep error"` |

---

## 6. Playbooks Deep Dive

A **Playbook** is a human-readable YAML document containing one or more **Plays**.
- A **Play** maps a set of managed hosts to a list of ordered **Tasks**.
- A **Task** invokes an Ansible **Module** with specified parameters to achieve a desired state.

```
Playbook (YAML file)
  │
  ├── Play 1: "Configure Web Tier" (hosts: web)
  │     ├── Task 1: Update apt cache
  │     ├── Task 2: Install Nginx
  │     └── Task 3: Enable service (Notifies Handler)
  │
  ├── Play 2: "Configure Database Tier" (hosts: db)
  │     ├── Task 1: Install MySQL
  │     └── Task 2: Secure installation
  │
  └── Handlers: (Executed at the end if notified)
        └── Handler: "Restart Nginx"
```

---

### Playbook Anatomy & Keywords

Here is a structural breakdown of a complete playbook with every primary keyword explained:

```yaml
---
- name: End-to-End Web Server Deployment      # 1. Play Name
  hosts: servers                               # 2. Target Hosts
  become: yes                                  # 3. Privilege Escalation (sudo)

  vars:                                        # 4. Variables Block
    web_port: 80
    app_root: /var/www/html

  tasks:                                       # 5. Ordered Tasks List
    - name: Ensure Nginx is installed          # Task Description
      apt:                                     # Module Name
        name: nginx                            # Module Parameter
        state: present                         # Desired State

    - name: Deploy custom configuration file
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: Restart Nginx Service            # Trigger Handler on change

  handlers:                                    # 6. Event-Driven Handlers
    - name: Restart Nginx Service
      service:
        name: nginx
        state: restarted
```

#### Detailed Keyword Explanations:

1. **`name`**:
   - A descriptive label for the play or task.
   - Displayed in the terminal and CI/CD logs during execution. Essential for auditability and debugging.
2. **`hosts`**:
   - Specifies which systems from your inventory will execute this play (`servers`, `web`, `all`, or boolean patterns like `web:&staging`).
3. **`become`**:
   - Privilege escalation directive (`become: yes` / `become: true`).
   - Equivalent to prefixing actions with `sudo`. Required for system-level operations like installing packages, managing services, or writing to `/etc/` and `/var/`.
4. **`vars`**:
   - Defines a key-value dictionary of variables scoped to the play. Promotes DRY (Don't Repeat Yourself) design.
5. **`tasks`**:
   - The sequential array of operations executed from top to bottom. If any task fails on a host, Ansible halts further execution for that host (unless `ignore_errors: yes` is specified).
6. **`handlers`**:
   - Special tasks that only run when triggered by a `notify` directive from another task that reported a **`changed`** status.

---

### Modules vs. Tasks

* **Module**: A standalone, reusable script (written in Python for Linux, or PowerShell for Windows) that ships with Ansible or collections. Examples: `apt`, `yum`, `copy`, `template`, `service`, `systemd`, `user`, `git`.
* **Task**: The specific unit of execution inside a Playbook that pairs a module with your customized inputs.

```yaml
# A Task:
- name: Ensure Git is installed      # Task metadata
  apt:                               # Module
    name: git                        # Parameter 1
    state: present                   # Parameter 2
```

---

### Handlers & Event-Driven Triggers (`notify`)

In enterprise operations, you should never restart a service unless its configuration file actually changed. Handlers prevent unnecessary downtime:

1. A task updates a configuration file using the `copy` or `template` module.
2. If the file is **identical** $\rightarrow$ task status is `ok` $\rightarrow$ handler is **NOT** notified.
3. If the file is **modified** $\rightarrow$ task status is `changed` $\rightarrow$ `notify` triggers the handler.
4. Handlers run **once and only once** at the very end of the play, regardless of how many tasks notified them.

---

### Playbook Execution Flow

```
                     ansible-playbook CLI Invoked
                                  │
                                  ▼
                        Parse Inventory & Vars
                                  │
                                  ▼
                      TASK [Gathering Facts]
                   (Collects OS, IP, RAM specs)
                                  │
                                  ▼
                         TASK 1: Update apt
                   (Result: ok or changed)
                                  │
                                  ▼
                         TASK 2: Install Nginx
                   (Result: ok or changed)
                                  │
                                  ▼
                      TASK 3: Deploy Config
                   (Changed? -> Queue Handler)
                                  │
                                  ▼
                         RUNNING HANDLERS
                   (Execute "Restart Nginx")
                                  │
                                  ▼
                            PLAY RECAP
               (ok=4  changed=2  unreachable=0  failed=0)
```

---

## 7. Playbook CLI Execution Breakdown

### Command: `ansible-playbook -i ../hosts.ini hello.yaml`

```bash
ansible-playbook -i ../hosts.ini hello.yaml
```

#### Complete Anatomical Breakdown:

| Token / Word | Type | In-Depth Engineering Explanation |
| :--- | :--- | :--- |
| **`ansible-playbook`** | Executable Binary | The dedicated command-line engine designed to parse, validate, and orchestrate YAML playbooks across inventory targets. |
| **`-i`** | Flag / Option | Short for `--inventory-file`. Tells Ansible where to locate the target node definitions. |
| **`../hosts.ini`** | Relative Path | Points to the inventory file located one directory level up (`..`). Can also be an absolute path (e.g. `/etc/ansible/hosts`). |
| **`hello.yaml`** | Target Playbook | The YAML playbook file containing the plays, tasks, variables, and desired states to execute. |

#### Useful Flags for Production:
```bash
# 1. Syntax check before running
ansible-playbook -i ../hosts.ini hello.yaml --syntax-check

# 2. Dry run / Check Mode (Simulates changes without modifying target nodes)
ansible-playbook -i ../hosts.ini hello.yaml --check

# 3. Limit execution to a specific host
ansible-playbook -i ../hosts.ini hello.yaml --limit worker-node-1

# 4. Verbose debugging output (-v, -vv, -vvv, or -vvvv for full SSH logs)
ansible-playbook -i ../hosts.ini hello.yaml -vvv
```

---

## 8. Codebase Playbooks Walkthrough

This repository contains ready-to-run playbooks in [`Playbook/`]:

### [`hello.yaml`]: Variables & Command Execution
A foundational playbook demonstrating variable interpolation using Jinja2 syntax `{{ ... }}`:

```yaml
- name: hello friends
  hosts: servers
  become: yes

  vars:
    user_name: Pratik

  tasks:
    - name: Greet Users
      command: echo "hello {{ user_name }}"
```

---

### [`deploy_nginx.yml`]: End-to-End Web Server Deployment
A production deployment playbook showcasing package cache management, package installation, file creation, and service management:

```yaml
---
- name: End-to-End Web Server Deployment
  hosts: web
  become: yes  # Runs everything below as root (sudo)
  
  vars:
    web_root: /var/www/html

  tasks:
    - name: Update apt package cache
      apt:
        update_cache: yes
        cache_valid_time: 3600  # Only update if cache is older than an hour

    - name: Install Nginx web server
      apt:
        name: nginx
        state: present  # Ensures Nginx is installed

    - name: Create a custom landing page
      copy:
        content: "<h1>Welcome to Automated Ubuntu Infrastructure via Ansible!</h1>"
        dest: "{{ web_root }}/index.html"
        mode: '0644'

    - name: Ensure Nginx service is started and enabled on boot
      service:
        name: nginx
        state: started
        enabled: yes
```

---

### [`install_pkg.yaml`]: Batch Package Loops & Conditionals
Demonstrates iteration with `loop` and OS fact checking with `when`:

```yaml
- name: Install Packages
  hosts: all
  become: yes

  vars:
    packages_to_install:
      - zip
      - unzip
      - jq
      - wget

  tasks:
    - name: Print installation progress
      debug:
        msg: "installing {{ item }}"
      loop: "{{ packages_to_install }}"
      when: ansible_facts["distribution"] == "Ubuntu"

    - name: Install utility packages
      apt:
        name: "{{ item }}"
        state: present
      loop: "{{ packages_to_install }}"
```

---

## 9. End-to-End Workflow: Terraform + Ansible on AWS

The modern DevOps pattern is: **Terraform provisions the infrastructure $\rightarrow$ Ansible configures the servers.**

This repository features both sides in [`Terraform_ansible/`]:

```
+---------------------+           +---------------------+           +---------------------+
| 1. Terraform        |  Public   | 2. Ansible          |    SSH    | 3. EC2 Instances    |
| Provisions EC2,     |  IPs &    | Reads Inventory,    | Configures| Configured with     |
| Security Groups,    | --------> | connects with       | --------> | Nginx, Security,    |
| & SSH Key Pairs     | Key Path  | terra-key-ec2       |           | Packages            |
+---------------------+           +---------------------+           +---------------------+
```

### Step 1: Provision Infrastructure with Terraform
```bash
cd Terraform_ansible/
terraform init
terraform plan
terraform apply -auto-approve
```
*Terraform outputs the instance public IPs and creates the private key `terra-key-ec2`.*

### Step 2: Set Secure Permissions on Private Key
Linux and SSH require strict private key permissions:
```bash
chmod 400 terra-key-ec2
```

### Step 3: Populate Ansible Inventory
Update [`inventory`]with the generated EC2 Public IP:
```ini
[web]
web1 ansible_host=34.228.xx.xx

[web:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=./Terraform_ansible/terra-key-ec2
```

### Step 4: Verify SSH Connectivity via Ad-Hoc Ping
```bash
ansible -i inventory web -m ping
```

### Step 5: Execute the Deployment Playbook
```bash
ansible-playbook -i inventory Playbook/deploy_nginx.yml
```

### Step 6: Verify in Web Browser
Open `http://<ec2-public-ip>` to view the landing page:
> *"Welcome to Automated Ubuntu Infrastructure via Ansible!"*

---

## 10. DevOps Best Practices & Troubleshooting

| Practice / Issue | Recommendation |
| :--- | :--- |
| **SSH Host Key Prompts** | Set `host_key_checking = False` in `ansible.cfg` for automated cloud environments. |
| **Permissions on SSH Keys** | Always run `chmod 400 <private_key>` or `chmod 600 <private_key>`. Open permissions (`0644` or `0777`) cause SSH rejection. |
| **Privilege Escalation** | Always specify `become: yes` on tasks modifying system files or installing packages. |
| **Idempotent Tasks** | Prefer native modules (`apt`, `copy`, `service`, `template`) over raw `command` or `shell` modules. |
| **Dry Run Testing** | Always run `ansible-playbook --check` before applying changes in production. |
| **Directory Hygiene** | Keep playbooks, roles, inventories, and templates structured cleanly in source control. |

---
