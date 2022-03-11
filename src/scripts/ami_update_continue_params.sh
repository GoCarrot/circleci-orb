#!/bin/bash -eo pipefail

SetupEnv() {
  D_REGION=$(eval echo "${D_REGION}")
  D_ACCOUNT_CANONICAL_SLUG=$(eval echo "${D_ACCOUNT_CANONICAL_SLUG}")
  D_DEPLOYOMAT_CANONICAL_SLUG=$(eval echo "${D_DEPLOYOMAT_CANONICAL_SLUG}")
  D_CONTINUATION_PARAMTERS=$(eval echo "${D_CONTINUATION_PARAMTERS}")

  echo "D_REGION=$D_REGION"
  echo "D_ACCOUNT_CANONICAL_SLUG=$D_ACCOUNT_CANONICAL_SLUG"
  echo "D_DEPLOYOMAT_CANONICAL_SLUG=$D_DEPLOYOMAT_CANONICAL_SLUG"
  echo "D_CONTINUATION_PARAMTERS=$D_CONTINUATION_PARAMTERS"

  export D_REGION D_ACCOUNT_CANONICAL_SLUG D_DEPLOYOMAT_CANONICAL_SLUG D_CONTINUATION_PARAMTERS
}

BuildParams() {
  PARAMS=$(jq --null-input '{"region": $ENV.D_REGION, "deployomat_canonical_slug": $ENV.D_DEPLOYOMAT_CANONICAL_SLUG, "account_canonical_slug": $ENV.D_ACCOUNT_CANONICAL_SLUG}')
  if [[ -n "${D_CONTINUATION_PARAMTERS}" ]]; then
    for var in $(echo "${D_CONTINUATION_PARAMTERS}" | tr ',' '\n'); do
      IFS='=' read -r key value <<< "$var"
      PARAMS=$(echo "$PARAMS" | jq --arg key "$key" --arg val "$value" '. + {($key): $val}')
    done
  fi

  echo "$PARAMS" | tee continue_params.json
}

SetupEnv
BuildParams
