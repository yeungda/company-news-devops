#!/bin/bash
if [ ! -d "$HOME/.rvm" ]; then
  echo "installing rvm"
  bash < <(curl -s https://rvm.beginrescueend.com/install/rvm)
fi
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
. .rvmrc
which bundle | grep rvm >/dev/null || gem install bundler --version 1.0.13 --no-rdoc --no-ri
export BUNDLE_GEMFILE=$(pwd)/conf/Gemfile
bundle check || bundle install
rake -f conf/Rakefile $@
