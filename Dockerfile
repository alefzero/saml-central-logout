FROM ubuntu:20.04

ENV HOME_DIR=/opt/saml-central-logout
# Image configuration
RUN apt-get update
RUN ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata apt-utils
RUN apt-get -y install apache2 libapache2-mod-auth-mellon curl
RUN a2enmod ssl auth_mellon proxy proxy_http proxy_http2 headers rewrite
RUN a2dismod status 
RUN a2dissite 000-default

# httpd-saml2-sp configuration
RUN mkdir -p ${HOME_DIR} /etc/apache2/saml2 /etc/apache2/certs

COPY conf/    /etc/apache2/
COPY www/     /var/www/
COPY scripts/ ${HOME_DIR} 

RUN chmod +x  ${HOME_DIR}/*.sh

# default environmet variables values
ENV SERVICE_HOSTNAME=example.com
ENV SSL_CERT_FILE=/etc/ssl/certs/ssl-cert-snakeoil.pem
ENV SSL_CERT_PRIVATE_KEY=/etc/ssl/private/ssl-cert-snakeoil.key
ENV SSL_CERT_FULL_CHAIN=""
ENV IDP_METADATA_SAML_XML_URL=""
ENV CONFIG_MODE=NO
ENV ALLOWED_REDIRECT_DOMAINS=""
ENV DEFAULT_LOGOUT_DESTINATION_URL=/done.html

WORKDIR ${HOME_DIR}

EXPOSE 80
EXPOSE 443

ENTRYPOINT [ "/bin/bash", "-c" ]
CMD [ "${HOME_DIR}/run.sh" ]
