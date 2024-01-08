#!/bin/bash

set -e

deploy_to_elastic() {
  sed -e "s/\${API_IMAGE}/$ESCAPED_API_IMAGE/g" -e "s/\${UI_IMAGE}/$ESCAPED_UI_IMAGE/g" docker-compose.template.yml > docker-compose.yml
  
  zip deploy.zip docker-compose.yml default.conf -r

  if ! eb deploy docker-elastic-beanstalk-up-dev; then
    STATUS=$(eb status docker-elastic-beanstalk-up-dev | grep -i status | awk '{print $2}')

    echo "Elastic Beanstalk Status: $STATUS"

    if [ "$STATUS" == "Ready" ]; then
      echo "Elastic Beanstalk is ready!"

      if ! eb deploy docker-elastic-beanstalk-up-dev; then
        echo "The Deployment is being made by the other package, but it's okay (in theory) as it uses the latest tags."
      fi

      exit 0
    elif [ "$STATUS" == "Updating" ] || [ "$STATUS" == "Pending" ]; then
      echo "The Deployment is being made by the other package, but it's okay (in theory) as it uses the latest tags."
      exit 0
    else
      echo "Unknown status: $STATUS. Exiting with an error."
      exit 1
    fi
  fi
}

check_ecr_images() {
  REPOSITORY_IMAGE_TAG_TO_CHECK="${GITHUB_REF_NAME%%@*}"

  if [ "$REPOSITORY_IMAGE_TAG_TO_CHECK" = "api" ]; then
    REPOSITORY_IMAGE_TAG_TO_CHECK="$UI_IMAGE_TAG"
  else
    REPOSITORY_IMAGE_TAG_TO_CHECK="$API_IMAGE_TAG"
  fi

  echo "Checking if the other package ECR image $REPOSITORY_IMAGE_TAG_TO_CHECK exists."

  while ! aws ecr describe-images \
    --repository-name $REPOSITORY \
    --image-ids imageTag="$REPOSITORY_IMAGE_TAG_TO_CHECK" >/dev/null 2>&1; do
    echo "ECR image does not exist. Retrying..."
    sleep 10
  done

  echo "ECR image $REPOSITORY_IMAGE_TAG_TO_CHECK exists"
}

deploy() {
  pip install awsebcli
  
  LATEST_API_TAG=$(git describe --tags --match="api*" --abbrev=0)
  LATEST_UI_TAG=$(git describe --tags --match="ui*" --abbrev=0)

  API_IMAGE_TAG="${LATEST_API_TAG//@/-}"
  UI_IMAGE_TAG="${LATEST_UI_TAG//@/-}"

  API_IMAGE="$REGISTRY/$REPOSITORY:$API_IMAGE_TAG"
  UI_IMAGE="$REGISTRY/$REPOSITORY:$UI_IMAGE_TAG"

  ESCAPED_API_IMAGE=$(echo "$API_IMAGE" | sed 's/[\/&]/\\&/g')
  ESCAPED_UI_IMAGE=$(echo "$UI_IMAGE" | sed 's/[\/&]/\\&/g')
  
  check_ecr_images
  deploy_to_elastic
}

deploy
