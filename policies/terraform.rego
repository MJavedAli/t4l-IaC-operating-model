package terraform.plan

import rego.v1

required_tags := {
  "BusinessUnit",
  "CostCentre",
  "DataClassification",
  "Environment",
  "ManagedBy",
  "Owner",
  "Service",
}

# This sample limits the generic tag rule to resource types in the vertical
# slice that support tags. A production policy library would maintain and test
# a broader catalogue rather than assuming every aws_* resource is taggable.
taggable_types := {
  "aws_cloudwatch_log_group",
  "aws_ecs_service",
  "aws_ecs_task_definition",
  "aws_iam_role",
}

deny contains message if {
  resource := input.resource_changes[_]
  resource.mode == "managed"
  resource.type in taggable_types
  action_is_create_or_update(resource.change.actions)
  after := object.get(resource.change, "after", {})
  tags := object.get(after, "tags", {})
  missing := {key | some key in required_tags; not tags[key]}
  count(missing) > 0
  message := sprintf("%s is missing mandatory tags: %v", [resource.address, missing])
}

deny contains message if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket_public_access_block"
  action_is_create_or_update(resource.change.actions)
  after := resource.change.after
  not after.block_public_acls
  message := sprintf("%s must set block_public_acls=true", [resource.address])
}

deny contains message if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket_public_access_block"
  action_is_create_or_update(resource.change.actions)
  after := resource.change.after
  not after.block_public_policy
  message := sprintf("%s must set block_public_policy=true", [resource.address])
}

deny contains message if {
  resource := input.resource_changes[_]
  resource.type == "aws_ecs_service"
  action_is_create_or_update(resource.change.actions)
  config := resource.change.after.network_configuration[_]
  config.assign_public_ip
  message := sprintf("%s must not assign public IPs without an approved exception", [resource.address])
}

action_is_create_or_update(actions) if {
  actions[_] == "create"
}

action_is_create_or_update(actions) if {
  actions[_] == "update"
}
