#!/bin/bash
set -eo pipefail

process_args() {
    # Default
    VAULT_CERT_PATH="certs"
    CERTBOT_FLAGS="--webroot --webroot-path /tmp --agree-tos --renew-by-default"

    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
            certonly|renew)
            COMMAND="$1"
            shift
            ;;
            -h|--help)
            show_help
            exit 0
            ;;
            -t|--vault-token)
            VAULT_TOKEN="$2"
            shift
            ;;
            -a|--vault-addr)
            VAULT_ADDR="$2"
            shift
            ;;
            -p|--vault-cert-path)
            VAULT_CERT_PATH="$2"
            shift
            ;;
            -f|--certbot-flags)
            CERTBOT_FLAGS="$2"
            shift
            ;;
            -*|--*)
            echo "letsencrypt-to-vault: unknown flag: $2"
            show_help
            exit 1
            ;;
            *)
            if [[ "$COMMAND" == "certonly" ]]; then
                DOMAINS=$@
            fi
            return
        esac
    done
}

show_help() {
    echo "Let's encrypt to Hashicorp Vault"
    echo
    echo "Renew or get Let's Encrypt certificates and send it to Hashicorp Vault" 
    echo
    echo "Usage:"
    echo "  letsencrypt-to-vault command [-flags] [sitesnames]"
    echo ""
}

cert_renew() {
    echo "Trying to get or renew certificates..."
    certbot $COMMAND $CERTBOT_FLAGS $DOMAINS
    echo "Certificates were renewed"
}

send_to_vault() { 
    local certs_dir="/etc/letsencrypt/live"

    echo "Sending certs to vault..."
    echo

    if [[ $COMMAND == "certonly" ]]; then
        local sitesnames="$DOMAINS"
    else
        local sitesnames=$(find $certs_dir -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)
    fi

    for sitename in $sitesnames
    do
        local cert=$(cat $certs_dir/$sitename/fullchain.pem | tr -d "\n")
        local privkey=$(cat $certs_dir/$sitename/privkey.pem | tr -d "\n")

        curl \
            -H "X-Vault-Token: $VAULT_TOKEN" \
            -H "Content-Type: application/json" \
            -X POST \
            -d "{\"key\":\"$privkey\", \"cert\": \"$cert\"}" \
            "$VAULT_ADDR/v1/secret/$VAULT_CERT_PATH/$sitename"
    done

    echo "Done. Certificates were sent"
}

main() {
    process_args $@
    cert_renew
    send_to_vault
}

main $@
