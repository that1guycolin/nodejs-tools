#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

INSTALL_DIRECTORY="${HOME}/.local/bin"
DO_ALL=false
verify_executables=(
    bash-language-server
    docker-compose-langserver
    eslint
    fish-lsp
    markdownlint
    marked
    prettier
    tsc
    typescript-language-server
    vscode-css-language-server
    vscode-eslint-language-server
    vscode-html-language-server
    vscode-markdown-language-server
    yaml-language-server
)
declare -a user_list
declare -a executable_list

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

INSTALL_MANIFEST="${DIR}/installed.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

function usage {
    echo -e "$(
        cat <<EOF
${PURPLE}USAGE:${NC} ${0##*/} ${BLUE}[OPTIONS] ${NC}

  Install wrapper scripts to ${CYAN}\${HOME}/.local/bin${NC} in order to \
integrate programs
  from nodejs-tools with applications on the host machine.

  The following wrapper scripts are available:

    * bash-language-server              * docker-compose-langserver
    * eslint                            * fish-lsp
    * markdownlint                      * marked
    * prettier                          * tsc
    * typescript-language-server        * vscode-css-language-server
    * vscode-eslint-language-server     * vscode-html-language-server
    * vscode-json-language-server       * vscode-markdown-language-server
    * yaml-language-server

${PURPLE}OPTIONS: ${NC}
  ${CYAN}-i, --install-directory ${BLUE}DIRECTORY ${NC}
      The directory in which to place the executable scripts.

  ${CYAN}-e, --executable ${BLUE}EXE ${NC}
      The name of an executable for which you wish to create a wrapper script.
      If not passed, the script will install wrapper scripts for all possible
      applications. You can use this flag multiple times.

  ${CYAN}-a, --all ${NC}
      Create all possible executable wrapper scripts.

  ${CYAN}-r, --remove${NC}
      Remove all installed wrapper scripts.

  ${CYAN}-h, --help ${NC}
      Display this message and exit.
EOF
    )"
}

function remove_wrapper_scripts {
    [ -f "$INSTALL_MANIFEST" ] || {
        echo -e "${RED}ERROR:${NC} Cannot locate the install manifest."
        echo "If you did create wrapper scripts, they must be manually removed."
        exit 5
    }
    mapfile -t scripts <"$INSTALL_MANIFEST"
    for script in "${scripts[@]}"; do
        rm -f "$script"
        echo -e "${YELLOW}Removed ${script}."
    done
    echo -e ""
    echo -e "${YELLOW}All scripts removed.${NC}"
    exit 0
}

function validate_input {
    if [[ $DO_ALL == true ]]; then
        for exe in "${verify_executables[@]}"; do
            executable_list+=("$exe")
        done
    else
        [[ "${#user_list[@]}" -gt 0 ]] || {
            echo -e "${RED}ERROR:${NC} Provide at least one program."
            usage
            exit 3
        }
        for exe in "${user_list[@]}"; do
            found=false
            for item in "${verify_executables[@]}"; do
                if [[ "$item" == "$exe" ]]; then
                    found=true
                    executable_list+=("$exe")
                    break
                fi
            done
            if [[ $found == false ]]; then
                echo -e "${YELLOW}WARNING:${NC} ${exe} not a valid option, \
 skipping..."
            fi
        done
        [[ "${#user_list[@]}" -gt 0 ]] || {
            echo -e "${RED}ERROR:${NC} No provided programs were valid."
            usage
            exit 4
        }
    fi
}

function make_wrapper {
    local program="$1"
    local script="${INSTALL_DIRECTORY}/${program}"

    cat >"$script" <<EOF
#!/usr/bin/env bash

exec podman exec -i \\
    -w "\$(pwd)" \\
    nodejs-tools \\
    $program "\$@"
EOF
    chmod +x "$script"
    echo "$script" >>"$INSTALL_MANIFEST"
}

function main {
    PARSED=$(getopt -o i:e:arh -l install:,executable:,all,remove,help -- "$@") || {
        usage
        exit 1
    }
    eval set -- "$PARSED"
    while true; do
        case "$1" in
            -i | --install-directory)
                INSTALL_DIRECTORY="$2"
                shift 2
                ;;
            -e | --executable)
                user_list+=("$2")
                shift 2
                ;;
            -a | --all)
                DO_ALL=true
                shift
                ;;
            -r | --remove)
                remove_wrapper_scripts
                ;;
            -h | --help)
                usage
                exit
                ;;
            --)
                shift
                break
                ;;
            *)
                echo -e "${RED}Invalid option: ${NC}$1" >&2
                usage
                exit 2
                ;;
        esac
    done

    validate_input

    touch "$INSTALL_MANIFEST"
    for exe in "${executable_list[@]}"; do
        make_wrapper "$exe"
        echo -e "Wrote wrapper script for ${GREEN}${exe}${NC}!"
    done

    echo -e "${GREEN}Complete!${NC}"
}
main "$@"
