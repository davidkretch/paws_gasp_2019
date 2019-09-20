# Set up AWS Batch to run R jobs.
#
# Based on 'Creating a Simple "Fetch & Run" AWS Batch Job'
# https://aws.amazon.com/blogs/compute/creating-a-simple-fetch-and-run-aws-batch-job/

#-------------------------------------------------------------------------------
# Get the default networking info to set up the Batch compute environment.

ec2 <- paws::ec2()

default_vpc <- ec2$describe_vpcs(
  Filters = "isDefault=true"
)$Vpcs[[1]]

security_group <- ec2$describe_security_groups(
  Filters = sprintf("vpc-id=%s", default_vpc$VpcId),
  GroupNames = "default"
)$SecurityGroups[[1]]

subnets <- ec2$describe_subnets(
  Filters = sprintf("vpc-id=%s", default_vpc$VpcId)
)$Subnets


#-------------------------------------------------------------------------------
# Create an IAM role for Batch.

role_name <- "AWSBatchServiceRole"
policy_arn <- "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"

trust_policy <- list(
  Version = "2012-10-17",
  Statement = list(
    list(
      Effect = "Allow",
      Principal = list(
        Service = "batch.amazonaws.com"
      ),
      Action = "sts:AssumeRole"
    )
  )
)

iam <- paws::iam()

if (role_name %in% sapply(iam$list_roles()$Roles, function(x) x$RoleName)) {
  role <- iam$get_role(role_name)
} else {
  role <- iam$create_role(
    RoleName = role_name,
    AssumeRolePolicyDocument = jsonlite::toJSON(trust_policy, auto_unbox = TRUE)
  )
  iam$attach_role_policy(
    RoleName = role_name,
    PolicyArn = policy_arn
  )
}


#-------------------------------------------------------------------------------
# Create the Batch compute environment, job queue, and job definition.

batch <- paws::batch()

# The compute environment: the resources on which Batch jobs will run.
batch$create_compute_environment(
  type = "MANAGED",
  computeEnvironmentName = "fetch_and_run_compute_environment",
  computeResources = list(
    type = "EC2",
    desiredvCpus = 1L,
    ec2KeyPair = "default",
    instanceRole = "ecsInstanceRole",
    instanceTypes = "optimal",
    maxvCpus = 128L,
    minvCpus = 0L,
    securityGroupIds = security_group$GroupId,
    subnets = sapply(subnets, function(x) x$SubnetId)
  ),
  serviceRole = role$Role$Arn,
  state = "ENABLED"
)

# The job queue for the compute environment.
batch$create_job_queue(
  computeEnvironmentOrder = list(
    list(
      computeEnvironment = "fetch_and_run_compute_environment",
      order = 1L
    )
  ),
  jobQueueName = "fetch_and_run_job_queue",
  priority = 1L,
  state = "ENABLED"
)

#-------------------------------------------------------------------------------
# Create the fetch & run job definition.

# TODO: Create the IAM role.
role <- iam$get_role("ecs_fetch_and_run")

job_def <- batch$register_job_definition(
  type = "container",
  containerProperties = list(
    image = "davidkretch/fetch_and_run",
    vcpus = 1L,
    memory = 128L,
    jobRoleArn = role$Role$Arn
  ),
  jobDefinitionName = "fetch_and_run"
)
