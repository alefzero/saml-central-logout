# Saml Central Logout

Ambiente Apache HTTPD que provê e centraliza o logout de aplicações para um domínio/realm
de um IDP via SAML2.0.

Para utilizar essa imagem, basta iniciá-la alterando as configurações para CONFIG_MODE=YES. Ao acessar a página inicial deste ambiente, serão dadas as instruções de configuração.

## Realizando o logout

Para realizar o logout após a configuração, basta fazer um redirect para utilizar:

```https://SERVICE_HOSTNAME/mellon/logout?ReturnTo=URL_A_RETORNAR_APOS_LOGOUT```

Caso queira realizar um logout para a URL padrãoo, basta acessar:

```https://SERVICE_HOSTNAME/```

## Configuração da imagem

Parâmetro | Tipo |Ação | Valor padrão
--- | --- | --- | --- |
CONFIG_MODE|Obrigatório| Indica se a imagem será iniciada em modo de configuração de IDP | NO
SERVICE_HOSTNAME|Obrigatório | Hostname a ser usado nesse host. São exemplos de formatos válidos: ```example.com``` e ```example.com:8443``` | example.com
IDP_METADATA_SAML_XML_URL| Obrigatório| URL com protocoto onde está disponível o XML de configuração do IDP a ser utilizado para download de configuração |
IGNORE_IDP_SSL_CERTS| Opcional | Ignora o certificado de SSL quanto está fazendo o download do arquivo de metadata do IDP | NO
SSL_CERT_FILE|Obrigatório | Arquivo de certificado de SSL para o hostname | auto-assinado
SSL_CERT_PRIVATE_KEY| Obrigatório |Chave privada do certificado de SSL para o hostname| auto-assinado
SSL_CERT_FULL_CHAIN| Opcional| Cadeia de certificado para o servidor HTTP| auto-assinado
ALLOWED_REDIRECT_DOMAINS|Opcional | lista de domínios no qual o serão permitidos redirects após o logout
DEFAULT_LOGOUT_DESTINATION_URL| Opcional| URL padrão para onde o logout será encaminhado caso se acesse a página de logout sem indicação de redirect final | /done.html
SAML_CERT_FILE | Obrigatório em CONFIG_MODE=NO| Arquivo de certificado SAML a ser utilizado
SAML_CERT_PRIVATE_KEY | Obrigatório em CONFIG_MODE=NO | Arquivo de chave privada do certificado SAML a ser utilizado
SAML_SP_METADATA_FILE | Obrigatório em CONFIG_MODE=NO | Arquivo de metadados SAML (service provider file) da aplicação cadastrada no IDP
