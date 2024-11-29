#!/bin/bash

# Verificar si se proporcionaron los parámetros necesarios
if [ $# -ne 8 ]; then
    echo "Uso: $0 <login_url> <cert_url> <username> <password> <secret> <github_user> <github_commit> <github_repo>"
    echo "Ejemplo: $0 'https://trustos-id.com' 'https://trustos-cert.com' 'did:user:example123' 'mypassword' 'your-secret-key' 'johndoe' 'abc123' 'owner/repo'"
    exit 1
fi

# Configuración
LOGIN_URL="$1"
CERT_URL="$2"

# Capturar parámetros
USERNAME="$3"
PASSWORD="$4"
SECRET_KEY="$5"
GITHUB_USER="$6"
GITHUB_COMMIT="$7"
GITHUB_REPO="$8"

# Función para generar JWT
generate_jwt() {
    # Crear header
    HEADER='{
        "alg": "HS256",
        "typ": "JWT"
    }'
    # Crear payload con timestamp actual + 10 minutos
    PAYLOAD='{
        "iss": "lab-external-jwt",
        "exp": '"$(($(date +%s) + 600))"'
    }'

    # Codificar Header y Payload en base64url
    HEADER_BASE64=$(echo -n "$HEADER" | jq -c | base64 | tr -d '=' | tr '+/' '-_')
    PAYLOAD_BASE64=$(echo -n "$PAYLOAD" | jq -c | base64 | tr -d '=' | tr '+/' '-_')

    # Crear firma
    SIGNATURE=$(echo -n "${HEADER_BASE64}.${PAYLOAD_BASE64}" | \
        openssl dgst -binary -sha256 -hmac "$SECRET_KEY" | \
        base64 | tr -d '=' | tr '+/' '-_')

    # Concatenar todo para formar el JWT
    JWT="${HEADER_BASE64}.${PAYLOAD_BASE64}.${SIGNATURE}"
    echo "$JWT"
}

# Generar JWT
GITHUB_JWT=$(generate_jwt)

# Realizar login y mostrar la respuesta para debug
echo "Realizando login..."
LOGIN_RESPONSE=$(curl -s \
    -X POST \
    -H "accept: application/json" \
    -H "trustosAuth: Bearer ${GITHUB_JWT}" \
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
    -H "trustosAuth: Bearer ${GITHUB_JWT}" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"Github Code Certificate\",
        \"description\": \"GitHub code certificate description\",
        \"content\": {
            \"repo\": \"$GITHUB_REPO\",
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
