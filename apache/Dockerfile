FROM php:7.0-apache
MAINTAINER Michael Babker <michael.babker@mautic.org> (@mbabker)

# Install PHP extensions
RUN apt-get update && apt-get install --no-install-recommends -y \
    cron \
    libc-client-dev \
    libicu-dev \
    libkrb5-dev \
    libmcrypt-dev \
    libssl-dev \
    libzip-dev \
    unzip \
    zip \
    && rm /etc/cron.daily/*
RUN docker-php-ext-configure imap --with-imap --with-imap-ssl --with-kerberos \
    && docker-php-ext-install imap intl mbstring mcrypt mysqli pdo pdo_mysql zip

VOLUME /var/www/html

# Define Mautic version and expected SHA1 signature
ENV MAUTIC_VERSION 2.9.2
ENV MAUTIC_SHA1 2cdd26822bd4b37f95238bfd21caabe6051a3411

ENV MAUTIC_RUN_CRON_JOBS true
ENV MAUTIC_DB_USER root
ENV MAUTIC_DB_NAME mautic

# Download package and extract to web volume
RUN curl -o mautic.zip -SL https://s3.amazonaws.com/mautic/releases/${MAUTIC_VERSION}.zip \
	&& echo "$MAUTIC_SHA1 *mautic.zip" | sha1sum -c - \
	&& mkdir /usr/src/mautic \
	&& unzip mautic.zip -d /usr/src/mautic \
	&& rm mautic.zip \
	&& chown -R www-data:www-data /usr/src/mautic

# Copy init scripts and custom .htaccess
COPY docker-entrypoint.sh /entrypoint.sh
COPY makeconfig.php /makeconfig.php
COPY makedb.php /makedb.php
COPY mautic.crontab /etc/cron.d/mautic
COPY mautic-php.ini /usr/local/etc/php/conf.d/mautic-php.ini

# Enable opcache in php
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/mautic-php.ini
RUN echo "zend_extension=opcache.so" >> /usr/local/etc/php/conf.d/mautic-php.ini

# Enable Apache Rewrite Module
RUN a2enmod rewrite

RUN sed -i 's/^\s*session\s\+required\s\+pam_loginuid.so/# &/' /etc/pam.d/cron

# limit apache to 1 worker
RUN sed -ri ' \
		s/(StartServers)\s*[0-9]*/\1 1/; \
		s/(MinSpareServers)\s*[0-9]*/\1 1/; \
		s/(MaxSpareServers)\s*[0-9]*/\1 1/; \
		s/(MaxRequestsPerChild)\s*[0-9]*/\1 1/; \
	' /etc/apache2/mods-enabled/mpm_prefork.conf

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
