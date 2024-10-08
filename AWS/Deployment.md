# AWS Deployment Guide
1. Ensure Free Tier alerts are enabled.
2. Create zero-spend and monthly cost budgets.
3. Create the table in DynamoDB:
   - Run [Ur Solver](../UrSolver) to generate urSolution.data.
   - Run [DynamoDBGen](../DynamoDBGen) to convert the solution to a series of DynamoDB JSON files.
   - Compress the JSON files with [zstd](https://github.com/facebook/zstd).
   - Choose an appropriate region.
   - Upload the compressed files to an S3 bucket.
   - Import the files into a DynamoDB table named 'urnodes' with a partition key 'I' of type String.
   - Delete the compressed files from S3.
4. Create an IAM policy named [UrLambdaExecutionPolicy](UrLambdaExecutionPolicy.json).
5. Create an IAM role named UrLambdaExecutionRole for a Lambda service and attach the above policy.
6. Create the Lambda function:
   - Create a function named QueryUrNodes.
   - Set the runtime to node.js.
   - Change the default execution role to the role created above.
   - Copy/paste the code from [index.mjs](index.mjs).
   - Deploy the function.
7. Create the API in API Gateway:
   - Build a REST API named UrNodes.
   - Create two resources:
     - urnodes under /
     - {id} under /urnodes/
   - For each resource, create a GET method integrated with the Lambda function created above.
   - Enable Lambda proxy integration for both methods.
   - Deploy the API to a stage named prod.
   - Create an API key named UrAPIKey.
   - Create a usage plan named UrAPIUsage.
     - Set Rate, Burst, and Quota appropriately.
     - Associate the API key created above.
     - Associate the stage used to deploy the API.
8. Update [AWSConfig.swift](../Core/AWSConfig.swift.txt) with the API parameters.
9. Run [CloudDBClientTests](../CoreTests/CloudDBClientTests.swift) to validate the deployment.
