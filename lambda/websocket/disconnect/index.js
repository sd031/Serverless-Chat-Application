const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const CONNECTIONS_TABLE = process.env.CONNECTIONS_TABLE;

exports.handler = async (event) => {
  console.log('Disconnect event:', JSON.stringify(event, null, 2));
  
  try {
    const connectionId = event.requestContext.connectionId;
    
    // Delete connection
    const deleteParams = {
      TableName: CONNECTIONS_TABLE,
      Key: {
        connectionId
      }
    };
    
    await docClient.send(new DeleteCommand(deleteParams));
    
    console.log(`Connection ${connectionId} deleted`);
    
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Disconnected successfully' })
    };
    
  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ 
        message: 'Internal server error',
        error: error.message 
      })
    };
  }
};
