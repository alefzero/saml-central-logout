#!/bin/bash
# Created by Alexandre Marcelo (@xandecelo), jun-2023
# More information at https://github.com/xandecelo/saml-central-logout

printf "\n\n\n"
date
printf "Iniciando imagem do Apache - saml logout central.\n\n"
printf "<p class="error">" >${HOME_DIR}/warning_message_file

# Set document root depending of configuration
DOCUMENT_ROOT="/var/www/html"
SERVICE_FILE="000-service"
SAML_FILES_FOLDER="/etc/apache2/saml2"
CONFIG_MODE_RESULT=RUN

pushd() {
    command pushd "$@" >/dev/null
}

popd() {
    command popd "$@" >/dev/null
}
warning() {
    msg=$1
    echo
    echo "$msg" >>${HOME_DIR}/warning_message_file
    echo "$msg"
}

setVariables() {
    sed -i -e "s|%%ALLOWED_REDIRECT_DOMAINS%%|${ALLOWED_REDIRECT_DOMAINS}|g" "/etc/apache2/sites-available/000-service.conf"
    sed -i -e "s|%%DOCUMENT_ROOT%%|${DOCUMENT_ROOT}|g" "/etc/apache2/sites-available/000-service.conf"
    sed -i -e "s|%%SERVICE_HOSTNAME%%|${SERVICE_HOSTNAME}|g" "/etc/apache2/sites-available/000-service.conf"

    sed -i -e "s|%%DOCUMENT_ROOT%%|${DOCUMENT_ROOT}|g" "/etc/apache2/sites-available/000-service_config.conf"
    sed -i -e "s|%%SERVICE_HOSTNAME%%|${SERVICE_HOSTNAME}|g" "/etc/apache2/sites-available/000-service_config.conf"

    find /var/www  -name "*.html" -exec sed -i -e "s|%%SERVICE_HOSTNAME%%|${SERVICE_HOSTNAME}|g" {} \;
    find /var/www  -name "*.html" -exec sed -i -e "s|%%DEFAULT_LOGOUT_DESTINATION_URL%%|${DEFAULT_LOGOUT_DESTINATION_URL}|g" {} \;
    find /var/www/html_config -name "*.html" -exec sed -i -e "s|%%IDP_METADATA_SAML_XML_URL%%|${IDP_METADATA_SAML_XML_URL}|g" {} \;
    find /var/www/html_config -name "*.html" -exec sed -i -e "s|%%SSL_CERT_FILE%%|${SSL_CERT_FILE}|g" {} \;
    find /var/www/html_config -name "*.html" -exec sed -i -e "s|%%SSL_CERT_PRIVATE_KEY%%|${SSL_CERT_PRIVATE_KEY}|g" {} \;
    find /var/www/html_config -name "*.html" -exec sed -i -e "s|%%SSL_CERT_FULL_CHAIN%%|${SSL_CERT_FULL_CHAIN}|g" {} \;
    find /var/www/html_config -name "*.html" -exec sed -i -e "s|%%ALLOWED_REDIRECT_DOMAINS%%|${ALLOWED_REDIRECT_DOMAINS}|g" {} \;
    printf "</p>" >>warning_message_file
    find /var/www/html_config -name "*.html" -exec sed -i -e '/%%WARNING_MESSAGE%%/{ r warning_message_file' -e 'd}' {} \;
}

setupIDPConfig() {
    if [ "$IDP_METADATA_SAML_XML_URL" == "" ]; then
        warning "Variável obrigatória IDP_METADATA_SAML_XML_URL não foi configurada."
    else
        EXTRA_OPTS=""
        if [ "${IGNORE_IDP_SSL_CERTS^^}" == "YES" ]; then
            EXTRA_OPTS=" -k "
        fi

        if curl_output=$(curl --fail $EXTRA_OPTS $IDP_METADATA_SAML_XML_URL -o "${SAML_FILES_FOLDER}/idp_metadata.xml" 2>&1); then
            if [ "${CONFIG_MODE_RESULT}" == "SETUP" ]; then
                pushd ${SAML_FILES_FOLDER}
                mellon_create_metadata saml-central-logout "https://${SERVICE_HOSTNAME}/mellon/"
                cp saml-central-logout.cert /var/www/html_config
                cp saml-central-logout.key /var/www/html_config
                cp saml-central-logout.xml /var/www/html_config/saml-central-logout.xml
                chmod +r /var/www/html_config/*
                popd
            elif [ "${CONFIG_MODE_RESULT}" == "RUN" ]; then
                cp ${SAML_CERT_FILE} "${SAML_FILES_FOLDER}/saml-central-logout.cert"
                cp ${SAML_CERT_PRIVATE_KEY} "${SAML_FILES_FOLDER}/saml-central-logout.key"
                cp ${SAML_SP_METADATA_FILE} "${SAML_FILES_FOLDER}/saml-central-logout.xml"
            else
                warning "Esta imagem não foi configurada. Use CONFIG_MODE=YES ou ajuste demais variáveis."
            fi

        else
            warning "Não foi possível obter o arquivo de configuração SAML do IDP. Verifique a URL em IDP_METADATA_SAML_XML_URL."
        fi

    fi
}

setConfigModeResult() {
    if [ -n "${CONFIG_MODE}" ] && [ "${CONFIG_MODE^^}" == "YES" ]; then
        CONFIG_MODE_RESULT=SETUP
        DOCUMENT_ROOT="${DOCUMENT_ROOT}_config"
        SERVICE_FILE="${SERVICE_FILE}_config"
    elif [ ! -f "${SAML_SP_METADATA_FILE}" ]; then
        CONFIG_MODE_RESULT=FIRST
        DOCUMENT_ROOT="${DOCUMENT_ROOT}_1st_setup"
        SERVICE_FILE="${SERVICE_FILE}_config"
    fi
}

setupSSLCertificates() {
    test -n "$SSL_CERT_FILE" && cp "$SSL_CERT_FILE" /etc/apache2/certs/cert1.pem
    test -n "$SSL_CERT_PRIVATE_KEY" && cp "$SSL_CERT_PRIVATE_KEY" /etc/apache2/certs/privkey1.pem
    if [ -n "$SSL_CERT_FULL_CHAIN" ]; then
        cp "$SSL_CERT_FULL_CHAIN" /etc/apache2/certs/fullchain1.pem
    else
        sed -i -e 's|^[^#]*SSLCertificateChainFile /etc/apache2/certs/fullchain1.pem|#&|' "/etc/apache2/sites-available/000-service.conf"
        sed -i -e 's|^[^#]*SSLCertificateChainFile /etc/apache2/certs/fullchain1.pem|#&|' "/etc/apache2/sites-available/000-service_config.conf"
    fi
}

copyCommonFiles() {
    find /var/www/ -type d -name "html*" -exec cp -R /var/www/common/* {} \;
}

setConfigModeResult
setupIDPConfig
setVariables
a2ensite $SERVICE_FILE >/dev/null
setupSSLCertificates
copyCommonFiles

# Run Apache HTTPD server at foreground
printf "\n\nExecutando o Apache em modo ${CONFIG_MODE_RESULT}\n"
apachectl -D FOREGROUND
