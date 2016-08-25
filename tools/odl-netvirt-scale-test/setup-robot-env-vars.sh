#!/usr/bin/env bash

# Test ENV VARS
export WORKSPACE='/opt/odl/test'
export DEFAULT_LINUX_PROMPT='$'
export ODL_DIR='/opt/odl'
export BUNDLEFOLDER='distribution-karaf-0.4.0-Beryllium'
export USER_HOME=$HOME

# Test to RUN
export SUITES="${USER_HOME}/test/csit/suites/netvirt/Netvirt_Scale/020_netvirt_scale.robot.robot"

# OpenDaylight System ENV VARS
export ODL_SYSTEM_IP='10.0.0.5'
export ODL_SYSTEM_USER=$USER
export ODL_SYSTEM_PROMPT='$'

# Tools System ENV VARS
export NUM_TOOLS_SYSTEM=3
export TOOLS_SYSTEM_IP='10.0.0.29'
export TOOLS_SYSTEM_1_IP='10.0.0.29'
export TOOLS_SYSTEM_2_IP='10.0.0.31'
export TOOLS_SYSTEM_3_IP='10.0.0.200'
export TOOLS_SYSTEM_4_IP='10.0.0.33'
export TOOLS_SYSTEM_PROMPT='$'
export TOOLS_SYSTEM_USER=$USER
export TOOLS_SYSTEM_PASSWORD='password'
