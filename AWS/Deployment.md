# AWS Deployment Guide
1. Ensure Free Tier alerts are enabled.
2. Create zero-spend and monthly cost budgets.
3. Create the table in DynamoDB:
   - Run [Ur Solver](../Solver) to generate urSolution.data.
   - Run [DynamoDBGen](../DynamoDBGen) to convert the solution to a series of DynamoDB JSON files.
   - Compress the JSON files with [zstd](https://github.com/facebook/zstd).
   - Choose an appropriate region.
   - Upload the compressed files to an S3 bucket.
   - Import the files into a DynamoDB table named 'urnodes' with a partition key 'I' of type String.
   - Delete the compressed files from S3.
4. Create an IAM policy named [UrLambdaExecutionPolicy](UrLambdaExecutionPolicy.json).
5. Create an IAM role for the Lambda service named UrLambdaExecutionRole and add the above policy.
