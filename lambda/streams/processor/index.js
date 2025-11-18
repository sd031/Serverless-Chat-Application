const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');
const { ApiGatewayManagementApiClient, PostToConnectionCommand } = require('@aws-sdk/client-apigatewaymanagementapi');
const { unmarshall } = require('@aws-sdk/util-dynamodb');

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const CONNECTIONS_TABLE = process.env.CONNECTIONS_TABLE;
const WEBSOCKET_API_ENDPOINT = process.env.WEBSOCKET_API_ENDPOINT;

exports.handler = async (event) => {
  console.log('Stream event:', JSON.stringify(event, null, 2));
  
  try {
    // Extract endpoint from WebSocket URL
    const endpoint = WEBSOCKET_API_ENDPOINT.replace('wss://', '').replace('ws://', '');
    
    const apiGatewayClient = new ApiGatewayManagementApiClient({ 
      endpoint: `https://${endpoint}`
    });
    
    // Process each record from DynamoDB Stream
    for (const record of event.Records) {
      if (record.eventName === 'INSERT') {
        // Get the new message
        const newMessage = unmarshall(record.dynamodb.NewImage);
        
        console.log('New message:', newMessage);
        
        // Get all active connections
        const scanParams = {
          TableName: CONNECTIONS_TABLE
        };
        
        const connections = await docClient.send(new ScanCommand(scanParams));
        
        // Broadcast message to all connections
        const postCalls = (connections.Items || []).map(async (connection) => {
          try {
            const postParams = {
              ConnectionId: connection.connectionId,
              Data: JSON.stringify({
                action: 'newMessage',
                message: {
                  messageId: newMessage.messageId,
                  roomId: newMessage.roomId,
                  userId: newMessage.userId,
                  username: newMessage.username,
                  message: newMessage.message,
                  timestamp: newMessage.timestamp
                }
              })
            };
            
            await apiGatewayClient.send(new PostToConnectionCommand(postParams));
            console.log(`Message sent to connection ${connection.connectionId}`);
            
          } catch (error) {
            if (error.statusCode === 410) {
              // Connection is stale, delete it
              console.log(`Stale connection ${connection.connectionId}, will be cleaned up by TTL`);
            } else {
              console.error(`Error sending to connection ${connection.connectionId}:`, error);
            }
          }
        });
        
        await Promise.all(postCalls);
      }
    }
    
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Stream processed successfully' })
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
