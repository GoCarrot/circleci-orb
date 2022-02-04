#!/bin/bash -e -o pipefail
~/terraform/terraform -chdir="$module_path" output -json \
  | jq -r 'to_entries | map({key: .key | gsub("-"; "_") | ascii_upcase, value: .value.value, type: .value.value | type})
    | map(select(.type == "string" or .type == "number" or .type == "boolean"))
    | map("export TF_OUT_\(.key)=\(.value)")
    | join("\n")' > ${PLAN_PATH}/outputs.txt
cat ${PLAN_PATH}/outputs.txt >> $BASH_ENV
cat ${PLAN_PATH}/outputs.txt
