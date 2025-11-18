const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const jwt = require('jsonwebtoken');

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const CONNECTIONS_TABLE = process.env.CONNECTIONS_TABLE;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

exports.handler = async (event) => {
  console.log('Connect event:', JSON.stringify(event, null, 2));
  
  try {
    const connectionId = event.requestContext.connectionId;
    const queryParams = event.queryStringParameters || {};
    const token = queryParams.token;
    
    if (!token) {
      return {
        statusCode: 401,
        body: JSON.stringify({ message: 'Authentication token required' })
      };
    }
    
    // Verify JWT token
    let decoded;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch (error) {
      console.error('JWT verification failed:', error);
      return {
        statusCode: 401,
        body: JSON.stringify({ message: 'Invalid or expired token' })
      };
    }
    
    const { userId, username, email } = decoded;
    
    // Store connection
    const timestamp = Date.now();
    const ttl = Math.floor(Date.now() / 1000) + (24 * 60 * 60); // 24 hours
    
    const putParams = {
      TableName: CONNECTIONS_TABLE,
      Item: {
        connectionId,
        userId,
        username,
        email,
        connectedAt: timestamp,
        ttl
      }
    };
    
    await docClient.send(new PutCommand(putParams));
    
    console.log(`Connection ${connectionId} stored for user ${userId}`);
    
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Connected successfully' })
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
