#!/bin/bash

# Created by argbash-init v2.8.1
# ARG_OPTIONAL_SINGLE([app-module],[],[Application module],[wsgi:app])
# ARG_OPTIONAL_SINGLE([backend],[],[Server backend],[gunicorn])
# ARG_OPTIONAL_SINGLE([conda-env],[],[Conda environment],[mitre-securing-ai])
# ARG_OPTIONAL_SINGLE([gunicorn-module],[],[Python module used to start Gunicorn WSGI server],[mitre.securingai.restapi.cli.gunicorn])
# ARG_OPTIONAL_ACTION([upgrade-db],[],[Upgrade the database schema],[upgrade_database])
# ARG_DEFAULTS_POS()
# ARGBASH_SET_INDENT([  ])
# ARG_HELP([Securing AI Testbed API Entry Point\n])"
# ARGBASH_PREPARE()
# needed because of Argbash --> m4_ignore([
### START OF CODE GENERATED BY Argbash v2.10.0 one line above ###
# Argbash is a bash code generator used to get arguments parsing right.
# Argbash is FREE SOFTWARE, see https://argbash.io for more info


die()
{
  local _ret="${2:-1}"
  test "${_PRINT_HELP:-no}" = yes && print_help >&2
  echo "$1" >&2
  exit "${_ret}"
}


begins_with_short_option()
{
  local first_option all_short_options='h'
  first_option="${1:0:1}"
  test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_app_module="wsgi:app"
_arg_backend="gunicorn"
_arg_conda_env="mitre-securing-ai"
_arg_gunicorn_module="mitre.securingai.restapi.cli.gunicorn"


print_help()
{
  printf '%s\n' "Securing AI Testbed API Entry Point
"
  printf 'Usage: %s [--app-module <arg>] [--backend <arg>] [--conda-env <arg>] [--gunicorn-module <arg>] [--upgrade-db] [-h|--help]\n' "$0"
  printf '\t%s\n' "--app-module: Application module (default: 'wsgi:app')"
  printf '\t%s\n' "--backend: Server backend (default: 'gunicorn')"
  printf '\t%s\n' "--conda-env: Conda environment (default: 'mitre-securing-ai')"
  printf '\t%s\n' "--gunicorn-module: Python module used to start Gunicorn WSGI server (default: 'mitre.securingai.restapi.cli.gunicorn')"
  printf '\t%s\n' "--upgrade-db: Upgrade the database schema"
  printf '\t%s\n' "-h, --help: Prints help"
}


parse_commandline()
{
  while test $# -gt 0
  do
    _key="$1"
    case "$_key" in
      --app-module)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_app_module="$2"
        shift
        ;;
      --app-module=*)
        _arg_app_module="${_key##--app-module=}"
        ;;
      --backend)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_backend="$2"
        shift
        ;;
      --backend=*)
        _arg_backend="${_key##--backend=}"
        ;;
      --conda-env)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_conda_env="$2"
        shift
        ;;
      --conda-env=*)
        _arg_conda_env="${_key##--conda-env=}"
        ;;
      --gunicorn-module)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_gunicorn_module="$2"
        shift
        ;;
      --gunicorn-module=*)
        _arg_gunicorn_module="${_key##--gunicorn-module=}"
        ;;
      --upgrade-db)
        upgrade_database
        exit 0
        ;;
      -h|--help)
        print_help
        exit 0
        ;;
      -h*)
        print_help
        exit 0
        ;;
      *)
        _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
        ;;
    esac
    shift
  done
}


# OTHER STUFF GENERATED BY Argbash

### END OF CODE GENERATED BY Argbash (sortof) ### ])
# [ <-- needed because of Argbash

shopt -s extglob
set -euo pipefail

###########################################################################################
# Global parameters
###########################################################################################

readonly ai_workdir="${AI_WORKDIR}"
readonly conda_dir="${CONDA_DIR}"
readonly gunicorn_module="${_arg_gunicorn_module}"
readonly logname="Container Entry Point"

set_parsed_globals() {
  readonly app_module="${_arg_app_module}"
  readonly conda_env="${_arg_conda_env}"
  readonly server_backend="${_arg_backend}"
}

###########################################################################################
# Secure the container at runtime
#
# Globals:
#   logname
# Arguments:
#   None
# Returns:
#   None
###########################################################################################

secure_container() {
  if [[ -f /usr/local/bin/secure-container.sh ]]; then
    /usr/local/bin/secure-container.sh
  else
    echo "${logname}: ERROR - /usr/local/bin/secure-container.sh script missing" 1>&2
    exit 1
  fi
}

###########################################################################################
# Upgrade the Securing AI database
#
# Globals:
#   ai_workdir
#   conda_dir
#   conda_env
#   logname
# Arguments:
#   None
# Returns:
#   None
###########################################################################################

upgrade_database() {
  echo "${logname}: INFO - Upgrading the Securing AI database"

  set_parsed_globals

  bash -c "\
  source ${conda_dir}/etc/profile.d/conda.sh &&\
  conda activate ${conda_env} &&\
  cd ${ai_workdir} &&\
  flask db upgrade -d ${ai_workdir}/migrations"
}

###########################################################################################
# Start gunicorn server
#
# Globals:
#   ai_workdir
#   app_module
#   conda_dir
#   conda_env
#   gunicorn_module
#   logname
# Arguments:
#   None
# Returns:
#   None
###########################################################################################

start_gunicorn() {
  echo "${logname}: INFO - Starting gunicorn server"

  bash -c "\
  source ${conda_dir}/etc/profile.d/conda.sh &&\
  conda activate ${conda_env} &&\
  cd ${ai_workdir} &&\
  python -m ${gunicorn_module} -c /etc/gunicorn/gunicorn.conf.py ${app_module}"
}

###########################################################################################
# Start RESTful API service
#
# Globals:
#   logname
#   server_backend
# Arguments:
#   None
# Returns:
#   None
###########################################################################################

start_restapi() {
  case ${server_backend} in
    gunicorn)
      start_gunicorn
      ;;
    *)
      echo "${logname}: ERROR - unsupported backend - ${server_backend}" 1>&2
      exit 1
      ;;
  esac
}

###########################################################################################
# Main script
###########################################################################################

parse_commandline "$@"
set_parsed_globals
secure_container
start_restapi
# ] <-- needed because of Argbash
