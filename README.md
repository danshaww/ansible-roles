# Ansible Roles <img src="https://raw.githubusercontent.com/benc-uk/icon-collection/refs/heads/master/azure-docs/ansible.svg" alt="drawing" width="40" align="right"/>
This repository is my centralised Ansible Role collection.  
  
All of my Ansible project repositories (i.e core,dev,docker etc) make use of the roles stored here.  
From a CI/CD perspective, the only workflows that run in this repository are stub workflows used to trigger workflows in project repositories.  

Current Ansible Roles:
- [`ado_agent`](roles/ado_agent)
- [`apache`](roles/apache) — Ansible role to install Apache.
- [`az_secrets`](roles/az_secrets)
- [`bind_dns`](roles/bind_dns) — Ansible Role to install and configure Bind DNS, using Jinja2 templates to build configuration files.
- [`bitwarden_secrets`](roles/bitwarden_secrets) — Ansible Role to pull all secrets from Bitwarden Secrets Manager and store them based on project.
- [`check_host`](roles/check_host)
- [`checkmk_server`](roles/checkmk_server) — Ansible role to install CheckMK and perform basic configuration.
- [`cloudflared`](roles/cloudflared) — Ansible role to install and configure cloudflared.
- [`cron_management`](roles/cron_management) — Ansible role containing for managing cron
- [`docker_host`](roles/docker_host) — Ansible role to install Docker, perform initial server configuration & deploy docker compose projects where configured.
- [`gitea_runner`](roles/gitea_runner)
- [`github_runner`](roles/github_runner)
- [`global_system`](roles/global_system) — System Configuration Role used on all servers.
- [`isc_dhcp`](roles/isc_dhcp) — Ansible Role to install and configure ISC DHCP Server.
- [`k8s_node`](roles/k8s_node) — Ansible Role to install and configure K8S.
- [`letsencrypt`](roles/letsencrypt) — Ansible role to install and configure Lets Encrypt using Cloudflare DNS.
- [`nagios_agent`](roles/nagios_agent) — Role to configure Nagios NRPE Agent
- [`nagios_server`](roles/nagios_server) — Ansible role to install Nagios Core. This role has no dependancies on other roles.
- [`nfs_mount`](roles/nfs_mount)
- [`nginx`](roles/nginx) — Ansible role to install NGINX.
- [`ssmtp`](roles/ssmtp) — Ansible role containing for configuring ssmtp
- [`storage_server`](roles/storage_server) — Ansible role containing a range of common storage server related tasks
- [`technitium`](roles/technitium) — Ansible Role to install technitium
- [`unifi_os`](roles/unifi_os)
- [`uptime_kuma`](roles/uptime_kuma) — Role to configure an Uptime Kuma instance.
- [`user_management`](roles/user_management) — Ansible role for creating & managing users.
- [`windows_system`](roles/windows_system) — System Configuration Role used on Windows servers.
