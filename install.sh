#!/bin/bash

#sudo cp covert-radio /usr/local/bin

HOME="/opt/covert-radio"

# Create project home
sudo mkdir -p $HOME

sudo cp -R bin $HOME
sudo cp -R lib $HOME
sudo cp -R var $HOME

sudo cp README.md $HOME
sudo cp LICENSE $HOME

# enable auto-completion (terminals will need to reload before this will take effect)
sudo ln -s $HOME/bin/covert_radio_complete.sh /etc/bash_completion.d/covert-radio

# put executable in folder in PATH
sudo ln -s $HOME/bin/covert-radio /usr/local/bin
