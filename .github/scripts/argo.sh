#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat << EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(basename "${BASH_SOURCE[0]}") --server SERVER_NAME --path path --repo GIT_REPO --revision GIT_SHA --dest-namespace DEST_NAMESPACE --image KUSTOMIZE_OVRERIDE --auth-token AUTH_TOKEN --project PROJECT_NAME

A wrapper for ArgoCD Cli, to standardize the options for CI/CD.

Available options:

--help        Print this help and exit
--appname     Name of ArgoCD App
--server          ArgoCD server Address
--repo            Source Github Repository From which Argo will deploy
--revision         Git Revision/SHA that needs to be deployed
--path       kustomize Path/path to deploy
--dest-namespace  Destination Namespace
--image           Image Override, for ex. alpine:3.10=mydockerimage:rev
--auth-token      ArgoCD authentication token for the Project 
--project         Name of ArgoCD project Setup.

EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  flag=0
  param=''
  path=''
  image=""
  project=""
  repo=""
  authtoken=""
  destnamespace=""
  server=""
  revision=""
  appname=""
  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -f | --flag) flag=1 ;; # example flag
    -p | --param) # example named parameter
      param="${2-}"
      shift
      ;;
    -d | --path) 
        path="${2-}"
        shift
        ;;
    -i | --image) # example named parameter
      image="${2-}"
      shift
      ;;
    --project) # example named parameter
      project="${2-}"
      shift
      ;;
    --dest-namespace) # example named parameter
      destnamespace="${2-}"
      shift
      ;;
    --auth-token) # example named parameter
      authtoken="${2-}"
      shift
      ;;
    --server) # example named parameter
      server="${2-}"
      shift
      ;;
    --repo) # example named parameter
      repo="${2-}"
      shift
      ;;
    --revision) # example named parameter
      revision="${2-}"
      shift
      ;;
    --appname) # example named parameter
      appname="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done


  # check required params and arguments
  [[ -z "${server-}" ]] && die "Missing required parameter: server"

  return 0
}

parse_params "$@"
setup_colors

# argo command
argocd app create ${appname} --server ${server} --insecure --upsert --sync-policy auto --sync-option CreateNamespace=true --repo ${repo} --revision ${revision}  --path ${path}  --dest-namespace ${destnamespace} --dest-server https://kubernetes.default.svc --kustomize-image  ${image}  --auth-token ${authtoken} --project ${project}


# /argocd app create pr-1 --server 20.253.152.212 --repo https://github.com/spunkandgritt/kustomize-argocd.git --revision 9ac22ac6da799ae2c717db0df2eb7ae2c4f17770 --path kustomize/overlays/dev --dest-namespace develop-microservices --kustomize-image alpine:3.10=example-argocd:sha-9ac22ac@sha256:7d30db4828fe14dc5d8a70f146f7db6b872390d8dd040d0f09345fa4022e27dd --project apps2deploy --param asda --auth-token eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhcmdvY2QiLCJzdWIiOiJwcm9qOmFwcHMyZGVwbG95OmNyZWF0ZS1zeW5jIiwibmJmIjoxNjU4OTUzMzE4LCJpYXQiOjE2NTg5NTMzMTgsImp0aSI6IjdhMGQxYzQzLWMxMDUtNDk1ZC1iZmI1LWI3M2E5N2ZjOTY2MCJ9.NRi6CygWEfpznaZFASUCp8kQIQ30kKbBjoV3YwcofKg