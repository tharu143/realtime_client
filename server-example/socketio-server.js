const { Server } = require("socket.io");
const { v4: uuidv4 } = require("uuid");

const io = new Server(3000, {
  cors: {
    origin: "*",
  }
});

// In-memory store: clientId -> { messages: [], lastAck: 0 }
const clients = new Map();

console.log("Socket.IO server running on port 3000");

io.on("connection", (socket) => {
  console.log("New connection:", socket.id);

  // Identify client
  let clientId = null;

  socket.on("message", (msg) => {
    // msg is the JSON object
    console.log("Received:", msg);

    if (!msg || !msg.type) return;

    if (msg.type === "resume") {
      clientId = msg.client_id;
      const lastAck = msg.last_ack_seq || 0;
      console.log(`Client ${clientId} resuming from ${lastAck}`);

      if (!clients.has(clientId)) {
        clients.set(clientId, { messages: [], lastAck: 0 });
      }
      
      const clientData = clients.get(clientId);
      
      // Find missing messages
      const missing = clientData.messages.filter(m => m.seq > lastAck);
      
      // Send resume response
      const response = {
        type: "resume_response",
        server_ack_seq: clientData.lastAck, // The last seq we received from client (not tracked in this simple example, assuming we ack immediately)
        missing: missing,
        timestamp: new Date().toISOString()
      };
      socket.emit("message", response);
      
    } else if (msg.type === "event") {
      clientId = msg.client_id;
      if (!clientId) return;

      if (!clients.has(clientId)) {
        clients.set(clientId, { messages: [], lastAck: 0 });
      }
      const clientData = clients.get(clientId);

      // Update last received seq from client
      if (msg.seq) {
        clientData.lastAck = Math.max(clientData.lastAck, msg.seq);
      }

      // Send ACK
      if (msg.seq) {
        socket.emit("message", {
          type: "ack",
          ack_seq: msg.seq,
          client_id: clientId,
          timestamp: new Date().toISOString()
        });
      }

      // Echo back as a new message (simulation) or broadcast
      // For this test, we'll just log.
      // If we want to simulate server sending messages, we can do it here.
      
    } else if (msg.type === "ack") {
      // Client acked our message
      // We could remove from our queue
    }
  });

  socket.on("disconnect", () => {
    console.log("Disconnected:", socket.id);
  });
});

// Simulate sending messages to client
setInterval(() => {
  clients.forEach((data, id) => {
    // Randomly send a message
    if (Math.random() > 0.9) {
      // We need to find a socket for this client. 
      // In this simple example, we don't map clientId to socketId easily without extra logic.
      // We'll skip unsolicited server messages for now unless requested.
    }
  });
}, 1000);
