variable "name" {
  description = "Name to give to the vm"
  type = string
}

variable "vcpus" {
  description = "Number of vcpus to assign to the vm"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Amount of memory in MiB"
  type        = number
  default     = 8192
}

variable "volume_ids" {
  description = "Id of disk volumes to attach to the vm"
  type        = list(string)
}

variable "libvirt_networks" {
  description = "Parameters of libvirt network connections if a libvirt networks are used."
  type = list(object({
    network_name = string
    network_id = string
    prefix_length = string
    ip = string
    mac = string
    gateway = string
    dns_servers = list(string)
  }))
  default = []
}

variable "macvtap_interfaces" {
  description = "List of macvtap interfaces."
  type        = list(object({
    interface = string,
    prefix_length = number,
    ip = string,
    mac = string,
    gateway = string,
    dns_servers = list(string),
  }))
  default = []
}

variable "cloud_init_volume_pool" {
  description = "Name of the volume pool that will contain the cloud init volume"
  type        = string
}

variable "cloud_init_volume_name" {
  description = "Name of the cloud init volume"
  type        = string
  default = ""
}

variable "ssh_admin_user" { 
  description = "Pre-existing ssh admin user of the image"
  type        = string
  default     = "ubuntu"
}

variable "admin_user_password" { 
  description = "Optional password for admin user"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_admin_public_key" {
  description = "Public ssh part of the ssh key the admin will be able to login as"
  type        = string
}

variable "cloud_init_configurations" {
  description = "List of cloud-init configurations to add to the vm"
  type        = list(object({
    filename = string
    content  = string
  }))
  default = []
}

variable "hostname" {
  description = "Value to assign to the hostname. If left to empty (default), 'name' variable will be used."
  type        = object({
    hostname = string
    is_fqdn  = string
  })
  default = {
    hostname = ""
    is_fqdn  = false
  }
}

variable "running" {
  description = "Whether the vm should be running or stopped"
  type        = bool
  default     = true
}

variable "autostart" {
  description = "Whether the vm should start on host boot up"
  type        = bool
  default     = true
}

variable "chrony" {
  description = "Chrony configuration for ntp. If enabled, chrony is installed and configured, else the default image ntp settings are kept"
  type = object({
    enabled = bool,
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#server
    servers = list(object({
      url     = string,
      options = list(string)
    })),
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#pool
    pools = list(object({
      url     = string,
      options = list(string)
    })),
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#makestep
    makestep = object({
      threshold = number,
      limit     = number
    })
  })
  default = {
    enabled = false
    servers = []
    pools   = []
    makestep = {
      threshold = 0,
      limit     = 0
    }
  }
}

variable "extra_users" {
  description = "List of extra ssh users"
  type = list(object({
    username     = string
    public_key   = string
    is_sudo_user = bool
  }))
  default = []
}