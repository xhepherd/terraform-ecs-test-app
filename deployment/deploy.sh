#!/bin/sh -e

#Usage: CONTAINER_VERSION=docker_container_version

# register task-definition
sed <td-ads-app.template -e "s,@VERSION@,$CONTAINER_VERSION,">TASKDEF.json
aws ecs register-task-definition --cli-input-json file://TASKDEF.json > REGISTERED_TASKDEF.json
TASKDEFINITION_ARN=$( < REGISTERED_TASKDEF.json jq .taskDefinition.taskDefinitionArn )

# update service
sed "s,@@TASKDEFINITION_ARN@@,$TASKDEFINITION_ARN," <service-update-ads-app.json >SERVICEDEF.json
aws ecs update-service --cli-input-json file://SERVICEDEF.json | tee SERVICE.json
#aws ecs update-service --cluster ads-app --service ads-app --force-new-deployment