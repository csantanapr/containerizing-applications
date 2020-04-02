## Introduction

blah

Expected completion: 5-10 minutes

## Spin up an environment

In an effort to make this lab repeatable, we offer it pre-configured in the [Red Hat Product Demo system](https://rhpds.redhat.com). For the easiest setup, please head there and launch the "Containerizing Applications: Existing and New" item in the "[Catalog](https://rhpds.redhat.com/catalog/explorer)."

However, if you don't have access to the demo portal, you can also create a new RHEL8 Virtual Machine and run the [`configure-lab.sh`](../../setup/configure-lab.sh) script in the setup directory in this repo.

## Connecting to your environment [RHPDS]

Once you launch the demo, you should receive an email with the credentials to ssh in to the "ClientVM". Do not ssh to the OpenShift Cluster as that isn't used in this lab.

## Getting Set Up
For the sake of time, some of the required setup has already been taken care of on your AWS VM. For future reference though, the easiest way to get started is to head over to the OpenShift Origin repo on github and follow the "[Getting Started](https://github.com/openshift/origin/blob/master/docs/cluster_up_down.md)" instructions. The instructions cover getting started on Windows, MacOS, and Linux.

Since some of these labs will have long running processes, it is recommended to use something like `tmux` or `screen` in case you lose your connection at some point so you can reconnect:
```bash
$ sudo yum -y install screen
$ screen
```

In case you get disconnected use `screen -x` or `tmux attach` to reattach once you reestablish ssh connectivity. If you are unfamiliar with screen, check out this [quick tutorial](https://www.mattcutts.com/blog/a-quick-tutorial-on-screen/). For tmux here is a [quick tutorial](https://fedoramagazine.org/use-tmux-more-powerful-terminal/).


## Lab Materials [Not RHPDS]

Clone the lab repository from gitlab:
```bash
$ cd ~/
$ git clone https://gitlab.com/2020-summit-labs/containerizing-applications
```

## Lab Materials [RHPDS]

Make sure the lab materials are up to date by git pulling the repo:
```bash
$ cd ~/containerizing-applications
$ git pull
```

Now that we have all the content, we need to do a little bit of local configuration to support the dynamic nature of the lab.

Next, take a look in `~/.bashrc` and make sure you have the following environment variables, even though they are (likely) not set correctly. You should have:

 ```bash
$ tail -6 ~/.bashrc
# User specific aliases and functions
export OS_REGISTRY='OS_REGISTRY_VALUE'
export OS_API='OS_API_VALUE'
export OS_ADMIN_USER='opentlc-mgr'
export OS_ADMIN_PASS='r3dh4t1!'
export OS_USER='lab-user'
export OS_PASS='r3dh4t1!'
```

Now please replace "\<item\>" with the OpenShift API URL you got in your setup email (and don't forget the port). Or, if not using RHPDS, your setup:

```bash
$ sed -i -e "s|OS_API_VALUE|<item>|g" ~/.bashrc
$ source ~/.bashrc
```

Once you have that, you can expose the OpenShift registry by and add it to our variables:

```bash
$ oc login -u $OS_ADMIN_USER -p $OS_ADMIN_PASS $OS_API
$ oc project openshift-image-registry
$ oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
$ sed -i -e "s|OS_REGISTRY_VALUE| \ `oc get routes -o jsonpath="{..items[*].spec.host}"`|g" ~/.bashrc
```

Now let's make our lab user able to access it:

```bash
$ # user most have logged in at least once
$ oc login -u $OS_USER -p $OS_PASS $OS_API 
$ oc login -u $OS_ADMIN_USER -p $OS_ADMIN_PASS $OS_API # go back to admin
$ oc policy add-role-to-user registry-viewer $OS_USER
$ oc policy add-role-to-user registry-editor $OS_USER
```

## OpenShift Container Platform

What is OpenShift? OpenShift, which you may remember as a "[PaaS](https://en.wikipedia.org/wiki/Platform_as_a_service)" to build applications on, has evolved into a complete container platform based on Kubernetes. If you remember the "[DIY Cartridges](https://github.com/openshift/origin-server/blob/master/documentation/oo_cartridge_guide.adoc#diy)" from older versions of Openshift, essentially, OpenShift v3 has expanded the functionality to provide complete containers. With OpenShift, you can build from a platform, build from scratch, or anything else you can do in a container, and still get the complete lifecycle automation you loved in the older versions.

You are now ready to move on to the [next lab](../lab1/chapter1.md).
