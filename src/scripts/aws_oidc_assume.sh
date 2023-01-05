#!/bin/bash -eo pipefail

SetupEnv() {
  export D_REGION=$(eval echo "${D_REGION}")
  export D_ROLE_ARN=$(eval echo "${D_ROLE_ARN}")
  export D_DURATION_SECONDS=$(eval echo "${D_DURATION_SECONDS}")
  export D_ROLE_EXTERNAL_ID=$(eval echo "${D_ROLE_EXTERNAL_ID}")

  echo "D_REGION=$D_REGION"
  echo "D_ROLE_ARN=$D_ROLE_ARN"
  echo "D_DURATION_SECONDS=$D_DURATION_SECONDS"
  echo "D_ROLE_EXTERNAL_ID=$D_ROLE_EXTERNAL_ID"

  export AWS_REGION=$D_REGION
}

AssumeRole() {
  echo "Assuming role ${D_ROLE_ARN}"
  if [ -z "$D_ROLE_EXTERNAL_ID" ]; then
    eval "$(aws sts assume-role-with-web-identity --role-arn "${D_ROLE_ARN}" --role-session-name "${CIRCLE_PROJECT_REPONAME}-${CIRCLE_WORKFLOW_ID}" --web-identity-token "${CIRCLE_OIDC_TOKEN}" --duration-seconds "${D_DURATION_SECONDS}" | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)\nexport AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)\nexport AWS_SESSION_TOKEN=\(.SessionToken)\n"')"
  else
    eval "$(aws sts assume-role-with-web-identity --external-id "${D_ROLE_EXTERNAL_ID}" --role-arn "${D_ROLE_ARN}" --role-session-name "${CIRCLE_PROJECT_REPONAME}-${CIRCLE_WORKFLOW_ID}" --web-identity-token "${CIRCLE_OIDC_TOKEN}" --duration-seconds "${D_DURATION_SECONDS}" | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)\nexport AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)\nexport AWS_SESSION_TOKEN=\(.SessionToken)\n"')"
  fi
}

PersistEnvVars() {
  echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
  echo "export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" >> "${BASH_ENV}"
  echo "export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" >> "${BASH_ENV}"
  echo "export AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}" >> "${BASH_ENV}"
}

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  SetupEnv
  AssumeRole
  PersistEnvVars
else
  echo "AWS_ACCESS_KEY_ID is set. Not assuming OIDC role."
fi
