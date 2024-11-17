FROM ubuntu:latest

ENV AD_DOMAIN=EXAMPLE
ENV AD_REALM=EXAMPLE.LOCAL
# Administrator password does not meet the default minimum
# password length requirement (7 characters)
ENV AD_ADMIN_PASSWORD=Passw0rd

RUN apt update -q && \
    apt install locales && \
    locale-gen pl_PL.UTF-8 && \
    dpkg-reconfigure locales

# Installation
# This command will install the packages necessary for bootstrapping
# and testing the Samba AD/DC services:
RUN apt install -y samba-ad-dc \
    krb5-user \
    bind9-dnsutils \
	vim-nox \
	net-tools
	
# The Samba AD/DC provisioning tool will want to create a new Samba 
# configuration file, dedicated to the AD/DC role, but it will 
# refrain from replacing an existing one.	
RUN apt clean && \
	rm -fr /var/lib/apt/lists/* \
    mv /etc/samba/smb.conf /etc/samba/smb.conf.orig

# Prepare required folders...
# Workdir:
RUN mkdir -p /opt/service && mkdir -p /opt/init 
	
# cp -r service/* /opt/service/
COPY service/* /opt/service
COPY init/* /opt/init

RUN rm -rf /tmp/* \
 && rm -rf /var/tmp/* \
 && chmod a+x /opt/service/startServer.sh

VOLUME ["/etc/samba", "/var/log/samba", "/var/lib/samba"]
# https://www.encryptionconsulting.com/ports-required-for-active-directory-and-pki/
EXPOSE 42 53 53/udp 88 88/udp 135 137-138/udp 139 389 389/udp 445 464 464/udp 636 3268-3269 49152-65535
WORKDIR /opt/service
CMD ["/bin/sh", "-c", "/opt/service/startServer.sh"]

