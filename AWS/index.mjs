import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  BatchGetCommand,
  GetCommand
} from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});

const dynamo = DynamoDBDocumentClient.from(client);

export const handler = async (event, context) => {
  let body;
  let statusCode = 200;
  const headers = {
    "Content-Type": "application/json",
  };
  
  try {
    switch (event.resource) {
      case "/urnodes/{id}":
        body = await dynamo.send(
          new GetCommand({
            TableName: "urnodes",
            Key: {
              I: event.pathParameters.id,
            },
          })
        );
       body = body.Item;
        break;
        
      case "/urnodes":
        var input = {
          RequestItems: {
            urnodes: {
              Keys: []
            }
          }
        };
        const ids = event.multiValueQueryStringParameters.id;
        for (var i = 0; i < ids.length; ++i) {
          const key = {
            I: ids[i]
          };
          input.RequestItems.urnodes.Keys.push(key);
        }
        body = await dynamo.send(
          new BatchGetCommand(input)
          );
        body = body.Responses.urnodes
        break;

      default:
        throw new Error(`Unsupported resource: "${event.resource}"`);
    }
  } catch (err) {
    statusCode = 400;
    body = err.message;
  } finally {
    body = JSON.stringify(body);
  }

  return {
    statusCode,
    body,
    headers,
  };
};
