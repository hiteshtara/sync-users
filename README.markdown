
# Sync Users
---

Last Updated: May 24, 2016

## Requirements

- Ruby 2.0+
- Oracle Client or JDBC
- Java if using JRuby
- rbenv
- Latest RubyGems
- Latest Bundler
- git (to install rbenv)
- Ruby Build Environment

  ### RHEL/CentOS/Fedora

  ```bash
  > sudo yum install -y patch libyaml-devel glibc-headers autoconf gcc-c++ glibc-devel readline-devel zlib-devel libffi-devel openssl-devel automake libtool bison sqlite-devel
  ```

  ### Devian/Ubuntu/Mint

  ```bash
  > sudo apt-get -y install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev
  ```

## Oracle Database Access

There two options to aceess Oracle databases:

- Oracle Client
- JDBC

### Oracle Client
---

In case of using Oracle Client:

- Use MRI Ruby
- oci8 gem is required.
- Set ORACLE_HOME if using Full Client, or
- Set LD_LIBRARY_PATH if using Instant Client

### JDBC
---

In case of using JDBC:

- Use Jruby
- Put ojdbc7-12.1.0.2.jar in ~/.rbenv/versions/jruby-<VERSION>/lib or <APP_ROOT>/lib
- Cannot use oci8 gem

## JRUBY

Confirmed working with both Jruby 9.0.5.0 and 9.1.0.0.

If you get:

  ```
  Error: Your application used more memory than the safety cap of 500M
  ```

  or

  ```
  java.lang.OutOfMemoryError: GC overhead limit exceeded
  ```


Set the following JAVA options through JRUBY_OPTS:

```
export JRUBY_OPTS="J-Xmx2048m"
```

## Setup

```
Install Ruby 2.0 or higher (2.3 recommended)
Install latest RubyGems
Install latest Bundler 
> bundle install
```

or

```bash
> ./setup.sh
```

or

```bash
> ./setup_jruby.sh
```

The setup.sh will install Ruby with rbenv.
The setup.sh will modify ~/.bash_profile to enable rbenv.
All the gem files will be installed into ~/.rbenv directory.

If you want to use RVM, you should not use this setup script.
RVM and rbenv cannot be used at the same time because of the way RVM handles gem.

## BASH Profile
---

The following lines will set up rbenv environment in the current shell session:

```bash
export PATH=$HOME/.rbenv/bin:$PATH
eval "$(rbenv init -)"
export RBENV_VERSION=2.2.3
```

## Local Gems

Gems can be installed under ./gems by the setup.sh.
$LOAD_PATH will be dynamically changed to include lib directories under ./gems by sync_user.

You can change the install location

with command line:

```bash
> bundle install --path=./gems
```

or

with config file (<APP-ROOT>/.bundle/config):

```bash
> BUNDLE_PATH: ./gems
> BUNDLE_DISABLE_SHARED_GEMS: true
```

If you install gems with Ruby version manager such as rbenv and RVM, or install them globally,
you can ignore ./gems directory.

Also, you can use any directories for gem installation if they are set in $LOAD_PATH.

## Configuration

The default configuration file is config/development.json.
See the configuration file for details.

## Logging

Logging is configurable via the configuration file.
The default location of the log file is log/development.log.

Supported log level is {DEBUG|INFO|WARN|ERROR|FATAL}

## Rbenv Commands

```bash
> rbenv versions               # List all installed Rubies
> rbenv version                # Show current selected Ruby
> rbenv install -l             # List all the available Rubies
> rbenv install <RUBY-VERSION> # Install specific version of Ruby
> rbenv shell                  # Show current shell session Ruby version (RBENV_VERSION)
> rbenv shell <RUBY_VERSION>   # Set specific Ruby version to current shell session
> rbenv local                  # Show current local Ruby version (.ruby-version of current working directory)
> rbenv local <RUBY_VERSION>   # Set specific Ruby version to local
> rbenv rehash                 # Install shims for Ruby executables. Run this command after intalling Ruby.
> rbenv init                   # Initialize rbenv to enable shims
```

## Create Executable Jar File

```bash
> gem install warbler
> warbler executable jar
```

Creates sync-users.jar

## Run Jar

### Requirements

- config directory in Application Root
- log directory in Application Root
- development.json in ./config to run commands

```bash
> java -jar sync-users.jar <COMMAND> [PATH-TO-CONFIG]
```

See the details for Usage

## Usage

```bash
> bin/sync_user run [PATH-TO-CONFIG]
> bin/sync_user dryrun [PATH-TO-CONFIG]
> bin/sync_user env [PATH-TO-CONFIG]
> bin/sync_user kim-status [PATH-TO-CONFIG]
> bin/sync_user core-status [PATH-TO-CONFIG]
> bin/sync_user peek <USERNAME> [PATH-TO-CONFIG]
> bin/sync_user help
```

## With CRON or Non-interactive Shell

Rbenv must be enabled before sync_user runs.

```bash
> 0 4 * * * source $HOME/.bash_profile; PATH/TO/sync_user run config/production.json
```

With Executable Jar

```bash
> 0 4 * * * java -jar PATH/TO/sync_users.jar run config/production.json
```

