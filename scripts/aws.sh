#!/usr/bin/env bash

sudo mkdir -p /fastai
sudo mount /dev/xvdh /fastai
ssh-agent /bin/bash
ssh-add /fastai/.ssh/id_rsa

# Install dot files
cd /fastai/tools/dotfiles
make


cd /fastai/
