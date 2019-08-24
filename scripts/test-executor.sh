#!/usr/bin/env bash
set -x

#Directory to store the output artifacts
export LOG_DIR=${LOG_DIR:-/tmp/log}

git clone https://github.com/elek/ozone-ci.git "$LOG_DIR"


#The working directory
BASE_DIR=${BASE_DIR:-/workdir}
mkdir -p "$BASE_DIR"

if [ -z "$WORKFLOW_NAME" ]; then
  echo '$WORKFLOW_NAME should be set'
  exit 1
fi

mkdir -p $BASE_DIR
if [[ "$BASE_DIR" ]]; then
  cd $BASE_DIR
fi

JOB_NAME=$(cut -d '-' -f 1 <<<"$WORKFLOW_NAME")
# WORKFLOW_NAME=
# TEST_TYPE=

export OUTPUT_DIR=$LOG_DIR/${JOB_NAME:-results}/$WORKFLOW_NAME/$TEST_TYPE
mkdir -p $OUTPUT_DIR

cd $BASE_DIR

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/test-executor-lib.sh"

if [ "$UPDATE_GITHUB_STATUS" == "true" ]; then
  send_status $LOG_DIR "${JOB_NAME:-results}/$WORKFLOW_NAME/$TEST_TYPE"
fi

set -o pipefail

"$@" 2>&1 | tee $OUTPUT_DIR/output.log

RESULT=$?

if [[ "$RESULT" == "0" ]]; then
  echo "success" >"$OUTPUT_DIR/result"
else
  echo "failure" >"$OUTPUT_DIR/result"
fi

git_commit_result

if [ "$UPDATE_GITHUB_STATUS" == "true" ]; then
  send_status $LOG_DIR "${JOB_NAME:-results}/$WORKFLOW_NAME/$TEST_TYPE"
fi
exit $RESULT
