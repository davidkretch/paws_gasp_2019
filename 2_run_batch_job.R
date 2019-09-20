# Run an example R job with Batch.
#
# Based on 'Creating a Simple "Fetch & Run" AWS Batch Job'
# https://aws.amazon.com/blogs/compute/creating-a-simple-fetch-and-run-aws-batch-job/

bucket <- "davidkretch"
filename <- "test.R"

#-------------------------------------------------------------------------------
# Upload the R script to S3 file storage.

s3 <- paws::s3()

conn <- file(filename, "rb")
contents <- readBin(conn, "raw", n = file.size(filename))

s3$put_object(
  Body = contents,
  Bucket = bucket,
  Key = filename
)

#-------------------------------------------------------------------------------
# Run the R script on Batch!

batch <- paws::batch()

batch$submit_job(
  jobName = "hello_world",
  jobQueue = "fetch_and_run_job_queue",
  jobDefinition = "fetch_and_run",
  containerOverrides = list(
    vcpus = 64,
    command = filename,
    environment = list(
      list(name = "BATCH_FILE_TYPE", value = "script"),
      list(name = "BATCH_FILE_S3_URL", value = sprintf("s3://%s/%s", bucket, filename))
    )
  )
)
