#!/bin/bash

################################################################
GEM_INSTALL_DIR="./gems"
RUBYGEMS_INSTALL_DIR="$HOME/.rubygems"
RBENV_INSTALL_DIR="$HOME/.rbenv"
RBENV=$RBENV_INSTALL_DIR/bin/rbenv
RBENV_RUBY=$RBENV_INSTALL_DIR/shims/ruby
RBENV_GEM=$RBENV_INSTALL_DIR/shims/gem
RUBY_VERSION=2.2.3
################################################################

platform='unknown'
pkg_manager='unknown'

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  platform='linux'
  if type apt-get > /dev/null 2>&1; then
    pkg_manager='apt-get'
  elif type yum > /dev/null 2>&1; then
    pkg_manager='yum'
  else
    echo "No Package Manager Found"
    exit 1
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  platform='osx'
  pkg_manager='brew'
else
  echo "Unsupported OS: $OSTYPE"
  exit 1
fi

echo "Platform is $platform"
echo "Package manager is $pkg_manager"

#---------------------------------------------------------------
# Install RBENV
#---------------------------------------------------------------

echo 'Installing rbenv and Ruby build environment'

if [[ "$platform" == "osx" ]]; then
  if ! type brew > /dev/null 2>&1; then
    echo 'Homebrew is not installed'
    echo '!!! Setup Canceled !!!'
    exit 1
  fi
  brew update
  brew install rbenv
  brew install ruby-build
  brew install openssl libyaml libffi
  brew tap homebrew/dupes && brew install apple-gcc42
  RBENV=/usr/local/bin/rbenv
fi

if [[ "$platform" == "linux" ]]; then
  if ! [ -d "$RBENV_INSTALL_DIR" ]; then
    if ! type git >/dev/null 2>&1; then
      echo 'Git is not installed'
      exit 1
    else
      echo 'Git is installed'
    fi

    git clone https://github.com/rbenv/rbenv.git $RBENV_INSTALL_DIR
    git clone https://github.com/rbenv/ruby-build.git $RBENV_INSTALL_DIR/plugins/ruby-build

    ############################################################################
    # Disable the following lines if you do not have Root privilege
    if [[ "$pkg_manager" == "apt-get" ]]; then
      sudo apt-get -y install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev
    elif [[ "$pkg_manager" == "yum" ]]; then
      sudo yum install -y patch libyaml-devel glibc-headers autoconf gcc-c++ glibc-devel readline-devel zlib-devel libffi-devel openssl-devel automake libtool bison sqlite-devel
    fi
    ############################################################################

    #echo '######################################################################'
    #echo 'To speed up RBEV, try to compile dynamic bash extension:'
    #echo 'cd $RBENV_INSTALL_DIR && src/configure && make -C src'
    #echo '######################################################################'
  fi
fi

#---------------------------------------------------------------
# Add RBENV path to $PATH
#---------------------------------------------------------------

echo 'Setting up RBENV'

export RBENV_VERSION=$RUBY_VERSION
echo '######################################################################'
echo 'Adding following lines to ~/.bash_profile'
echo '----------------------------------------------------------------------'
echo "  export PATH=$RBENV_INSTALL_DIR/bin:\$PATH"
echo "  eval \"\$(rbenv init -)\""
echo "  export RBENV_VERSION=$RUBY_VERSION"
echo '######################################################################'
echo "export PATH=$RBENV_INSTALL_DIR/bin:\$PATH" >> ~/.bash_profile
echo "eval \"\$(rbenv init -)\"" >> ~/.bash_profile
echo "export RBENV_VERSION=$RUBY_VERSION" >> ~/.bash_profile

export PATH=$RBENV_INSTALL_DIR/bin:$PATH

source ~/.bash_profile

#---------------------------------------------------------------
# Initialize RBENV
#---------------------------------------------------------------

echo 'Initializing RBENV'
$RBENV init

#---------------------------------------------------------------
# Install Ruby
#---------------------------------------------------------------

echo "Installing Ruby $RUBY_VERSION"
$RBENV install -s $RUBY_VERSION
$RBENV rehash

cur_ruby="$(command -v ruby)"
echo 'Expected Ruby is '$RBENV_RUBY
echo 'Current  Ruby is '$cur_ruby

if ! [[ "$RBENV_RUBY" == "$cur_ruby" ]]; then
  exit 1
fi

cur_ruby_version="$(ruby -v)"
echo "Expected Ruby Version is $RUBY_VERSION"
echo 'Current  Ruby version is '$cur_ruby_version

if ! [[ "$cur_ruby_version" == "ruby $RUBY_VERSION"* ]]; then
  exit 1
fi

echo 'Ruby is OK'

#---------------------------------------------------------------
# Install RubyGems
#---------------------------------------------------------------

cur_gem=$(command -v gem)

echo "Expected Gem is $RBENV_GEM"
echo "Current  Gem is $cur_gem"

if ! [[ "$RBENV_GEM" == "$cur_gem" ]]; then
  exit 1
fi

echo 'RubyGems is OK'

#---------------------------------------------------------------
# Install Bundler
#---------------------------------------------------------------

echo 'Installing bundler'

if ! type bundle >/dev/null 2>&1; then
  echo 'Bundler is not installed'
  gem install bundler
else
  echo 'Bundler is installed'
fi

if ! type bundle >/dev/null 2>&1; then
  echo 'Bundler is not installed'
  exit 1
fi

echo 'Bundler is OK'

#---------------------------------------------------------------
# Install Gems
#---------------------------------------------------------------

echo 'Installing gems'

bundle install

echo 'All gems are installed'

