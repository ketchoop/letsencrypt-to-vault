#!/bin/bash

process_args() {
    # Default
    VAULT_TOKEN="$VAULT_TOKEN"
    VAULT_ADDR="$VAULT_ADDR"
    VAULT_CERT_PATH="certs"
    COMMAND=$1

    if [[ "$COMMAND" == "certonly" || "$COMMAND" == "renew" ]]; then
        echo ""
    else
        echo "letsencrypt-to-vault: Wrong command"
        echo
        show_help
        exit 1
    fi

    shift

    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
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
    echo
}

send_to_vault() { 
    local certs_dir="/etc/letsencrypt/live"

    for sitename in $(find $certs_dir -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)
    do
        local cert=$(cat $certs_dir/$sitename/fullchain.pem)
        local privkey=$(cat $certs_dir/$sitename/privkey.pem)

        curl \
            -H "X-Vault-Token: $VAULT_TOKEN" \
            -H "Content-Type: application/json" \
            -X POST \
            -d "{\"key\":\"$privkey\", \"cert\": \"$cert\"}" \
            "http://$VAULT_ADDR/v1/secret/$VAULT_CERT_PATH/$sitename"
    done
}

main() {
    process_args $@
    cert_renew
    send_to_vault
}

main $@
