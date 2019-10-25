# Run an example R job with Batch.
#
# Based on 'Creating a Simple "Fetch & Run" AWS Batch Job'
# https://aws.amazon.com/blogs/compute/creating-a-simple-fetch-and-run-aws-batch-job/

#-------------------------------------------------------------------------------

# Get EC2 default security group ID and subnet IDs.
get_ec2_info <- function() {
  ec2 <- paws::ec2()
  default_vpc <- ec2$describe_vpcs(
    Filters = "isDefault=true"
  )
  security_group <- ec2$describe_security_groups(
    Filters = sprintf("vpc-id=%s", default_vpc$VpcId),
    GroupNames = "default"
  )
  subnets <- ec2$describe_subnets(
    Filters = sprintf("vpc-id=%s", default_vpc$VpcId)
  )
  return(list(
    security_group = security_group$SecurityGroups[[1]]$GroupId,
    subnets = sapply(subnets$Subnets, function(x) x$SubnetId)
  ))
}


#-------------------------------------------------------------------------------

# Create an IAM role for the given service, or return the role if one with the
# same name already exists.
create_or_get_role <- function(name, service, policy) {
  iam <- paws::iam()
  exists <- name %in% sapply(iam$list_roles()$Roles, function(x) x$RoleName)
  if (exists) {
    return(iam$get_role(name))
  }
  
  role <- iam$create_role(
    RoleName = name,
    AssumeRolePolicyDocument = jsonlite::toJSON(trust_policy(service), auto_unbox = TRUE)
  )
  iam$attach_role_policy(
    RoleName = name,
    PolicyArn = policy
  )
  return(role)
}

# Create a trust policy for an IAM role.
trust_policy <- function(service) {
  list(
    Version = "2012-10-17",
    Statement = list(
      list(
        Effect = "Allow",
        Principal = list(
          Service = sprintf("%s.amazonaws.com", service)
        ),
        Action = "sts:AssumeRole"
      )
    )
  )
}

