#!/bin/bash

script_name=${0##*/}                               # Basename, or drop /path/to/file
script=${script_name%%.*}                          # Drop .ext.a.b
script_path=${0%/*}                                # Dirname, or only /path/to
script_path=$( [[ -d ${script_path} ]] && cd ${script_path} ; pwd)             # Absolute path
script_path_name="${script_path}/${script_name}"   # Full path and full filename to $0
absolute_script_path_name=$( /bin/readlink --canonicalize ${script_path}/${script_name})   # Full absolute path and filename to $0
absolute_script_path=${absolute_script_path_name%/*}                 # Dirname, or only /path/to, now absolute
script_basedir=${script_path%/*}                   # basedir, if script_path is .../bin/

# curl -s -L  http://10.0.2.2:8000/bootstrap.sh | sh

if [[ -x /opt/puppetlabs/bin/puppet ]] ; then
   echo "Puppet installed! Use the force..."
   #exit
fi

export PATH=/usr/bin
# Install packages
pkg_arr=()
for pkg in epel-release wget vim-enhanced git htop tmux rsync open-vm-tools ; do
   rpm -q ${pkg} > /dev/null || pkg_arr+="${pkg} "
done
[[ ${#pkg_arr[@]} -ge 1 ]] && yum -y install ${pkg_arr[@]}

# Install puppet
rpm -q puppet5-release > /dev/null || rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm
[[ ! -x /opt/puppetlabs/bin/puppet ]] && yum -y install puppet-agent


: << X
sudoedit $( sudo /opt/puppetlabs/bin/puppet config print environmentpath )/$( sudo /opt/puppetlabs/bin/puppet config print environment)/manifests/site.pp
sudo /opt/puppetlabs/bin/puppet parser validate $( sudo /opt/puppetlabs/bin/puppet config print environmentpath )/$( sudo /opt/puppetlabs/bin/puppet config print environment)/manifests/site.pp
sudo /opt/puppetlabs/bin/puppet apply -t --noop  /etc/puppetlabs/code/environments/production/manifests/site.pp

PUPPET=/opt/puppetlabs/bin/puppet
PUPPET_ENV_PATH=$( sudo ${PUPPET} config print environmentpath )
PUPPET_ENV=$( sudo ${PUPPET} config print environment )
PUPPET_SITE_PP=${PUPPET_ENV_PAT}/${PUPPET_ENV}/manifests/site.pp

sudoedit ${PUPPET_SITE_PP}
sudo ${PUPPET} parser validate ${PUPPET_SITE_PP}
sudo ${PUPPET} apply -t --noop  ${PUPPET_SITE_PP}


# install eyaml

# install r10k
# https://github.com/puppetlabs/r10k/blob/master/doc/dynamic-environments/quickstart.mkd
sudo /opt/puppetlabs/puppet/bin/gem install r10k
sudo mkdir --parents --mode=0755 --verbose /etc/puppetlabs/r10k
sudoedit /etc/puppetlabs/r10k/r10k.yaml
# r10k.yaml is checked for in the following locations:
#   - $PWD/r10k.yaml
#   - /etc/puppetlabs/r10k/r10k.yaml
#   - /etc/r10k.yaml


####
sudo yum install -y python-pip ncdu
sudo pip install --upgrade pip
sudo pip install pydf


####
https://www.jethrocarr.com/2015/05/10/introducing-pupistry/
https://www.jethrocarr.com/2016/01/23/secure-hiera-data-with-masterless-puppet/
https://www.puppefy.com/how-to-set-up-a-masterless-puppet-on-centos/

X

# Resources:
# https://github.com/tazjin/puppet-masterless
# https://www.digitalocean.com/community/tutorials/how-to-set-up-a-masterless-puppet-environment-on-ubuntu-14-04
# https://www.digitalocean.com/community/tutorials/how-to-install-puppet-in-standalone-mode-on-centos-7
# https://www.unixmen.com/setting-masterless-puppet-environment-ubuntu/
# https://www.slideshare.net/PuppetLabs/bashton-masterless-puppet
# https://www.slideshare.net/PuppetLabs/puppetconf-2014-1
# http://echorand.me/standalone-open-source-puppet-setup-on-fedora.html
# http://serverspec.org/
# http://codegist.net/code/masterless-puppet-centos/
# https://github.com/neillturner/kitchen-puppet
# https://github.com/daenney/pupa
# https://ask.puppet.com/question/23910/masterless-puppet-with-hiera-dynamic-lookup/
# https://puppet.com/docs/puppet/5.3/quick_start_helloworld.html
# https://www.packer.io/docs/provisioners/puppet-masterless.html
# http://www.devops-share.com/masterless-puppet-with-autoscaling/
# https://stackoverflow.com/questions/29759795/masterless-puppet-with-hiera
# https://github.com/szymonrychu/puppet-masterless
# http://www.mooreds.com/wordpress/archives/2059
# https://github.com/jordansissel/puppet-examples/tree/master/masterless
# https://puppet.com/presentations/de-centralise-and-conquer-masterless-puppet-dynamic-environment
# Short-lived Immutable servers with masterless puppet https://www.youtube.com/watch?v=yETgehoQmIs&feature=youtu.be
# https://github.com/MSMFG/tru-strap
# https://github.com/neilmillard/puppet-dockerhost
# https://www.cakesolutions.net/teamblogs/whats-in-a-server-name
# https://www.cakesolutions.net/teamblogs/cloudformation-best-practices
# https://www.cakesolutions.net/teamblogs/puppet-and-friends
# https://github.com/cornelf/puppet-and-friends
# http://www.knowceantech.com/2014/03/amazon-cloud-bootstrap-with-userdata-cloudinit-github-puppet/
   # cached: http://webcache.googleusercontent.com/search?q=cache:EHSv0fd1zJcJ:www.knowceantech.com/2014/03/amazon-cloud-bootstrap-with-userdata-cloudinit-github-puppet/&num=1&hl=en&gl=no&strip=1&vwsrc=0
# https://www.slideshare.net/auxesis/rump-making-puppetmasterless-puppet-meaty
# https://github.com/railsmachine/rump
# https://grahamgilbert.com/blog/2015/07/18/running-puppet-server-in-docker-part-3-hiera/
# http://garylarizza.com/blog/2014/03/07/puppet-workflow-part-3b/
# https://rnelson0.com/2014/07/21/hiera-r10k-and-the-end-of-manifests-as-we-know-them/
# https://techpunch.co.uk/development/how-to-build-a-puppet-repo-using-r10k-with-roles-and-profiles
# http://www.geoffwilliams.me.uk/puppet/r10k_integration
# http://www.geoffwilliams.me.uk/puppet/
# https://www.puppefy.com/how-to-set-up-a-masterless-puppet-on-centos/

# https://github.com/puppetlabs/control-repo
# https://github.com/example42/psick
# https://github.com/example42/control-repo-archive

# https://code.tutsplus.com/courses/puppet-vs-chef-comparing-configuration-management-systems/lessons/tools-of-the-trade-masterless-puppet-and-puppet-forge
