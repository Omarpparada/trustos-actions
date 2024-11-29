#!/bin/bash

# Verificar si se proporcionaron los parámetros necesarios
if [ $# -ne 4 ]; then
    echo "Uso: $0 <username> <password> <github_user> <github_commit>"
    echo "Ejemplo: $0 'did:user:example123' 'mypassword' 'johndoe' 'abc123'"
    exit 1
fi

# Configuración
LOGIN_URL="https://lab.trustos.telefonicatech.com/id/v2/login"
CERT_URL="https://lab.trustos.telefonicatech.com/cert/v2/certificates?networkId=10004"

# Capturar parámetros
USERNAME="$1"
PASSWORD="$2"
GITHUB_USER="$3"
GITHUB_COMMIT="$4"

# Realizar login y mostrar la respuesta para debug
echo "Realizando login..."
LOGIN_RESPONSE=$(curl -s \
    -X POST \
    -H "accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}" \
    "$LOGIN_URL")

echo "Respuesta del login:"
echo "$LOGIN_RESPONSE" | jq '.'

# Extraer el token usando jq
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.token')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "Error: No se pudo obtener el token"
    echo "Código de estado: $(echo "$LOGIN_RESPONSE" | jq -r '.statusCode')"
    echo "Mensaje: $(echo "$LOGIN_RESPONSE" | jq -r '.message')"
    exit 1
fi

echo "Token obtenido correctamente" 

# Crear certificado
echo "Creando certificado..."
CERT_RESPONSE=$(curl -s \
    -X POST \
    "$CERT_URL" \
    -H "accept: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"Github Code Certificate\",
        \"description\": \"Github code certificate description\",
        \"content\": {
            \"user\": \"$GITHUB_USER\",
            \"commit\": \"$GITHUB_COMMIT\"
        }
    }")

# Extraer y mostrar el certID
CERT_ID=$(echo "$CERT_RESPONSE" | jq -r '.data.certID')

if [ -z "$CERT_ID" ] || [ "$CERT_ID" == "null" ]; then
    echo "Error: No se pudo obtener el certID"
    echo "Respuesta completa del certificado:"
    echo "$CERT_RESPONSE" | jq '.'
    exit 1
fi

echo "Certificado creado exitosamente"
echo "CertID: $CERT_ID"
