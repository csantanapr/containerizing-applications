## Introduction

blah

Expected completion: 5-10 minutes

- [Introduction](#introduction)
- [Spin up an environment](#spin-up-an-environment)
- [Connecting to your environment [RHPDS]](#connecting-to-your-environment-rhpds)
- [Getting Set Up](#getting-set-up)
- [Lab Materials [Not RHPDS]](#lab-materials-not-rhpds)
- [Lab Materials [RHPDS]](#lab-materials-rhpds)
- [OpenShift Container Platform](#openshift-container-platform)

## Spin up an environment

In an effort to make this lab repeatable, we offer it pre-configured in the [Red Hat Product Demo system](https://rhpds.redhat.com). For the easiest setup, please head there and launch the "Containerizing Applications: Existing and New" item in the "[Catalog](https://rhpds.redhat.com/catalog/explorer)." Proceed to [Connecting to your environment [RHPDS]](#connecting-to-your-environment-rhpds).

However, if you don't have access to the demo portal, you can also create a new RHEL8 Virtual Machine and run the [`configure-lab.sh`](../../setup/configure-lab.sh) script in the setup directory in this repo.

```bash
$ curl -o configure-lab.sh -L https://gitlab.com/2020-summit-labs/containerizing-applications/-/raw/master/setup/configure-lab.sh
$ cat configure-lab.sh
$ chmod a+x configure-lab.sh
$ ./configure-lab.sh
```

You will also need an OpenShift instance later in the lab. If you don't have one, you can use the upstream version by heading to [OKD.io](https://www.okd.io/). Follow the instructions for whatever way is best for you. You should find instructions for Linux, Windows, and MacOS.

Now proceed to [Getting Set Up](#getting-set-up)


## Connecting to your environment [RHPDS]

Once you launch the demo, you should receive an email with the credentials to ssh in to the "ClientVM". Do not ssh to the OpenShift Cluster as that isn't used from the command line in this lab.

## Getting Set Up
Since some of these labs will have long running processes, it is recommended to use something like `tmux` or `screen` in case you lose your connection at some point so you can reconnect. If you followed the steps above, you should already have `tmux`. `screen` is available in EPEL. 

In case you get disconnected use `screen -x` or `tmux attach` to reattach once you reestablish ssh connectivity. If you are unfamiliar with screen, check out this [quick tutorial](https://www.mattcutts.com/blog/a-quick-tutorial-on-screen/). For tmux here is a [quick tutorial](https://fedoramagazine.org/use-tmux-more-powerful-terminal/).

## Lab Materials

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
export OS_API='OS_API_URL'
export OS_ADMIN_USER='opentlc-mgr'
export OS_ADMIN_PASS='r3dh4t1!'
export OS_USER='lab-user'
export OS_PASS='r3dh4t1!'
```

### Environment Variables [RHPDS]
Now please replace `OS_API_URL` in `.bashrc` with the appropriate value. You should have it in your setup email (and don't forget the ports). The usernames and passwords should already be set correctly.  We will set `OS_REGISTRY_VALUE` a little later.

```bash
$ vi ~/.bashrc
$ source ~/.bashrc
```

### Environment Variables [Custom]
Now please replace the values in `.bashrc` with the appropriate values. You should have them from your OpenShift setup (and don't forget the ports). We will set `OS_REGISTRY_VALUE` a little later.

```bash
$ vi ~/.bashrc
$ source ~/.bashrc
```

### OpenShift Registry
Once you have the variables set, you can expose the OpenShift registry by and add it to our variables:

```bash
$ oc login -u $OS_ADMIN_USER -p $OS_ADMIN_PASS $OS_API
$ oc project openshift-image-registry
$ oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
$ sed -i -e "s|OS_REGISTRY_VALUE| \ `oc get routes -o jsonpath="{..items[*].spec.host}"`|g" ~/.bashrc #this sets OS_REGISTRY_VALUE
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

What is OpenShift? OpenShift, which you may remember as a "[PaaS](https://en.wikipedia.org/wiki/Platform_as_a_service)" to build applications on, has evolved into a complete container platform based on Kubernetes. With OpenShift, you can build from a platform, build from scratch, or anything else you can do in a container, and still get the complete lifecycle automation you loved in the older versions.

You are now ready to move on to the [next lab](../lab1/chapter1.md).
