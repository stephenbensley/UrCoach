# AWS Deployment Guide
1. Ensure Free Tier alerts are enabled
2. Create zero-spend and monthly cost budgets with e-mail alerts
3. Create the table in DynamoDB
   - Choose an appropriate region
   - Run Ur Solver to generate urSolution.data
   - Run DynamoDBGen to convert the solution to a series of JSON files.
   - Compress the JSON files with zstd.
   - Upload the compressed files to an S3 bucket.
   - Import the files into a DynamoDB table named 'urnodes' with a primary key of 'I'.
   - Delete the compressed files from S3.
