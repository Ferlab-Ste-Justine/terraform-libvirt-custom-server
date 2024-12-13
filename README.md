# About

This module provision a custom server on libvirt.

It provides a base:
- Built-in cloudinit volume and server instantiation
- Base cloud init orchestration to create an admin user and set the hostname based on the libvirt vm name.
- Cloudinit networking orchestration

From there, it takes plain cloud-init parts as an argument for customizability that it adds to the cloudinit volume.

# Usage

## Input Variables

- **name**: Name to give to the vm. Will be the hostname by default as well.
- **hostname**: Used to give the vm an internal hostname that is different from the vm's name. It takes the following fields:
  - **hostname**: Hostname to give to the vm
  - **is_fqdn**: Boolean indicating whether the hostname is a fully qualified domain name or not.
- **vcpus**: Number of vcpus to assign to the vm. Defaults to 2.
- **memory**: Amount of memory in MiB to assign to the vm. Defaults to 8192.
- **volume_ids**: Id of the volumes to attach to the vm. The first volume should be an os volume. Any additional volumes should be formatted by additional cloud-init logic passed as an argument if they are not already formatted.
- **libvirt_network**: Parameters to connect to libvirt networks. It is an array of objects, each having the following keys:
  - **network_id**: Id (ie, uuid) of the libvirt network to connect to (in which case **network_name** should be an empty string).
  - **network_name**: Name of the libvirt network to connect to (in which case **network_id** should be an empty string).
  - **ip**: Ip of interface connecting to the libvirt network.
  - **mac**: Mac address of interface connecting to the libvirt network.
  - **prefix_length**:  Length of the network prefix for the network the interface will be connected to. For a **192.168.1.0/24** for example, this would be **24**.
  - **gateway**: Ip of the network's gateway. Usually the gateway the first assignable address of a libvirt's network.
  - **dns_servers**: Dns servers to use. Usually the dns server is first assignable address of a libvirt's network.
- **macvtap_interfaces**: List of macvtap interfaces to connect the vm to. Each entry in the list is a map with the following keys:
  - **interface**: Host network interface that you plan to connect your macvtap interface with.
  - **prefix_length**: Length of the network prefix for the network the interface will be connected to. For a **192.168.1.0/24** for example, this would be **24**.
  - **ip**: Ip associated with the macvtap interface. 
  - **mac**: Mac address associated with the macvtap interface
  - **gateway**: Ip of the network's gateway for the network the interface will be connected to.
  - **dns_servers**: Dns servers for the network the interface will be connected to. If there aren't dns servers setup for the network your vm will connect to, the ip of external dns servers accessible from the network will work as well.
- **cloud_init_volume_pool**: Name of the volume pool that will contain the cloud-init volume of the vm.
- **cloud_init_volume_name**: Name of the cloud-init volume that will be generated by the module for your vm. If left empty, it will default to **<name>-cloud-init.iso**.
- **ssh_admin_user**: Username of the default sudo user in the image. Defaults to **ubuntu**.
- **admin_user_password**: Optional password for the default sudo user of the image. Note that this will not enable ssh password connections, but it will allow you to log into the vm from the host using the **virsh console** command.
- **ssh_admin_public_key**: Public part of the ssh key the admin will be able to login as
- **cloud_init_configurations**: List of additional parts of cloud-init configuration. Each entry in the list should have a **filename** field that should be unique and meaningful as to the purpose of the cloud-init part and they should have a **content** field that should contain the content of the cloud-init part.
- **running**: Whether the vm should be running or stopped. Defaults to **true**.
- **autostart**: Whether the vm should start on host boot up. Defaults to **true**.

## Example of a custom cloud-init part

Say that we wanted to add cephadm to the custom server.

An entry for this in the **cloud_init_configurations** list could have a **filename** with a value of **cephadm.cfg** and a **content** with a value of:

```
#cloud-config
merge_how:
 - name: list
   settings: [append, no_replace]
 - name: dict
   settings: [no_replace, recurse_list]

runcmd:
  - wget https://download.ceph.com/rpm-18.2.0/el9/noarch/cephadm
  - chmod +x cephadm
  - ./cephadm add-repo --release reef
  - ./cephadm install
  - rm cephadm
  - cephadm install ceph-common
```