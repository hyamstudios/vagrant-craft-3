# Vagrant Craft 3

Starter Craft CMS 3 setup using Vagrant for local development. This setup uses a special port number to allow testing the site without modifying a hosts file. The site should be accessible to other devices on the same network.

Initial site url is http://localhost:8378. Or using the local computer name like [http://COMPUTER_NAME:8378](http://COMPUTER_NAME:8378). Port number is adjustable modified in the Vagrantfile.

Vagrant settings support macOS and Windows. Virtual machine is running Ubuntu 16 with PHP 7.0.

Installation includes Xdebug for PHP debugging and Visual Studio Code launch.json.

## Requirements

- [Vagrant](https://www.vagrantup.com/)
- [Virtual Box](https://www.virtualbox.org/)

For deployment to Digital Ocean, you'll need

- [Vagrant DigitalOcean Plugin](https://github.com/devopsgroup-io/vagrant-digitalocean)
- [Vagrant Secret Plugin](https://github.com/tcnksm/vagrant-secret)

## Instructions

1. Clone/download repository
1. Run `vagrant secret-init`
1. Use `vagrant-secret-example.yaml` as an example to fill in the Vagrant secret file: `./vagrant/secret.yaml`

## Deploy A Droplet

1. Make sure you already have the Digital Ocean API Token at hand, as well as your SSH key was already added to DO's dashboard.
1. Run `vagrant up digitalocean`, a droplet will be created and configured.
1. When it is done, copy the droplet IP and configure your domain to point to it.
1. If HTTPS does not work, run `vagrant provision digitalocean`, it will run LetsEncrypt process again.
1. Go to `https://YOUR_DOMAIN/admin/install` to finish CraftCMS setup.
1. Don't forget to rename the droplet in Digital Ocean!

## Local Setup

1. Run `vagrant up local` and wait for installation
1. Go to http://localhost:8378/admin to finalize Craft installation
   1. Fill in fields – password as `password`, database as `craft`
   1. Create first admin account
   1. Enter site details, leaving Base URL = **@web**

## Changelog

**2019-07-25**

- Add digital ocean deployment option

**2018-03-30**

- Added PHP Intl module
- Changed PHP memory limit to 256MB
- Changed Craft setup to automatically apply database settings
- Removed temporary index file as Craft now includes one

**2018-03-27**

- Added Xdebug
- Added Visual Studio Code launch.json for debugging with Xdebug
- Removed custom globals URI_PORT and SITE_URL by using @web alias for siteUrl
