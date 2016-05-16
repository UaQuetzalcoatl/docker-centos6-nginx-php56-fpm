FROM centos6-ssh-base:latest
# todo create a base image nginx_php7-fpm
ENV PHP_VERSION 7.0.5
ENV PHP_INI_DIR /usr/local/php

# update & install dependencies
RUN yum update -y \
	&& yum install -y \
		tar \
		gzip \
		autoconf \
		file \
		gcc \
		gcc-c++ \
		libc-devel \
		make \
		libtool \
		flex \
		bison \
		zlib \
		zlib-devel \
		pcre \
		pcre-devel \
		libedit-devel \
		libxml2 \
		libxml2-devel \
		libaio \
		ca-certificates \
		libicu-devel \
		epel-release \
		wget \
		curl \
		mongodb \
		rsyslog \
		openssl-devel \
		libgearman \
		uuid \
		libevent \
		git

RUN yum update -y && yum install -y libmcrypt libmcrypt-devel

RUN mkdir -p /tmp/source

# download libs
RUN curl -fSL "http://php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror" -o "/tmp/source/php-$PHP_VERSION.tar.gz"
RUN curl -fSL "https://github.com/skvadrik/re2c/releases/download/0.16/re2c-0.16.tar.gz" -o "/tmp/source/re2c-0.16.tar.gz"
RUN curl -fSL "http://nginx.org/download/nginx-1.10.0.tar.gz" -o "/tmp/source/nginx-1.10.0.tar.gz"
RUN curl -fSL https://s3.amazonaws.com/rm-rant-rpm/oci8/oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm -o /tmp/oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
RUN curl -fSL https://s3.amazonaws.com/rm-rant-rpm/oci8/oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm -o /tmp/oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm

#install instant client
RUN rpm -ivh /tmp/oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
RUN rpm -ivh /tmp/oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
#RUN rm -Rf /tmp/oracle*

# install re2c
RUN cd /tmp/source \
	&& tar -xzf re2c-0.16.tar.gz \
	&& cd re2c-0.16 \ 
	&& ./configure \ 
	&& make \ 
	&& make install \
	&& make clean

#install nginx
RUN set -xe \
	&& cd /tmp/source \
 	&& tar -xzf nginx-1.10.0.tar.gz \
 	&& cd nginx-1.10.0 \
 	&& ./configure \
 		--prefix="/usr/local/nginx" \
 		--conf-path="/usr/local/nginx/conf/nginx.conf" \
 		--error-log-path="/var/log/nginx/error.log" \
 		--http-log-path="/var/log/nginx/access.log" \
 		--user="web" \
 		--group="web" \
 		--with-debug \
	&& make \
	&& make install \
	&& make clean

#install php
RUN set -xe \
	&& cd /tmp/source \
 	&& tar -xzf php-$PHP_VERSION.tar.gz \
 	&& cd php-$PHP_VERSION \
 	&& ./configure \
 		--prefix="/usr/local/php" \
 		--enable-fpm \
 		--with-fpm-user="web" \
 		--with-fpm-group="web" \
 		--with-config-file-path=$PHP_INI_DIR \
 		--enable-cli \
 		--enable-mbstring \
 		--enable-intl \
 		--enable-bcmath \
 		--with-mcrypt \
		--with-pdo-mysql \
		--enable-opcache \
		--with-pear \
		--with-openssl \
		--with-oci8=shared,instantclient,/usr/lib/oracle/11.2/client64/lib \
	&& make \
	&& make install \
	&& make clean \
	&& cp php.ini-production $PHP_INI_DIR/php.ini \
	&& mkdir -p $PHP_INI_DIR/shared \
	&& cp php.ini-production $PHP_INI_DIR/shared/php.ini-production \
	&& cp php.ini-development $PHP_INI_DIR/shared/php.ini-development \
	&& cd /usr/local/php/etc \
	&& cp php-fpm.conf.default php-fpm.conf \
	&& echo "daemonize = no" >> php-fpm.conf \
	&& cd /usr/local/php/etc/php-fpm.d \
	&& cp www.conf.default www.conf \
	&& sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" $PHP_INI_DIR/php.ini \
	&& sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" $PHP_INI_DIR/shared/php.ini-production \
	&& sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" $PHP_INI_DIR/shared/php.ini-development \
	&& cd /

	#&& rm -Rf /tmp/source

# todo fix this. it's invalid path
# && sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null \
# 

ENV PATH=$PATH:/usr/local/php/bin:/usr/local/nginx/sbin

#install phpunit
RUN set -xe \
    && cd /tmp && wget https://phar.phpunit.de/phpunit.phar \
    && chmod +x phpunit.phar \
    && mv phpunit.phar /usr/local/bin/phpunit


#enable opcache
RUN set -xe \
	&& echo opcache.enable=1 | tee -a $PHP_INI_DIR/php.ini $PHP_INI_DIR/shared/php.ini-production $PHP_INI_DIR/shared/php.ini-development \
	&& echo opcache.enable_cli=1 | tee -a $PHP_INI_DIR/php.ini $PHP_INI_DIR/shared/php.ini-production $PHP_INI_DIR/shared/php.ini-development \
	&& echo opcache.memory_consumption=128 | tee -a $PHP_INI_DIR/php.ini $PHP_INI_DIR/shared/php.ini-production $PHP_INI_DIR/shared/php.ini-development \
	&& echo opcache.interned_strings_buffer=8 | tee -a $PHP_INI_DIR/php.ini $PHP_INI_DIR/shared/php.ini-production $PHP_INI_DIR/shared/php.ini-development \
	&& echo opcache.max_accelerated_files=4000 | tee -a $PHP_INI_DIR/php.ini $PHP_INI_DIR/shared/php.ini-production $PHP_INI_DIR/shared/php.ini-development \
	&& echo opcache.revalidate_freq=60 | tee -a $PHP_INI_DIR/php.ini $PHP_INI_DIR/shared/php.ini-production $PHP_INI_DIR/shared/php.ini-development \
	&& echo opcache.fast_shutdown=1 | tee -a $PHP_INI_DIR/php.ini $PHP_INI_DIR/shared/php.ini-production $PHP_INI_DIR/shared/php.ini-development

#
#     yum -y install php-pear; causes installing php5
#

RUN curl -fSL https://launchpad.net/gearmand/1.2/1.1.12/+download/gearmand-1.1.12.tar.gz -o /tmp/gearmand-1.1.12.tar.gz
RUN yum install -y boost boost-devel gperf libevent-devel libuuid libuuid-devel
RUN cd tmp && tar -xzf gearmand-1.1.12.tar.gz \
 	&& cd gearmand-1.1.12 \
 	&& ./configure && make && make install && make clean

# install gearman
ENV GEARMAN_LIB_DIR=/usr/lib64
ENV GEARMAN_INC_DIR=/usr/lib64


RUN cd /tmp  \
	&& git clone https://github.com/wcgallego/pecl-gearman.git \
	&& cd pecl-gearman \
	&& phpize --with-php-config=/usr/local/php/bin/php-config \
	&& ./configure --with-php-config=/usr/local/php/bin/php-config \
	&& make && make install && make clean

# install pecl extensions
RUN set -ex;\
    pecl channel-update pecl.php.net;\
    yes "" | pecl install -f mongodb-1.1.6;\
    yes "" | pecl install -f gearman-1.1.2;\
    yes "" | pecl install -f apcu;\
    echo extension=mongodb.so | tee -a $PHP_INI_DIR/php.ini $PHP_INI_DIR/shared/php.ini-production $PHP_INI_DIR/shared/php.ini-development; \
    echo extension=gearman.so | tee -a $PHP_INI_DIR/php.ini $PHP_INI_DIR/shared/php.ini-production $PHP_INI_DIR/shared/php.ini-development; \
    echo extension=apcu.so | tee -a $PHP_INI_DIR/php.ini $PHP_INI_DIR/shared/php.ini-production $PHP_INI_DIR/shared/php.ini-development; \
    echo extension=oci8.so | tee -a $PHP_INI_DIR/php.ini $PHP_INI_DIR/shared/php.ini-production $PHP_INI_DIR/shared/php.ini-development; \
    cp $PHP_INI_DIR/php.ini $PHP_INI_DIR/php-cli.ini


RUN set -x; \
	chown web:web /var/spool/cron/web; \
	chmod 644 /var/spool/cron/web; \
	yum install -y cronie; \
	touch /var/log/cron

# there is an issue with running cron in the container
RUN sed -i '/session\s*required\s*pam_loginuid.so/d' /etc/pam.d/crond

ENV PATH=$PATH:/usr/local/php/bin
EXPOSE 80
# ENTRYPOINT ["entrypoint.sh"]
# CMD ["start"]

RUN echo "while true; do sleep 1000; done" >> /tmp/start.sh
RUN chmod +x /tmp/start.sh

CMD ["/bin/bash", "/tmp/start.sh"]