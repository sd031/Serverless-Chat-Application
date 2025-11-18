const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand } = require('@aws-sdk/lib-dynamodb');
const { ApiGatewayManagementApiClient, PostToConnectionCommand } = require('@aws-sdk/client-apigatewaymanagementapi');

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const MESSAGES_TABLE = process.env.MESSAGES_TABLE;

exports.handler = async (event) => {
  console.log('Get messages event:', JSON.stringify(event, null, 2));
  
  try {
    const connectionId = event.requestContext.connectionId;
    const body = JSON.parse(event.body);
    const { roomId = 'general', limit = 50 } = body;
    
    // Query messages
    const queryParams = {
      TableName: MESSAGES_TABLE,
      IndexName: 'RoomIndex',
      KeyConditionExpression: 'roomId = :roomId',
      ExpressionAttributeValues: {
        ':roomId': roomId
      },
      ScanIndexForward: false,
      Limit: limit
    };
    
    const result = await docClient.send(new QueryCommand(queryParams));
    
    const messages = (result.Items || []).reverse();
    
    // Send messages back through WebSocket
    const endpoint = event.requestContext.domainName + '/' + event.requestContext.stage;
    const apiGatewayClient = new ApiGatewayManagementApiClient({ 
      endpoint: `https://${endpoint}`
    });
    
    const postParams = {
      ConnectionId: connectionId,
      Data: JSON.stringify({
        action: 'messages',
        messages
      })
    };
    
    await apiGatewayClient.send(new PostToConnectionCommand(postParams));
    
    console.log(`Sent ${messages.length} messages to connection ${connectionId}`);
    
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Messages retrieved successfully' })
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
