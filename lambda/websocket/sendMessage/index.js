const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');
const { v4: uuidv4 } = require('uuid');

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const MESSAGES_TABLE = process.env.MESSAGES_TABLE;
const CONNECTIONS_TABLE = process.env.CONNECTIONS_TABLE;

exports.handler = async (event) => {
  console.log('Send message event:', JSON.stringify(event, null, 2));
  
  try {
    const connectionId = event.requestContext.connectionId;
    const body = JSON.parse(event.body);
    const { message, roomId = 'general' } = body;
    
    if (!message) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Message content is required' })
      };
    }
    
    // Get connection details
    const getParams = {
      TableName: CONNECTIONS_TABLE,
      Key: {
        connectionId
      }
    };
    
    const connectionResult = await docClient.send(new GetCommand(getParams));
    
    if (!connectionResult.Item) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'Connection not found' })
      };
    }
    
    const { userId, username } = connectionResult.Item;
    
    // Store message
    const messageId = uuidv4();
    const timestamp = Date.now();
    
    const putParams = {
      TableName: MESSAGES_TABLE,
      Item: {
        messageId,
        roomId,
        userId,
        username,
        message,
        timestamp
      }
    };
    
    await docClient.send(new PutCommand(putParams));
    
    console.log(`Message ${messageId} stored for user ${userId}`);
    
    return {
      statusCode: 200,
      body: JSON.stringify({ 
        message: 'Message sent successfully',
        messageId,
        timestamp
      })
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
