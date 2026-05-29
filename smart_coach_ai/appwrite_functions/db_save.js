/**
 * Save rows to Appwrite Database (server API key).
 * Env: APPWRITE_ENDPOINT, APPWRITE_PROJECT_ID, APPWRITE_API_KEY,
 *      APPWRITE_DATABASE_ID, ANALYSES_COLLECTION_ID, CHAT_COLLECTION_ID
 */
import { Client, Databases, ID } from 'node-appwrite';

function dbClient() {
  const endpoint = process.env.APPWRITE_ENDPOINT;
  const projectId = process.env.APPWRITE_PROJECT_ID;
  const apiKey = process.env.APPWRITE_API_KEY;
  if (!endpoint || !projectId || !apiKey) return null;
  return new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
}

async function saveAnalysis({ userId, title, analysisType, note, status = 'completed' }) {
  const databaseId = process.env.APPWRITE_DATABASE_ID;
  const collectionId =
    process.env.ANALYSES_COLLECTION_ID || 'analyses';
  const client = dbClient();
  if (!client || !databaseId || !userId) return null;

  const databases = new Databases(client);
  const doc = await databases.createDocument(
    databaseId,
    collectionId,
    ID.unique(),
    {
      userId: String(userId),
      title: title || 'Session',
      status,
      analysisType: analysisType || 'text',
      runDate: new Date().toISOString(),
      note: note || '',
    },
  );
  return doc.$id;
}

async function saveChatMessage({
  sessionId,
  userId,
  sender,
  messageText,
  messageType = 'text',
}) {
  const databaseId = process.env.APPWRITE_DATABASE_ID;
  const collectionId =
    process.env.CHAT_COLLECTION_ID || 'chatmessages';
  const client = dbClient();
  if (!client || !databaseId || !userId || !messageText) return null;

  const databases = new Databases(client);
  const doc = await databases.createDocument(
    databaseId,
    collectionId,
    ID.unique(),
    {
      sessionId: sessionId || `session_${userId}`,
      userId: String(userId),
      sender,
      messageText,
      timestamp: new Date().toISOString(),
      isRead: sender === 'ai',
      messageType,
    },
  );
  return doc.$id;
}

export { saveAnalysis, saveChatMessage };
