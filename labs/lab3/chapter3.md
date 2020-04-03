# LAB 3: Deconstructing an application into microservices

In this lab you will deconstruct an application into microservices, creating a multi-container application. In this process we explore the challenges of networking, storage and configuration.

This lab should be performed on **YOUR ASSIGNED AWS VM** as `ec2-user` unless otherwise instructed.

NOTE: In the steps below we use `vi` to edit files.  If you are unfamiliar, this is a [good beginner's guide](https://www.howtogeek.com/102468/a-beginners-guide-to-editing-text-files-with-vi/). In short, "ESC" switches to command mode, "i" let's you edit, "wq" let's you save and exit, "q!" let's you exit without saving (all executed in command mode).

Expected completion: 20-30 minutes

## Decompose the application

In the previous lab we created an "all-in-one" application. Let's enter the container and explore.

```bash
$ sudo podman exec -it bigapp /bin/bash
```

### Services

From the container namespace list the log directories.

```bash
[CONTAINER_NAMESPACE]# ls -l /var/log/
```

We see `httpd` and `mariadb`. These are the services that make up the Wordpress application.

### Ports

We saw in the Dockerfile that port 80 was exposed. This is for the web server. Let's look at the mariadb logs for the port the database uses:

```bash
[CONTAINER_NAMESPACE]# grep port /var/log/mariadb/mariadb.log
```

This shows port 3306 is used.

### Storage

#### Web server

The Wordpress tar file was extracted into `/var/www/html`. List the files.

```bash
[CONTAINER_NAMESPACE]# ls -l /var/www/html
```

These are sensitive files for our application and it would be unfortunate if changes to these files were lost. Currently the running container does not have any associated "volumes", which means that if this container dies all changes will be lost. This mount point in the container should be backed by a "volume". Later in this lab, we'll use a directory from our host machine to back the "volume" to make sure these files persist.

#### Database

Inspect the `mariadb.log` file to discover the database directory.
```bash
[CONTAINER_NAMESPACE]# grep databases /var/log/mariadb/mariadb.log
```

Again, we have found some files that are in need of some non-volatile storage. The `/var/lib/mysql` directory should also be mounted to persistent storage on the host.

Now that we've inspected the container stop and remove it. `podman ps -ql` (don't forget `sudo`) prints the ID of the latest created container.  First you will need to exit the container.
```bash
[CONTAINER_NAMESPACE]# exit
$ sudo podman stop $(sudo podman ps -ql)
$ sudo podman rm $(sudo podman ps -ql)
```

If we are confident in what we are doing we can also "single-line" the above with `sudo podman rm -f $(sudo podman ps -ql)` by itself.

## Create the Dockerfiles

Now we will develop the two images. Using the information above and the Dockerfile from Lab 2 as a guide, we will create Dockerfiles for each service. For this lab we have created a directory for each service with the required files for the service. Please explore these directories and check out the contents and the startup scripts.
```bash
$ mkdir ~/workspace
$ cd ~/workspace
$ cp -R ~/containerizing-applications/labs/lab3/mariadb .
$ cp -R ~/containerizing-applications/labs/lab3/wordpress .
$ ls -lR mariadb
$ ls -lR wordpress
```

### MariaDB Dockerfile

1. In a text editor create a file named `Dockerfile` in the `mariadb` directory. (There is a reference file in the `mariadb` directory if needed)

        $ vi mariadb/Dockerfile

1. Add a `FROM` line that uses a specific image tag. Also add `maintainer` information.

        FROM registry.access.redhat.com/ubi8:8.1-397
        LABEL maintainer="student@example.com"

1. Add the required packages. We'll include `yum clean all` at the end to clear the yum cache.

        RUN yum -y install \
              mariadb-server openssl psmisc net-tools hostname procps && \
            yum clean all

1. Add the dependent scripts and modify permissions to support non-root container runtime.

        ADD scripts /scripts
        RUN chmod 755 /scripts/* && \
            MARIADB_DIRS="/var/lib/mysql /var/log/mariadb /run/mariadb" && \
            chown -R mysql:0 ${MARIADB_DIRS} && \
            chmod -R g=u ${MARIADB_DIRS}

1. Add an instruction to expose the database port.

        EXPOSE 3306

1. Add a `VOLUME` instruction. This ensures data will be persisted even if the container is lost. However, it won't do anything unless, when running the container, host directories are mapped to the volumes.

        VOLUME /var/lib/mysql

1. Switch to a non-root `USER` uid. The default uid of the mysql user is 27.

        USER 27

1. Finish by adding the `CMD` instruction.

        CMD ["/bin/bash", "/scripts/start.sh"]

Save the file and exit the editor.

### Wordpress Dockerfile

Now we'll create the Wordpress Dockerfile. (As before, there is a reference file in the `wordpress` directory if needed)

1. Using a text editor create a file named `Dockerfile` in the `wordpress` directory.

        $ vi wordpress/Dockerfile

1. Add a `FROM` line that uses a specific image tag. Also add `maintainer` information.

        FROM registry.access.redhat.com/ubi8:8.1-397
        LABEL maintainer="student@example.com"

1. Add the required packages. We'll include `yum clean all` at the end to clear the yum cache.

        RUN yum -y install \
              httpd php php-mysqlnd php-gd openssl psmisc procps && \
            yum clean all

1. Configure php-fpm which you have to do differently when you aren't using systemd.

        # running php-fpm directly (not using systemd) does
        # not create the socket directory
        RUN mkdir -p /run/php-fpm
        RUN chown 48:48 /run/php-fpm
        RUN chmod 0755 /run/php-fpm

1. Add the dependent scripts and make them executable.

        ADD scripts /scripts
        RUN chmod 755 /scripts/*

1. Add the Wordpress source from gzip tar file. podman will extract the files. Also, modify permissions to support non-root container runtime. Switch to port 8080 for non-root apache runtime.

        COPY latest.tar.gz /latest.tar.gz
        RUN tar xvzf /latest.tar.gz -C /var/www/html --strip-components=1 && \
            rm /latest.tar.gz && \
            sed -i 's/^Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf && \
            APACHE_DIRS="/var/www/html /usr/share/httpd /var/log/httpd /run/httpd" && \
            chown -R apache:0 ${APACHE_DIRS} && \
            chmod -R g=u ${APACHE_DIRS}

1. Add an instruction to expose the web server port.

        EXPOSE 8080

1. Add a `VOLUME` instruction. This ensures data will be persisted even if the container is lost.

        VOLUME /var/www/html/wp-content/uploads

1. Switch to a non-root `USER` uid. The default uid of the apache user is 48.

        USER 48

1. Finish by adding the `CMD` instruction.

        CMD ["/bin/bash", "/scripts/start.sh"]

Save the Dockerfile and exit the editor.

## Build Images, Test and Push

Now we are ready to build the images to test our Dockerfiles.

1. Build each image. When building an image podman requires the path to the directory of the Dockerfile.

        $ sudo podman build -t mariadb mariadb/
        $ sudo podman build -t wordpress wordpress/

1. If the build does not succeed then resolve the issue and build again. Once successful, list the images.

        $ sudo podman images

1. Create the local directories for persistent storage. Match the directory permissions we set in our Dockerfiles.

        $ mkdir -p ~/workspace/pv/mysql ~/workspace/pv/uploads
        $ sudo chown -R 27 ~/workspace/pv/mysql
        $ sudo chown -R 48 ~/workspace/pv/uploads

1. Run the wordpress image first. See an explanation of all the `podman run` options we will be using below:

  * `-d` to run in daemonized mode
  * `-v <host/path>:<container/path>:z` to mount (technically, "bindmount") the directory for persistent storage.  The :z option will label the content inside the container with the SELinux MCS label that the container uses so that the container can write to the directory.  Below we'll inspect the labels on the directories before and after we run the container to see the changes on the labels in the directories.
  * `-p <host_port>:<container_port>` to map the container port to the host port

```bash
$ ls -lZd ~/workspace/pv/uploads
$ sudo podman run -d -p 8080:8080 -v ~/workspace/pv/uploads:/var/www/html/wp-content/uploads:z -e DB_ENV_DBUSER=user -e DB_ENV_DBPASS=mypassword -e DB_ENV_DBNAME=mydb -e DB_HOST=0.0.0.0 -e DB_PORT=3306 --name wordpress wordpress
```
Note: See the difference in SELinux context after running with a volume & :z.
```bash
$ ls -lZd ~/workspace/pv/uploads
$ sudo podman exec wordpress ps aux #we can also directly exec commands in the container
```

Check volume directory ownership inside the container
```bash
$ sudo podman exec wordpress stat --format="%U" /var/www/html/wp-content/uploads
```

Now we can check out how wordpress is doing
```bash
$ sudo podman logs wordpress
$ sudo podman ps
$ curl -L http://localhost:8080 #note we indicated the port to use in the run command above
```

  **Note**: the `curl` command returns an error but demonstrates
            a response on the port.

5. Bring up the database (mariadb) for the wordpress instance. For the mariadb container we need to specify an additional option to make sure it is in the same "network" as the apache/wordpress container and not visible outside that container:

  * `--network=container:<alias>` to link to the wordpress container
```bash
$ ls -lZd ~/workspace/pv/mysql
$ sudo podman run -d --network=container:wordpress -v ~/workspace/pv/mysql:/var/lib/mysql:z -e DBUSER=user -e DBPASS=mypassword -e DBNAME=mydb --name mariadb mariadb
```
Note: See the difference in SELinux context after running w/ a volume & :z.
```bash
$ ls -lZd ~/workspace/pv/mysql
$ ls -lZ ~/workspace/pv/mysql
$ sudo podman exec mariadb ps aux
```

Check volume directory ownership inside the container
```bash
$ sudo podman exec mariadb stat --format="%U" /var/lib/mysql
```

Now we can check out how the database is doing
```bash
$ sudo podman logs mariadb
$ sudo podman ps
$ sudo podman exec mariadb curl localhost:3306 # gives an error but you can tell mariadb answered
$ sudo podman exec mariadb mysql -u user --password=mypassword -e 'show databases'
$ curl localhost:3306 #as you can see the db is not generally visible
$ curl -L http://localhost:8080 #and now wp is happier!
```


## Use a Container Registry

One of the things we can use our OpenShift cluster for is as a container registry. A container registry let's us share images with other machines including OpenShift itself. In a sense, `podman images` is a container registry but it is private to this machine. We want to make the images available elsewhere.

Let's get the images we created deployed to the registry. 

### Insecure Registries

For this lab, and likely for your development environments, you will be using self-signed certificates on your registry. As a result, `podman` will not allow their use unless explicitly told to. You can pass `--tls-verify=false` on the command line but this is prone to all kinds of error (and accidental innappropriate use).  

However, given the dynamic nature of this lab, it is a little hard to automatically or consistently add the insecure registry. As a result, we will be using `--tls-verify=false`. If you do want to experiment with the registry change, you can edit `/etc/containers/registries.conf` and search for `[registries.insecure]` and then add the output of `echo $OS_REGISTRY` there.

### Add a project

As a non-admin user, in order to add our images to the registry, the images have to be in a project/namespace. As a result, we need to create a project. During this step we will briefly introduce `oc` (the Openshift Client). We will be exploring `oc` in much more depth in the next lab. 

```bash
$ oc login -u $OS_USER -p $OS_PASS $OS_API
$ oc new-project container-lab
```

### Tag images for registry

First, we have to tag the images we want to push with the place they will end up.

```bash
$ sudo podman images
$ sudo podman tag localhost/mariadb $OS_REGISTRY/container-lab/mariadb
$ sudo podman tag localhost/wordpress $OS_REGISTRY/container-lab/wordpress
```

### Login to the registry

In order to push to the registry, we need login to the registry with `podman`. However, this can be a little confusing as we can't login with our normal password but, instead, must use an OpenShift generated token. `oc whoami -t` will give us the token we need, assuming we are logged in with oc.

Push the images
```bash
$ sudo podman login --tls-verify=false \
  -u $OS_USER \
  -p $(oc whoami -t) \
  $OS_REGISTRY
```

### Push images to registry

Push the images:

```bash
$ sudo podman images
$ sudo podman push --tls-verify=false $OS_REGISTRY/container-lab/mariadb
$ sudo podman push --tls-verify=false $OS_REGISTRY/container-lab/wordpress
```

## Clean Up

Let's clean up the containers we had running. 

```bash
$ sudo podman rm -f mariadb wordpress
$ sudo podman ps -a
```

In the [next lab](../lab4/chapter4.md) we introduce container orchestration via OpenShift.
