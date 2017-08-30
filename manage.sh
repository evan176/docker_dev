#!/bin/bash
# Little tool for easily control development step
COMMANDS=()

# Add command with format: COMMANDS+=("argument", "command")
COMMANDS+=("echo" "echo test")
COMMANDS+=("ls" "ls")

# Leave it empty if you don't need to customize it.
# The development folder (default: path of current folder)
PROJECT_DIR=""
# Specify the docker name (default: docker)
DOCKER_BINARY=""
# The file path of Dockefile (default: ./Dockerfile)
DOCKER_FILE_PATH=""
# The image name (default: folder name:latest)
DOCKER_IMG_NAME=""
# The container name (default: folder name)
DOCKER_CONTAINER_NAME=""
# The context path (default: current folder)
DOCKER_CONTEXT_PATH=""
# The WORKDIR in Dockerfile for volume (default: /workspace)
DOCKER_WORKDIR=""
# Extra params for docker
DOCKER_EXTRA_PARAMS=""
# User ID (default: current user id)
USER_ID=""


##############################################################################
err() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

##############################################################################
# Set default value for GLOBAL variables if it is empty.
# Globals:
#   PROJECT_DIR
#   DOCKER_BINARY
#   DOCKER_FILE_PATH
#   DOCKER_IMG_NAME
#   DOCKER_CONTAINER_NAME
#   DOCKER_CONTEXT_PATH
#   DOCKER_WORKDIR
#   DOCKER_EXTRA_PARAMS
#   USER_ID
# Arguments:
#   None
# Returns:
#   None
##############################################################################
process_vars () {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT="$(basename ${SCRIPT_DIR})"

  if [[ -z ${COMMANDS} ]]; then
    COMMANDS=()
  fi

  if [[ -z ${PROJECT_DIR} ]]; then
    PROJECT_DIR=${SCRIPT_DIR}
  fi

  if [[ -z ${DOCKER_BINARY} ]]; then
    DOCKER_BINARY="docker"
  fi

  if [[ -z ${DOCKER_FILE_PATH} ]]; then
    DOCKER_FILE_PATH="${SCRIPT_DIR}/Dockerfile"
  fi

  if [[ -z ${DOCKER_IMG_NAME} ]]; then
    DOCKER_IMG_NAME="${PROJECT}:latest"
  fi

  if [[ -z ${DOCKER_CONTAINER_NAME} ]]; then
    DOCKER_CONTAINER_NAME="${PROJECT}"
  fi

  if [[ -z ${DOCKER_CONTEXT_PATH} ]]; then
    DOCKER_CONTEXT_PATH="${SCRIPT_DIR}"
  fi

  if [[ -z ${DOCKER_WORKDIR} ]]; then
    DOCKER_WORKDIR="/workspace"
  fi

  if [[ -z ${USER_ID} ]]; then
    USER_ID=$(id -u)
  fi
}


##############################################################################
# Build docker image with given name and docker file
# Globals:
#   DOCKER_BINARY
#   DOCKER_FILE_PATH
#   DOCKER_IMG_NAME
#   DOCKER_CONTEXT_PATH
# Arguments:
#   None
# Returns:
#   None
##############################################################################
build_image () {
  # If no image then build it
  if [[ -z "$(${DOCKER_BINARY} images -q ${DOCKER_IMG_NAME})" ]]; then
    ${DOCKER_BINARY} build -t ${DOCKER_IMG_NAME} -f ${DOCKER_FILE_PATH} ${DOCKER_CONTEXT_PATH}
    RETURN_CODE=$?
    if [[ ${RETURN_CODE} -eq 0 ]]; then
      echo "Successfully build image: ${DOCKER_IMG_NAME}!"
    else
      err "Fail to build image: ${DOCKER_IMG_NAME}"
      exit ${RETURN_CODE}
    fi
  else
    echo "The image: ${DOCKER_IMG_NAME} already exists!"
  fi
}

##############################################################################
# Run container with existing image
# Globals:
#   PROJECT_DIR
#   DOCKER_BINARY
#   DOCKER_IMG_NAME
#   DOCKER_CONTAINER_NAME
#   DOCKER_WORKDIR
#   DOCKER_EXTRA_PARAMS
#   USER_ID
# Arguments:
#   None
# Returns:
#   None
##############################################################################
run_container () {
  # Run container if it not exist
  if [[ -z "$(${DOCKER_BINARY} ps -a -q -f name=${DOCKER_CONTAINER_NAME})" ]]; then
    ${DOCKER_BINARY} run -d -it --user ${USER_ID} --name ${DOCKER_CONTAINER_NAME}\
      -v ${PROJECT_DIR}:${DOCKER_WORKDIR} ${DOCKER_EXTRA_PARAMS}\
      "${DOCKER_IMG_NAME}"
    RETURN_CODE=$?
    if [[ ${RETURN_CODE} -ne 0 ]]; then
      err "Fail to run container: ${DOCKER_CONTAINER_NAME} with image: ${DOCKER_IMG_NAME}"
      exit ${RETURN_CODE}
    fi
  fi
  echo "The container: ${DOCKER_CONTAINER_NAME} is running!"
}


##############################################################################
# Stop container
# Globals:
#   DOCKER_BINARY
#   DOCKER_IMG_NAME
#   DOCKER_CONTAINER_NAME
# Arguments:
#   None
# Returns:
#   None
##############################################################################
stop_container () {
  # Check container exist
  if [[ -n "$(${DOCKER_BINARY} ps -a -q -f name=${DOCKER_CONTAINER_NAME})" ]]; then
    # Stop container if it is running
    if [[ "$(${DOCKER_BINARY} inspect -f {{.State.Status}} ${DOCKER_CONTAINER_NAME})" == "running" ]]; then
      ${DOCKER_BINARY} stop ${DOCKER_CONTAINER_NAME}
      RETURN_CODE=$?
      if [[ ${RETURN_CODE} -ne 0 ]]; then
        err "Fail to stop container: ${DOCKER_CONTAINER_NAME} with image: ${DOCKER_IMG_NAME}"
        exit ${RETURN_CODE}
      fi
    fi
    echo "The container: ${DOCKER_CONTAINER_NAME} is stopped!"

    # Remove container
    ${DOCKER_BINARY} rm -v ${DOCKER_CONTAINER_NAME}
    RETURN_CODE=$?
    if [[ ${RETURN_CODE} -eq 0 ]]; then
      echo "Successfully remove container: ${DOCKER_CONTAINER_NAME}!"
    else
      err "Fail to remove container: ${DOCKER_CONTAINER_NAME} with image: ${DOCKER_IMG_NAME}"
      exit ${RETURN_CODE}
    fi
  fi
}

##############################################################################
#
# Globals:
#   DOCKER_BINARY
#   DOCKER_IMG_NAME
#   DOCKER_CONTAINER_NAME
# Arguments:
#   None
# Returns:
#   None
##############################################################################
remove_image () {
  # Check image exist
  if [[ -n "$(${DOCKER_BINARY} images -q ${DOCKER_IMG_NAME})" ]]; then
    # Remove image
    ${DOCKER_BINARY} rmi ${DOCKER_IMG_NAME}
    RETURN_CODE=$?
    if [[ ${RETURN_CODE} -eq 0 ]]; then
      echo "The image: ${DOCKER_IMG_NAME} is removed!"
    else
      err "Fail to remove container: ${DOCKER_CONTAINER_NAME} with image: ${DOCKER_IMG_NAME}"
      exit ${RETURN_CODE}
    fi
  fi
}

print_help() {
  echo "This tool help for easily controlling development with docker."
  echo "Please add customized commands set customize variables in this"
  echo "script before executing."
  echo "    start"
  echo "        Build image & start container for development environment"
  echo "    reset"
  echo "        Rebuild image & restart development environment"
  echo "    stop"
  echo "        Stop container"
  echo "    clean"
  echo "        Stop container & remove image"
  echo "    ls"
  echo "        List all commands"
  echo "    bash"
  echo "        Open /bin/bash in container"
}

main() {
  process_vars

  if [[ $# -eq 0 ]]; then
    print_help
    exit 0
  fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      start)
        build_image
        run_container
        ;;
      reset)
        stop_container
        remove_image
        build_image
        run_container
        ;;
      stop)
        stop_container
        ;;
      clean)
        stop_container
        remove_image
        ;;
      bash)
        echo "Open bash in container: ${DOCKER_CONTAINER_NAME}" 
        ${DOCKER_BINARY} exec -it ${DOCKER_CONTAINER_NAME} bash
        ;;
      list)
        printf "%10s | %20s\n" "argument" "command" 
        for (( i=0; i<${#COMMANDS[@]}; i+=2 )); do
          printf "%10s | %20s\n" "${COMMANDS[$i]}" "${COMMANDS[$(($i + 1))]}" 
        done
        ;;
      *)
        for (( i=0; i<${#COMMANDS[@]}; i+=2 )); do
          if [[ "$1" == "${COMMANDS[$i]}" ]]; then
            echo "Run command: [${COMMANDS[$(($i + 1))]}] in container: ${DOCKER_CONTAINER_NAME}" 
            ${DOCKER_BINARY} exec ${DOCKER_CONTAINER_NAME} bash -c "${COMMANDS[$(($i + 1))]}"
            break
          fi
        done
        ;;
    esac
      shift
  done
}

main "$@"
