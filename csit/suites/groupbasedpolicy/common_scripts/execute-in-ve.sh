#!/usr/bin/env bash

source ~/.profile
source ${VIRT_ENV_PATH}/bin/activate
"$@"
deactivate