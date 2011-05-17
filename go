#!/bin/bash
export BUNDLE_GEMFILE=$(pwd)/conf/Gemfile
bundle check || bundle install
rake -f conf/Rakefile $@
