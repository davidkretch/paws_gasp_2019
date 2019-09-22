# Using Amazon Web Services with R

This presentation shows how you can use Amazon Web Services (AWS) in R with
the Paws package. The Paws package provides access to 150+ services on AWS.

One use case is to run large, complex analyses on a dedicated server. The 
example code here runs an R script on a large server which starts on command
and stops when done using AWS Batch.

The example is based on the 
[Creating a Simple "Fetch & Run" AWS Batch Job](https://aws.amazon.com/blogs/compute/creating-a-simple-fetch-and-run-aws-batch-job/)
blog post written by Amazon.

This presentation was prepared for the Government Advances in Statistical
Programming (GASP!) conference, held on September 23, 2019 in Washington DC.

## Summary

1. Install Paws.
2. Make a Docker container.
3. Set up AWS Batch.
4. Run an R job on Batch!

## 1. Install Paws

Run `install.packages("paws")` to install from CRAN.

If you are using Linux, you'll need to install development packages for 
cURL, OpenSSL, and libxml2. In Debian/Ubuntu, install `libcurl4-openssl-dev`, 
`libssl-dev`, and `libxml2-dev`.

The example also assumes that you have AWS credentials saved in OS environment
variables or in a shared credentials file. See 
[this document](https://github.com/paws-r/paws/blob/master/docs/credentials.md) for more info on authenticating with AWS.

## 2. Make a Docker container

Your batch job runs in a Docker container, which a self-contained environment 
with an OS and other software, such as R. The example in this repo uses a
pre-built Docker container with has R installed, which is hosted on Docker Hub.

You can make your own Docker container using the Dockerfile in the `docker`
folder. The 
[Creating a Simple "Fetch & Run" AWS Batch Job](https://aws.amazon.com/blogs/compute/creating-a-simple-fetch-and-run-aws-batch-job/) 
blog post shows how to do that.

## 3. Set up AWS Batch

To use Batch, you must set up a compute environment (e.g. max CPUs), a job queue, 
and a job definition (e.g. what container to use). See [the user guide](https://docs.aws.amazon.com/batch/latest/userguide/what-is-batch.html) for more info.

The script `1_aws_batch_setup.R` will create these for you.

You can also follow the instructions in [Creating a Simple "Fetch & Run" AWS Batch Job](https://aws.amazon.com/blogs/compute/creating-a-simple-fetch-and-run-aws-batch-job/).

## Run an R job on Batch

The example in `2_run_batch_job.R` copies an R script to an S3 file storage
bucket, then runs an AWS Batch job which fetches the R script and runs it.

## Other resources

`install.packages("paws")` - install Paws from CRAN.

[Paws home page](https://paws-r.github.io) - See online documentation.

[GitHub](https://www.github.com/paws-r/paws) - See getting started guide and
examples; submit issues.
