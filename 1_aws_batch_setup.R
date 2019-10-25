# Set up AWS Batch to run R jobs.
#
# Based on 'Creating a Simple "Fetch & Run" AWS Batch Job'
# https://aws.amazon.com/blogs/compute/creating-a-simple-fetch-and-run-aws-batch-job/

source("0_helpers.R")


#-------------------------------------------------------------------------------
# Create Identity & Access Management (IAM) roles for Batch.

# Service role for AWS Batch.
# AWS will create this role for you if you use the management console wizard.
service_role <- create_or_get_role(
  name = "AWSBatchServiceRole",
  service = "batch",
  policy = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
)

# Role for Elastic Container Service running on EC2.
# AWS will create this role for you if you use the management console wizard.
instance_role <- create_or_get_role(
  name = "ecsInstanceRole",
  service = "ec2",
  policy = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
)

instance_profile <- create_or_get_instance_profile("ecsInstanceRole")


#-------------------------------------------------------------------------------
# Create the Batch compute environment, job queue, and job definition.

batch <- paws::batch()

ec2_info <- get_ec2_info()

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
    securityGroupIds = ec2_info$security_group,
    subnets = ec2_info$subnets
  ),
  serviceRole = service_role$Role$Arn,
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
# A job definition specifies a Docker container that will run a batch process.

job_role <- create_or_get_role(
  name = "ecs_fetch_and_run",
  service = "ecs-tasks",
  policy = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
)

# This job definition uses a Docker container retrieved from Docker Hub.
job_def <- batch$register_job_definition(
  type = "container",
  containerProperties = list(
    image = "davidkretch/fetch_and_run", # from Docker Hub
    vcpus = 1L,
    memory = 128L,
    jobRoleArn = job_role$Role$Arn
  ),
  jobDefinitionName = "fetch_and_run"
)
