# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    config.vm.define :local, primary: true do |local|

        # Ubuntu version
        local.vm.box = "ubuntu/trusty64"

        # VirtualBox configuration
        local.vm.provider "virtualbox" do |vb|
            vb.customize ["modifyvm", :id, "--memory", 2048, "--cpus", "2"]
            vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
            vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
            vb.customize ["modifyvm", :id, "--usb", "off"]
            vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
        end

        # Network
        local.vm.hostname = "oliver-thebault"
        local.vm.network "private_network", ip: "192.168.100.6"

        # Share folders
        local.vm.synced_folder ".", "/var/www/oliver-thebault/", id:"project-root", type: "nfs", mount_options: ["nolock,vers=3,udp,noatime,actimeo=1"]

        # Ansible provisionning
        local.vm.provision :ansible do |ansible|
            ansible.playbook = "ansible/app.yml"
            ansible.limit = "all"
            ansible.extra_vars = {
                sites: [
                    {
                        name: 'oliver-thebault',
                        docroot: '/var/www/oliver-thebault',
                        server_name: 'oliver-thebault.dev',
                        template: 'vhost.symfony2.j2'
                    }
                ],
                mysql: {
                    databases: [
                        {
                            name: 'oliver-thebault'
                        }
                    ]
                },
                workspace: '/var/www/oliver-thebault'
            }
        end

    end

end
