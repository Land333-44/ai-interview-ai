# Deploy `ai-interview-ai` to Appwrite

Your console shows **active deployment from GitHub** (`6a149393780662168918`).  
Flutter sends `{ type: "chat" | "text" | "audio" | ... }` — the **old** GitHub `main.js` only accepts `{ text }`, which causes empty or wrong responses.

## IDs (do not confuse)

| What | ID |
|------|-----|
| **Function** (use in Flutter `functionId`) | `6a142acd003e45e8cb2b` |
| Deployment (build only) | `6a149393780662168918` |
| Runtime URL | `https://6a142ace00114bc266e3.fra.appwrite.run/` |

## Option A — Update GitHub (recommended)

1. Copy this folder into repo [Land333-44/ai-interview-ai](https://github.com/Land333-44/ai-interview-ai):
   - `src/main.js` (from here)
   - `package.json` with `"type": "module"`
2. Commit and push to the branch Appwrite watches.
3. In Appwrite → **ai-interview-ai** → **Deployments** → **Create deployment** (or wait for auto-build).

## Option B — Manual upload

1. Zip `appwrite_functions/` (include `src/main.js`, `package.json`).
2. Appwrite → function → **Create deployment** → upload archive (not GitHub).

## Environment variables (function → Settings → Variables)

| Variable | Required |
|----------|----------|
| `GROQ_API_KEY` | Yes |
| `APPWRITE_API_KEY` | Yes (for audio/image/video) |
| `APPWRITE_ENDPOINT` | Yes e.g. `https://cloud.appwrite.io/v1` |
| `APPWRITE_PROJECT_ID` | Yes `6a10c9d5003b379b2981` |
| `APPWRITE_BUCKET_ID` | Yes `6a11a23f0037ec3d8078` |
| `APPWRITE_DATABASE_ID` | Yes `6a10d139002c0b99c416` |
| `ANALYSES_COLLECTION_ID` | Yes `analyses` |
| `CHAT_COLLECTION_ID` | Yes `chatmessages` |
| `HUME_API_KEY` | Optional |

API key scopes: `databases.read`, `databases.write` (for function DB save).

## Database columns (must match exactly)

**analyses:** `userId` string, `title` string, `status` string, `analysisType` string, `runDate` datetime, `note` string

**chatmessages:** `sessionId`, `userId`, `sender`, `messageText` string, `timestamp` datetime, `isRead` boolean, `messageType` string

## Collection permissions (Flutter)

Each collection → **Users** role: **Create**, **Read** (and **Update** for notifications `isRead`).

## Permissions

- Function: **Users** → Execute
- Storage bucket: **Users** → Create, Read

## Test payload (Executions tab)

```json
{"type":"chat","text":"Salam, bghit ntkallem 3la interview"}
```

Expected: `{ "success": true, "reply": "..." }`

```json
{"type":"text","text":"I am nervous about my presentation tomorrow."}
```

Expected: `{ "success": true, "data": { "groq": {...}, "hume": {...} } }`
