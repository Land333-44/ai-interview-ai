# Appwrite Functions — Smart Coach AI

Unified handler: **`analyze_session.js`** (text, audio, image, video).

Deploy **`analyze_session.js`** as the entrypoint for function `ai-interview-ai`.

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GROQ_API_KEY` | Yes | Groq API key |
| `GROQ_API_ENDPOINT` | No | Default: `https://api.groq.com/openai/v1/chat/completions` |
| `APPWRITE_API_KEY` | Yes* | For media download (*audio/image/video) |
| `APPWRITE_ENDPOINT` | Yes* | e.g. `https://fra.cloud.appwrite.io/v1` |
| `APPWRITE_PROJECT_ID` | Yes* | Your project ID |
| `APPWRITE_BUCKET_ID` | Yes* | Storage bucket ID (`6a11a23f0037ec3d8078`) |
| `HUME_API_KEY` | No | Optional Hume emotions |

## Request payload (Flutter → Function)

```json
{ "type": "text", "text": "I feel nervous before my interview" }
```

```json
{
  "type": "audio",
  "fileId": "...",
  "userId": "...",
  "fileName": "recording.m4a"
}
```

Same shape for `"type": "image"` and `"type": "video"`.

## Response

```json
{
  "success": true,
  "score": 78,
  "summary": "...",
  "feedback": { },
  "emotions": { "Confidence": 0.88 },
  "modality": "text"
}
```

## Pipelines

| Type | Pipeline |
|------|----------|
| **text** | Groq LLM → emotions → score |
| **audio** | Storage download → Groq Whisper → Groq + emotions |
| **image** | Storage download → Groq Vision |
| **video** | Storage metadata → Groq coaching (frame AI later) |

## Install dependencies before deploy

```bash
cd appwrite_functions && npm install
```
