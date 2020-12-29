#!/bin/bash
# shellcheck shell=bash
# Exit immediately if a command exists with a non-zero status.
set -e

# Show CLI help information.
#
# Cannot use function name help, since help is a pre-existing command.
usage() {
    case "$1" in
        apply)
            cat 1>&2 <<EOF
manage.sh apply
Provision cloud resources with Terraform

USAGE:
    manage.sh apply [FLAGS]
FLAGS:
    -h, --help       Print help information
EOF
            ;;
        connect)
            cat 1>&2 <<EOF
manage.sh connect
Provision and connect to cloud resources

USAGE:
    manage.sh connect [FLAGS] [OPTIONS]
FLAGS:
    -h, --help       Print help information
EOF
            ;;
        destroy)
            cat 1>&2 <<EOF
manage.sh destroy
Remove cloud resources with Terraform

USAGE:
    manage.sh destroy [FLAGS] [OPTIONS]
FLAGS:
    -h, --help       Print help information
EOF
            ;;
        main)
            cat 1>&2 <<EOF
$(version)
Manage cloud resources with Terraform

USAGE:
    manage [FLAGS] [SUBCOMMAND]
FLAGS:
    -h, --help       Print help information
    -v, --version    Print version information
SUBCOMMANDS:
    apply            Provision cloud resources with Terraform
    destroy          Remove cloud resources with Terraform
EOF
            ;;
    esac
}

# Provision cloud resources with Terraform.
apply() {
    local _private_key

    generate_keys
    _private_key="$RET_VAL"

    terraform init > /dev/null
    terraform apply -auto-approve -var="private_key=$_private_key"
}

# Assert that command can be found on machine.
assert_cmd() {
    if ! check_cmd "$1" ; then
        error "Cannot find $1 command on computer."
    fi
}

# Check if command can be found on machine.
check_cmd() {
    command -v "$1" > /dev/null 2>&1
}

# Provision and connect to cloud resources.
connect() {
    apply "$@"
    eval "$(terraform output -raw connect)"
}

# Remove resources with Terraform.
destroy() {
    # Private key variable is still needed for destroy command.
    terraform destroy -auto-approve -var="private_key=mock_path"
}

# Print error message and exit with error code.
error() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

# Create temporary SSH key for Terraform.
generate_keys() {
    local _private_key

    echo "Generating temporary SSH keys for cloud servers..."

    # Generate a temporary paths.
    #
    # Flags:
    #     -u: Do not create files. Only print path name.
    _private_key=$(mktemp -u)

    # Generate SSH private and public keys.
    #
    # Errors are thrown when using ed25519 key format.
    #
    # Flags:
    #     -q: Silence ssh-keygen.
    #     -N "": Do not associate a password with the key.
    #     -f <path>: Filename of the key file.
    #     -t ed25519: Use RSA cryptosystem.
    ssh-keygen -q -N "" -b 4096 -f "$_private_key" -t rsa

    # Set correct permissions for SSH keys.
    #
    # Flags:
    #     600: Give only read and write permissions to current user.
    chmod 600 "$_private_key"
    chmod 600 "$_private_key.pub"

    RET_VAL="$_private_key"
}

# Get manage.sh version string
version() {
    echo "manage.sh 0.0.1"
}

# Script entrypoint.
main() {
    assert_cmd mktemp

    # Parse command line arguments.
    for arg in "$@"; do
        case "$arg" in
            apply)
                shift
                apply "$@"
                exit 0
                ;;
            connect)
                shift
                connect "$@"
                exit 0
                ;;
            destroy)
                shift
                destroy "$@"
                exit 0
                ;;
            -v|--version)
                version
                exit 0
                ;;
            *)
                ;;
        esac
    done

    usage "main"
}

# Execute main with command line arguments and call exit on failure.
main "$@"
