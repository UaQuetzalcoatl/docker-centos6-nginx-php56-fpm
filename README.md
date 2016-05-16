This repository contains source code for building a base docker image for nginx php5.6-fpm stack
===============================
* Build a ssh base image or pull it from the dockerhub. There is a repository with the source code `http://github.private.linksynergy.com/jayesh-sheth/docker-centos6-ssh-base`
* Clone the repo:
```sh
git clone git@github.private.linksynergy.com:alexey-savchenko/docker-centos6-nginx-php5.6-fpm.git
cd docker-centos6-nginx-php5.6-fpm
```

* Build the docker image
```sh
docker build -t centos6-nginx-php56-fpm-base .
```
