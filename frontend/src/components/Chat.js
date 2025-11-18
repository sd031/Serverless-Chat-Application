import React, { useState, useEffect, useRef } from 'react';
import './Chat.css';
import config from '../config';

function Chat({ user, token, onLogout }) {
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState('');
  const [ws, setWs] = useState(null);
  const [connected, setConnected] = useState(false);
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  useEffect(() => {
    // Connect to WebSocket
    const websocketUrl = `${config.WEBSOCKET_URL}?token=${token}`;
    const websocket = new WebSocket(websocketUrl);

    websocket.onopen = () => {
      console.log('WebSocket connected');
      setConnected(true);
      
      // Request message history
      websocket.send(JSON.stringify({
        action: 'getMessages',
        roomId: 'general'
      }));
    };

    websocket.onmessage = (event) => {
      const data = JSON.parse(event.data);
      console.log('WebSocket message:', data);

      if (data.action === 'messages') {
        setMessages(data.messages);
      } else if (data.action === 'newMessage') {
        setMessages(prev => [...prev, data.message]);
      }
    };

    websocket.onerror = (error) => {
      console.error('WebSocket error:', error);
      setConnected(false);
    };

    websocket.onclose = () => {
      console.log('WebSocket disconnected');
      setConnected(false);
    };

    setWs(websocket);

    return () => {
      if (websocket.readyState === WebSocket.OPEN) {
        websocket.close();
      }
    };
  }, [token]);

  const sendMessage = (e) => {
    e.preventDefault();
    
    if (!inputMessage.trim() || !ws || ws.readyState !== WebSocket.OPEN) {
      return;
    }

    ws.send(JSON.stringify({
      action: 'sendMessage',
      message: inputMessage.trim(),
      roomId: 'general'
    }));

    setInputMessage('');
  };

  const formatTime = (timestamp) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('en-US', { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  };

  return (
    <div className="chat-container">
      <div className="chat-header">
        <div className="chat-header-left">
          <h2>Serverless Chat</h2>
          <span className={`status ${connected ? 'connected' : 'disconnected'}`}>
            {connected ? '● Connected' : '○ Disconnected'}
          </span>
        </div>
        <div className="chat-header-right">
          <span className="username">👤 {user.username}</span>
          <button onClick={onLogout} className="logout-button">
            Logout
          </button>
        </div>
      </div>

      <div className="messages-container">
        {messages.length === 0 ? (
          <div className="no-messages">
            <p>No messages yet. Start the conversation!</p>
          </div>
        ) : (
          messages.map((msg, index) => (
            <div
              key={msg.messageId || index}
              className={`message ${msg.userId === user.userId ? 'own-message' : 'other-message'}`}
            >
              <div className="message-header">
                <span className="message-username">{msg.username}</span>
                <span className="message-time">{formatTime(msg.timestamp)}</span>
              </div>
              <div className="message-content">{msg.message}</div>
            </div>
          ))
        )}
        <div ref={messagesEndRef} />
      </div>

      <form onSubmit={sendMessage} className="message-input-container">
        <input
          type="text"
          value={inputMessage}
          onChange={(e) => setInputMessage(e.target.value)}
          placeholder="Type a message..."
          className="message-input"
          disabled={!connected}
        />
        <button 
          type="submit" 
          className="send-button"
          disabled={!connected || !inputMessage.trim()}
        >
          Send
        </button>
      </form>
    </div>
  );
}

export default Chat;
