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
main.sh apply
Provision cloud resources with Terraform

USAGE:
    main.sh apply [FLAGS] [provider]

FLAGS:
    -h, --help       Print help information

ARGS:
    <provider>       Cloud platform
EOF
            ;;
        connect)
            cat 1>&2 <<EOF
main.sh connect
Provision and connect to cloud resources

USAGE:
    main.sh connect [FLAGS] [OPTIONS]

FLAGS:
    -h, --help       Print help information

ARGS:
    <provider>       Cloud platform
EOF
            ;;
        destroy)
            cat 1>&2 <<EOF
main.sh destroy
Remove cloud resources with Terraform

USAGE:
    main.sh destroy [FLAGS] [OPTIONS]

FLAGS:
    -h, --help       Print help information

ARGS:
    <provider>       Cloud platform
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
    connect          Provision and connect to cloud resources
    destroy          Remove cloud resources with Terraform
EOF
            ;;
    esac
}

# Apply subcommand.
apply() {
    local _private_key

    # Parse command line arguments.
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage "apply"
                exit 0
                ;;
            *)
                ;;
        esac
    done

    generate_keys
    _private_key="$RET_VAL"

    (cd "cloud/$1" && terraform init > /dev/null)
    (cd "cloud/$1" && terraform apply -auto-approve -var="private_key=$_private_key")
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

# Connect subcommand.
connect() {
    # Parse command line arguments.
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage "apply"
                exit 0
                ;;
            *)
                ;;
        esac
    done

    apply "$@"
    (cd "cloud/$1" && eval "$(terraform output -raw connect)")
}

# Destroy subcommand.
destroy() {
    # Parse command line arguments.
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage "apply"
                exit 0
                ;;
            *)
                ;;
        esac
    done

    # Private key variable is still needed for destroy command.
    (cd "cloud/$1" && terraform destroy -auto-approve -var="private_key=mock_path")
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

# Get main.sh version string
version() {
    echo "main.sh 0.0.1"
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
