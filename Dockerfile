# Use Ubuntu 20.04 as the base image
FROM ubuntu:20.04

# Set environment variables to automate package installations without interaction and set time zone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Ho_Chi_Minh

# Update and install necessary packages in one RUN layer to minimize image size
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y apt-utils && \
    apt-get install -y apache2 mariadb-server php php-mysqli php-gd libapache2-mod-php nano apt-transport-https gnupg2 && \
    apt-get install -y g++ flex bison curl apache2-dev doxygen libyajl-dev ssdeep liblua5.2-dev libgeoip-dev libtool dh-autoreconf && \
    apt-get install -y libcurl4-gnutls-dev libxml2 libpcre++-dev libxml2-dev git wget tar autoconf automake pkg-config && \
    apt-get -f install && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add Elasticsearch GPG key and repository, then install Filebeat and Packetbeat
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list && \
    apt-get update && \
    apt-get install -y filebeat packetbeat libpcap0.8

# Download LibModsecurity 
#RUN git clone https://github.com/owasp-modsecurity/ModSecurity.git

# Download and build LibModsecurity
RUN git clone https://github.com/owasp-modsecurity/ModSecurity.git && \
    cd ModSecurity && \
    git submodule init && \
    git submodule update --recursive && \
    chmod +x build.sh && ./build.sh && ./configure && \
    make && make install

# Install ModSecurity-Apache Connector
#RUN git clone https://github.com/SpiderLabs/ModSecurity-apache

# Install ModSecurity-Apache Connector
RUN git clone https://github.com/SpiderLabs/ModSecurity-apache && \
    cd ModSecurity-apache && \
    chmod +x autogen.sh && ./autogen.sh && \
    ./configure --with-libmodsecurity=/usr/local/modsecurity/ && \
    make && make install
    
# Load the Apache ModSecurity Connector Module
RUN echo "LoadModule security3_module /usr/lib/apache2/modules/mod_security3.so" >> /etc/apache2/apache2.conf


#Configure ModSecurity
RUN mkdir /etc/apache2/modsecurity.d && \
    cp ModSecurity/modsecurity.conf-recommended /etc/apache2/modsecurity.d/modsecurity.conf && \
    cp ModSecurity/unicode.mapping /etc/apache2/modsecurity.d/ && \
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/apache2/modsecurity.d/modsecurity.conf
ADD ./confModsecurity/modsec_rules.conf /etc/apache2/modsecurity.d/

# Install OWASP ModSecurity Core Rule Set (CRS) on Ubuntu
RUN git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /etc/apache2/modsecurity.d/owasp-crs && \
   cp /etc/apache2/modsecurity.d/owasp-crs/crs-setup.conf.example /etc/apache2/modsecurity.d/owasp-crs/crs-setup.conf

# Activate ModSecurity
RUN mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.old
ADD ./confModsecurity/000-default.conf /etc/apache2/sites-available/


# Copy the SQL initialization script and website files
COPY ./initWebTD.sql /docker-entrypoint-initdb.d/

COPY ./src/WEB/ /var/www/html/

# RUN cd /var/www/html && git clone https://github.com/digininja/DVWA.git .

RUN rm -rf /var/www/html/index.html

RUN chown -R www-data:www-data /var/www/html/*


# Copy additional configuration and startup script
COPY ./src/ca/ca.crt /etc/filebeat/
COPY ./src/ca/ca.crt /etc/packetbeat/
COPY ./startupCMDdocker.sh /startupCMDdocker.sh
RUN chmod +x /startupCMDdocker.sh

# Expose necessary ports
EXPOSE 80 3310

# Set working directory
WORKDIR /var/www/html/


# Start services using the startup script
CMD ["/startupCMDdocker.sh"]
