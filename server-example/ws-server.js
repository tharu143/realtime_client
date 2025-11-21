const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

const wss = new WebSocket.Server({ port: 3001 });

// In-memory store: clientId -> { messages: [], lastAck: 0 }
const clients = new Map();

console.log("WebSocket server running on port 3001");

wss.on('connection', function connection(ws) {
    console.log('New connection');

    ws.on('message', function incoming(message) {
        try {
            const msg = JSON.parse(message);
            console.log('Received:', msg);

            if (!msg.type) return;

            if (msg.type === 'resume') {
                const clientId = msg.client_id;
                const lastAck = msg.last_ack_seq || 0;
                console.log(`Client ${clientId} resuming from ${lastAck}`);

                if (!clients.has(clientId)) {
                    clients.set(clientId, { messages: [], lastAck: 0 });
                }

                const clientData = clients.get(clientId);
                const missing = clientData.messages.filter(m => m.seq > lastAck);

                const response = {
                    type: 'resume_response',
                    server_ack_seq: clientData.lastAck,
                    missing: missing,
                    timestamp: new Date().toISOString()
                };
                ws.send(JSON.stringify(response));

            } else if (msg.type === 'event') {
                const clientId = msg.client_id;
                if (!clientId) return;

                if (!clients.has(clientId)) {
                    clients.set(clientId, { messages: [], lastAck: 0 });
                }
                const clientData = clients.get(clientId);

                if (msg.seq) {
                    clientData.lastAck = Math.max(clientData.lastAck, msg.seq);

                    // Send ACK
                    ws.send(JSON.stringify({
                        type: 'ack',
                        ack_seq: msg.seq,
                        client_id: clientId,
                        timestamp: new Date().toISOString()
                    }));
                }
            } else if (msg.type === 'meta') {
                if (msg.event === 'ping') {
                    // Respond with pong (or just ignore if using standard WS ping/pong frames, but we implemented app level)
                    // Actually, standard WS has ping/pong frames. 
                    // But our client sends a meta/ping message.
                    // We should reply if we want to support the app-level heartbeat.
                    // But for now, let's assume the client handles the lack of response by reconnecting, 
                    // or we send a pong.
                }
            }
        } catch (e) {
            console.error('Error parsing message:', e);
        }
    });
});
