#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

%{ if admin_user_password != "" ~}
ssh_pwauth: false
chpasswd:
  expire: False
  users:
    - name: ${ssh_admin_user}
      password: "${admin_user_password}"
      type: text
%{ endif ~}
preserve_hostname: false
hostname: ${hostname}
%{ if is_fqdn != "" ~}
fqdn: ${hostname}
prefer_fqdn_over_hostname: true
%{ endif ~}
users:
  - default
  - name: ${ssh_admin_user}
    ssh_authorized_keys:
      - "${ssh_admin_public_key}"
%{ for user in extra_users ~}
  - name: ${user.username}
%{ if user.is_sudo_user ~}
    sudo: ALL=(ALL) NOPASSWD:ALL
%{ endif ~}
    shell: /bin/bash
    groups: sadcsip
    ssh_authorized_keys:
      - ${user.public_key}
%{ endfor ~}

write_files:
  #Chrony config
%{ if chrony.enabled ~}
  - path: /opt/chrony.conf
    owner: root:root
    permissions: "0444"
    content: |
%{ for server in chrony.servers ~}
      server ${join(" ", concat([server.url], server.options))}
%{ endfor ~}
%{ for pool in chrony.pools ~}
      pool ${join(" ", concat([pool.url], pool.options))}
%{ endfor ~}
      driftfile /var/lib/chrony/drift
      makestep ${chrony.makestep.threshold} ${chrony.makestep.limit}
      rtcsync
%{ endif ~}
  - path: /tmp/init-user.sh
    owner: root
    permissions: '0700'
    defer: true
    content: |
      #!/usr/bin/env bash
      set -euox pipefail
      # This script expects a volume to be mounted at /data
      if [[ "$(grep -w /data /etc/fstab)" == "" ]]; then
      echo "No volume mounted at /data"
      exit 1
      fi
      
      [[ ! -d /home/BDD_SIP_HSJ ]] &&  mkdir /home/BDD_SIP_HSJ
      [[ ! -d /data/sadcsip ]] &&  mkdir /data/sadcsip
      [[ ! -d /data/users ]] &&  mkdir /data/users

      # Define permissions
      chown root:sadcsip /home/BDD_SIP_HSJ /data/sadcsip
      chown root:root /data/users
      chmod 550 /home/BDD_SIP_HSJ
      chmod 570 /data/sadcsip

      linux_users=(%{ for user in extra_users ~}${user.username} %{ endfor  ~})

      for os_user in "$${linux_users[@]}" ; do

        if [[ ! -L /home/"$os_user"/sadcsip ]]; then
            ln -s /data/sadcsip /home/"$os_user"/sadcsip
        fi

        if [[ ! -L /home/"$os_user"/work-data ]]; then
          if [[ ! -d /data/users/"$os_user" ]]; then
            mkdir /data/users/"$os_user"
            chown "$os_user":"$os_user" /data/users/"$os_user"
          fi
            ln -s /data/users/"$os_user" /home/"$os_user"/work-data
        fi

      done

packages:
  - nfs-common
  - ca-certificates
  - cmake
  - build-essential
  - cifs-utils
%{ if chrony.enabled ~}
  - chrony
%{ endif ~}

package_update: true
package_upgrade: true
package_reboot_if_required: true

mounts:
  - [ /dev/vdb, /data, auto, "defaults,nofail", 0, 2 ]

runcmd:
  #Finalize Chrony Setup
%{ if chrony.enabled ~}
  - cp /opt/chrony.conf /etc/chrony/chrony.conf
  - systemctl restart chrony.service 
%{ endif ~}