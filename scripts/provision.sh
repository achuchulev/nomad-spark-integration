#!/bin/bash

which wget unzip curl docker make ruby &>/dev/null || {
  sudo apt-get update
  sudo apt-get install -y wget unzip curl docker.io make ruby
  sudo usermod -a -G docker ubuntu
  sudo gem install rubyzip
}

# install packer
which packer || {
  cd /usr/local/bin
  curl -sSL https://raw.githubusercontent.com/kikitux/download-hashicorp-tools/master/download-packer.rb | sudo ruby
}

# install terraform
which terraform &>/dev/null || {
  pushd /usr/local/bin
  sudo wget https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_linux_amd64.zip
  sudo unzip terraform_0.11.10_linux_amd64.zip
  popd
}
