# -*- mode: ruby -*-
# vi: set ft=ruby :

# Determine if we are running on windows
require 'rbconfig'
is_windows = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)

Vagrant.configure(2) do |config|

  config.vm.define "digitalocean" do |config|
    config.vm.provider :digital_ocean do |provider, override|
      override.ssh.private_key_path = '~/.ssh/id_rsa'
      override.vm.box = 'digital_ocean'
      override.vm.box_url = "https://github.com/devopsgroup-io/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      override.vm.synced_folder '.', '/vagrant', :disabled => true
      override.nfs.functional = false
      override.vm.allowed_synced_folder_types = :rsync
      provider.ssh_key_name = Secret.digital_ocean_ssh_key_name
      provider.token = Secret.digital_ocean_token
      provider.image = 'ubuntu-19-04-x64'
      provider.region = 'fra1'
      provider.size = '2gb'
    end
    # Run the shell commands
    config.vm.provision "shell",
      path: "bootstrap-server.sh",
      env: {
        "SITE_DOMAIN" => Secret.site_domain
      }
  end

  config.vm.define "local" do |local|
    local.vm.box = "ubuntu/disco64"
    # Port is usually the phone-coded first 4 characters of the final URL (eg. test.com = 8378)
    local.vm.network "forwarded_port", guest: 80, host: 8378 # Test
    local.vm.network "private_network", type: "dhcp"
    # For windows use SMB else use NFS to sync files to guest host
    if is_windows
      local.vm.synced_folder ".", "/vagrant",
        type: "smb",
        owner: "www-data",
        group: "www-data",
        mount_options: [ "rw", "mfsymlinks" ]
    else
      local.vm.synced_folder ".", "/vagrant",
        nfs: true,
        mount_options: [ "rw", "tcp", "fsc", "actimeo=1" ]
    end
    # Set VirtualBox memory and allow symbolic links on Windows
    local.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
    end
    # Run the shell commands
    local.vm.provision "shell",
      path: "bootstrap-server.sh",
      env: {
        "IS_LOCAL" => true,
        "SITE_DOMAIN" => Secret.site_domain
      }
  end
end
