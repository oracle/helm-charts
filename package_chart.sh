#!/bin/bash
# Copyright (c) 2020, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

CHART=$1
TARGET_DIR=$2

if [[ -z ${CHART} ]]; then
  echo "please specify the name of the chart to package"
  exit 1
fi

pushd "./${CHART}" || (echo "Can't find the folder passed" && exit 1)
helm dependencies update
helm package . -d "$TARGET_DIR"
popd || exit

pushd ./charts/ || (echo "charts folder was not found" && exit 1)
helm repo index ../
popd || exit
