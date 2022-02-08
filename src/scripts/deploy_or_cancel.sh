#!/bin/bash -eo pipefail

SetupEnv() {
  export D_REGION=$(eval echo "${D_REGION}")
  export D_SERVICE_NAME=$(eval echo "${D_SERVICE_NAME}")
  export D_ACCOUNT_NAME=$(eval echo "${D_ACCOUNT_NAME}")
  export D_ENVIRONMENT=$(eval echo "${D_ENVIRONMENT}")
  export D_AMI_ID=$(eval echo "${D_AMI_ID}")
  export D_ARCHITECTURE=$(eval echo "${D_ARCHITECTURE}")
  export D_MANIFEST_PATH=$(eval echo "${D_MANIFEST_PATH}")
  export D_ORGANIZATION_PREFIX=$(eval echo "${D_ORGANIZATION_PREFIX}")
  D_DEPLOY_CONFIG_FILE=$(eval echo "${D_DEPLOY_CONFIG_FILE}")
  export AWS_REGION=$D_REGION
}

GetAmiId() {
  if [ -z "$D_AMI_ID" ]; then
    export D_AMI_ID=$(cat "$D_MANIFEST_PATH" | jq -r '.builds | map(select(.custom_data.arch == $ENV.D_ARCHITECTURE)) | map(select(.artifact_id | startswith($ENV.D_REGION))) | .[0].artifact_id | split(":") | .[1]')
  fi
}

GetRoleAndSfnArn() {
  ROLE_ARN=$(aws ssm get-parameter --name "/${D_ORGANIZATION_PREFIX}/${D_ENVIRONMENT}/ci-cd/roles/deployer" --output text --query Parameter.Value)
  SFN_ARN=$(aws ssm get-parameter --name "/${D_ORGANIZATION_PREFIX}/${D_ENVIRONMENT}/ci-cd/config/deployomat/${D_ACTION}_sfn_arn" --output text --query Parameter.Value)
}

AssumeRole() {
  echo "Assuming role ${ROLE_ARN}"
  eval $(aws sts assume-role --role-arn "${ROLE_ARN}" --role-session-name "${D_SERVICE_NAME}" | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)\nexport AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)\nexport AWS_SESSION_TOKEN=\(.SessionToken)\n"')
}

Execute() {
  echo "Executing state machine to ${D_ACTION} ${D_SERVICE_NAME} in ${D_ACCOUNT_NAME}"
  aws stepfunctions start-execution --state-machine-arn "$SFN_ARN" --input "$INPUT"
}

BuildInput() {
  INPUT=$(jq --null-input --arg acct "$D_ACCOUNT_NAME" --arg srv "$D_SERVICE_NAME" '{"AccountName": $acct, "ServiceName": $srv}')
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
