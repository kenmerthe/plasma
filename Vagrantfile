Vagrant.configure(2) do |config|
  vm = config.vm

  vm.box = 'boxcutter/debian82'

  vm.provision :update,
    type: :shell,
    inline: 'apt-get update'

  vm.provision :build,
    type: :shell,
    inline: 'cd /vagrant && make'

end
