#!/bin/bash -eo pipefail

SetupEnv() {
  export D_REGION=$(eval echo "${D_REGION}")
  export D_SERVICE_NAME=$(eval echo "${D_SERVICE_NAME}")
  export D_ACCOUNT_CANONICAL_SLUG=$(eval echo "${D_ACCOUNT_CANONICAL_SLUG}")
  export D_DEPLOYOMAT_CANONICAL_SLUG=$(eval echo "${D_DEPLOYOMAT_CANONICAL_SLUG}")
  export D_AMI_ID=$(eval echo "${D_AMI_ID}")
  export D_MANIFEST_PATH=$(eval echo "${D_MANIFEST_PATH}")
  D_DEPLOY_CONFIG_FILE=$(eval echo "${D_DEPLOY_CONFIG_FILE}")

  echo "D_REGION=$D_REGION"
  echo "D_SERVICE_NAME=$D_SERVICE_NAME"
  echo "D_ACCOUNT_CANONICAL_SLUG=$D_ACCOUNT_CANONICAL_SLUG"
  echo "D_DEPLOYOMAT_CANONICAL_SLUG=$D_DEPLOYOMAT_CANONICAL_SLUG"
  echo "D_AMI_ID=$D_AMI_ID"
  echo "D_MANIFEST_PATH=$D_MANIFEST_PATH"
  echo "D_DEPLOY_CONFIG_FILE=$D_DEPLOY_CONFIG_FILE"
  echo "D_ACTION=$D_ACTION"

  export AWS_REGION=$D_REGION
}

GetAmiId() {
  if [ -z "$D_AMI_ID" ]; then
    PARAM_PREFIX=$(aws ssm get-parameter --name "/omat/account_registry/${D_ACCOUNT_CANONICAL_SLUG}" --output text --query Parameter.Value | jq --raw-output '.prefix')
    ARCHITECTURE=$(aws ssm get-parameter --name "${PARAM_PREFIX}/config/${D_SERVICE_NAME}/architecture" --output text --query Parameter.Value)
    echo "ARCHITECTURE=$ARCHITECTURE"
    echo "Extracting AMI id from packer manifest..."
    export D_AMI_ID=$(cat "$D_MANIFEST_PATH" | jq --arg arch "$ARCHITECTURE" -r '.builds | map(select(.custom_data.arch == $arch)) | map(select(.artifact_id | startswith($ENV.D_REGION))) | .[0].artifact_id | split(":") | .[1]')
    echo "D_AMI_ID=$D_AMI_ID"
  fi
}

GetRoleAndSfnArn() {
  PARAM_PREFIX=$(aws ssm get-parameter --name "/omat/account_registry/${D_DEPLOYOMAT_CANONICAL_SLUG}" --output text --query Parameter.Value | jq --raw-output '.prefix')
  echo "PARAM_PREFIX=$PARAM_PREFIX"
  ROLE_ARN=$(aws ssm get-parameter --name "${PARAM_PREFIX}/roles/deployer" --output text --query Parameter.Value)
  SFN_ARN=$(aws ssm get-parameter --name "${PARAM_PREFIX}/config/deployomat/${D_ACTION}_sfn_arn" --output text --query Parameter.Value)
}

AssumeRole() {
  echo "Assuming role ${ROLE_ARN}"
  eval $(aws sts assume-role --role-arn "${ROLE_ARN}" --role-session-name "${D_SERVICE_NAME}" | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)\nexport AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)\nexport AWS_SESSION_TOKEN=\(.SessionToken)\n"')
}

Execute() {
  echo "Executing state machine to ${D_ACTION} ${D_SERVICE_NAME} in ${D_ACCOUNT_CANONICAL_SLUG}"
  aws stepfunctions start-execution --state-machine-arn "$SFN_ARN" --input "$INPUT"
}

BuildInput() {
  INPUT=$(jq --null-input --arg acct "$D_ACCOUNT_CANONICAL_SLUG" --arg srv "$D_SERVICE_NAME" '{"AccountCanonicalSlug": $acct, "ServiceName": $srv}')
  if [ "$D_ACTION" = "deploy" ]; then
    INPUT=$(echo "$INPUT" | jq --arg ami "$D_AMI_ID" '.AmiId |= $ami')
    if [ -n "$D_DEPLOY_CONFIG_FILE" ]; then
      if [ ! -e "$D_DEPLOY_CONFIG_FILE" ]; then
        echo "Could not find configuration file ${D_DEPLOY_CONFIG_FILE}"
        exit 1
      fi

      INPUT=$(echo "$INPUT" | jq --slurpfile conf "$D_DEPLOY_CONFIG_FILE" '.DeployConfig |= $conf[0]')
    fi
  fi
}

SetupEnv
if [ "$D_ACTION" = "deploy" ]; then
  GetAmiId
fi
GetRoleAndSfnArn
BuildInput
AssumeRole
Execute
