[![Build Status](https://travis-ci.org/uu59/gem_release_helper.svg?branch=master)](https://travis-ci.org/uu59/gem_release_helper)
[![Gem Version](https://badge.fury.io/rb/gem_release_helper.svg)](http://badge.fury.io/rb/gem_release_helper)
[![Code Climate](https://codeclimate.com/github/uu59/gem_release_helper/badges/gpa.svg)](https://codeclimate.com/github/uu59/gem_release_helper)
[![Test Coverage](https://codeclimate.com/github/uu59/gem_release_helper/badges/coverage.svg)](https://codeclimate.com/github/uu59/gem_release_helper/coverage)

# GemReleaseHelper



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gem_release_helper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gem_release_helper

Load rake tasks at your Rakefile:

    require "bundler/gem_tasks"
    require "gem_release_helper/tasks"
    GemReleaseHelper::Tasks.install({
      gemspec: "./your_gem.gemspec",
      github_name: "user/repo",
    })

## Usage

    $ bundle exec rake -T
    rake build                     # Build embulk-input-your-plugin-0.1.0.gem into the pkg directory
    rake generate:bump_version     # Bump version
    rake generate:changelog        # Generate CHANGELOG.md from previous release
    rake generate:gemfiles         # Generate gemfiles to test this plugin with released Embulk versions (since MIN_VERSION)
    rake generate:prepare_release  # Generate chengelog then bump version
    rake install                   # Build and install embulk-input-your-plugin-0.1.0.gem into system gems
    rake release                   # Create tag v0.1.0 and build and push embulk-input-your-plugin-0.1.0.gem to Rubygems

### generate:gemfiles

    $ mkdir gemfiles
    $ cat > gemfiles/template.erb
    source 'https://rubygems.org/'
    gemspec :path => '../'

    gem "embulk", "<%= version %>"

    $ tree gemfiles
    gemfiles
    └── template.erb

    0 directories, 1 file
    $ bundle exec rake generate:gemfiles MIN_VERSION=0.6.10
    I, [2015-08-11T11:03:37.202083 #10238]  INFO -- : Generate Embulk gemfiles from '0.6.10' to latest
    I, [2015-08-11T11:03:38.966539 #10238]  INFO -- : Updated Gemfiles '0.6.10' to '0.6.21'
    $ tree gemfiles
    gemfiles
    ├── embulk-0.6.10
    ├── embulk-0.6.11
    ├── embulk-0.6.12
    ├── embulk-0.6.13
    ├── embulk-0.6.14
    ├── embulk-0.6.15
    ├── embulk-0.6.16
    ├── embulk-0.6.17
    ├── embulk-0.6.18
    ├── embulk-0.6.19
    ├── embulk-0.6.20
    ├── embulk-0.6.21
    ├── embulk-latest
    └── template.erb
    $ cat gemfiles/embulk-latest
    source 'https://rubygems.org/'
    gemspec :path => '../'

    gem "embulk", "> 0.6.10"

    $ cat gemfiles/embulk-0.6.18
    source 'https://rubygems.org/'
    gemspec :path => '../'

    gem "embulk", "0.6.18"
