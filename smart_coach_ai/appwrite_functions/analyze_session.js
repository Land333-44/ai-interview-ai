/**
 * Unified Appwrite Function: text | audio | image | video
 * Env: GROQ_API_KEY, GROQ_API_ENDPOINT,
 *      APPWRITE_API_KEY, APPWRITE_ENDPOINT, APPWRITE_PROJECT_ID, APPWRITE_BUCKET_ID,
 *      HUME_API_KEY (optional)
 */
import { Client, Storage } from 'node-appwrite';
import { saveAnalysis, saveChatMessage } from './db_save.js';

function getBody(req) {
  try {
    if (typeof req.payload === 'string' && req.payload.trim()) {
      return JSON.parse(req.payload);
    }
    if (req.payload && typeof req.payload === 'object') return req.payload;
    if (req.bodyJson && typeof req.bodyJson === 'object') return req.bodyJson;
    if (typeof req.body === 'string' && req.body.trim()) {
      return JSON.parse(req.body);
    }
    if (req.body && typeof req.body === 'object') return req.body;
  } catch (_) {}
  return {};
}

export default async function (req, res) {
  try {
    const body = getBody(req);

    const type = (body.type || 'text').toLowerCase();
    const groqKey = process.env.GROQ_API_KEY;
    const groqEndpoint = process.env.GROQ_API_ENDPOINT
      || 'https://api.groq.com/openai/v1/chat/completions';

    if (!groqKey) {
      return res.json({ success: false, error: 'Missing GROQ_API_KEY' });
    }

    if (type === 'chat') {
      const message = String(body.text || body.message || '').trim();
      if (!message) {
        return res.json({ success: false, error: 'Missing chat message' });
      }
      const chatResult = await chatWithCoach(groqKey, groqEndpoint, message, body.history);
      if (chatResult.success && body.userId) {
        const sid = body.sessionId || `session_${body.userId}`;
        await saveChatMessage({
          sessionId: sid,
          userId: body.userId,
          sender: 'user',
          messageText: message,
        });
        const aiText = (chatResult.reply || chatResult.summary || '').trim();
        if (aiText) {
          await saveChatMessage({
            sessionId: sid,
            userId: body.userId,
            sender: 'ai',
            messageText: aiText,
          });
        }
      }
      return res.json(chatResult);
    }

    let textForAnalysis = '';

    if (type === 'text') {
      textForAnalysis = String(body.text || '').trim();
      if (!textForAnalysis) {
        return res.json({ success: false, error: 'Missing text' });
      }
      const textOnly = await analyzeTextPipeline(
        groqKey,
        groqEndpoint,
        textForAnalysis,
        'text',
      );
      if (textOnly.success && body.userId) {
        const scorePart = textOnly.score ? `Score: ${textOnly.score} — ` : '';
        await saveAnalysis({
          userId: body.userId,
          title: body.title || 'Text session',
          analysisType: 'text',
          note: `${scorePart}${textOnly.summary || ''}`.trim(),
        });
      }
      return res.json(textOnly);
    } else {
      const fileId = body.fileId;
      const userId = body.userId;
      if (!fileId) {
        return res.json({ success: false, error: 'Missing fileId for media analysis' });
      }

      const fileBuffer = await downloadStorageFile(fileId);
      if (!fileBuffer) {
        return res.json({ success: false, error: 'Could not download file from storage' });
      }

      if (type === 'audio') {
        textForAnalysis = await transcribeAudio(fileBuffer, body.fileName || 'audio.m4a');
        if (!textForAnalysis) {
          return res.json({ success: false, error: 'Audio transcription failed' });
        }
      } else if (type === 'image') {
        return res.json(await analyzeImage(groqKey, groqEndpoint, fileBuffer, body.fileName));
      } else if (type === 'video') {
        return res.json(await analyzeVideo(groqKey, groqEndpoint, fileId, userId, body.fileName));
      } else {
        return res.json({ success: false, error: `Unknown type: ${type}` });
      }
    }

    const pipelineResult = await analyzeTextPipeline(
      groqKey,
      groqEndpoint,
      textForAnalysis,
      type,
    );
    if (pipelineResult.success && body.userId) {
      const scorePart = pipelineResult.score
        ? `Score: ${pipelineResult.score} — `
        : '';
      await saveAnalysis({
        userId: body.userId,
        title: body.title || `${type} session`,
        analysisType: type,
        note: `${scorePart}${pipelineResult.summary || ''}`.trim(),
      });
    }
    return res.json(pipelineResult);
  } catch (error) {
    return res.json({
      success: false,
      error: error?.message || 'Unknown function error',
    });
  }
}

async function downloadStorageFile(fileId) {
  const endpoint = process.env.APPWRITE_ENDPOINT;
  const projectId = process.env.APPWRITE_PROJECT_ID;
  const apiKey = process.env.APPWRITE_API_KEY;
  const bucketId = process.env.APPWRITE_BUCKET_ID;

  if (!endpoint || !projectId || !apiKey || !bucketId) {
    console.error('Missing Appwrite storage env vars');
    return null;
  }

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);

  const storage = new Storage(client);
  const arrayBuffer = await storage.getFileDownload(bucketId, fileId);
  return Buffer.from(arrayBuffer);
}

async function transcribeAudio(buffer, fileName) {
  const groqKey = process.env.GROQ_API_KEY;
  const form = new FormData();
  const blob = new Blob([buffer], { type: 'audio/m4a' });
  form.append('file', blob, fileName.endsWith('.m4a') ? fileName : 'audio.m4a');
  form.append('model', 'whisper-large-v3');
  form.append('language', 'en');

  const whisperRes = await fetch(
    'https://api.groq.com/openai/v1/audio/transcriptions',
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${groqKey}` },
      body: form,
    },
  );

  if (!whisperRes.ok) {
    console.error('Whisper error', await whisperRes.text());
    return null;
  }

  const json = await whisperRes.json();
  return json.text || '';
}

async function analyzeImage(groqKey, groqEndpoint, buffer, fileName) {
  const base64 = buffer.toString('base64');
  const mime = guessImageMime(fileName);

  const groqRes = await fetch(groqEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${groqKey}`,
    },
    body: JSON.stringify({
      model: 'llama-3.2-11b-vision-preview',
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: 'You are a public speaking coach. Analyze this image for posture, expression, professionalism, and presence. Reply JSON only: summary, strengths[], improvements[].',
            },
            {
              type: 'image_url',
              image_url: { url: `data:${mime};base64,${base64}` },
            },
          ],
        },
      ],
      temperature: 0.4,
    }),
  });

  if (!groqRes.ok) {
    const err = await groqRes.text();
    return { success: false, error: `Vision API failed: ${err}` };
  }

  const groqJson = await groqRes.json();
  const content = groqJson?.choices?.[0]?.message?.content || '';
  const parsed = parseJsonFromContent(content);
  const summary = parsed.summary || content.slice(0, 300);
  const emotions = heuristicEmotions(summary);

  return {
    success: true,
    score: computeScore(summary, emotions),
    summary,
    feedback: parsed,
    emotions,
    modality: 'image',
  };
}

async function analyzeVideo(groqKey, groqEndpoint, fileId, userId, fileName) {
  const prompt = `You are a public speaking coach. The user uploaded a video practice file (${fileName || 'recording'}, id: ${fileId}). Provide coaching on video delivery: eye contact, pacing, gestures, energy, and structure. Reply JSON only: summary, strengths[], improvements[].`;

  const groqRes = await fetch(groqEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${groqKey}`,
    },
    body: JSON.stringify({
      model: 'llama-3.1-8b-instant',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.5,
    }),
  });

  if (!groqRes.ok) {
    return { success: false, error: await groqRes.text() };
  }

  const groqJson = await groqRes.json();
  const content = groqJson?.choices?.[0]?.message?.content || '';
  const parsed = parseJsonFromContent(content);
  const summary = parsed.summary || 'Video session analyzed.';
  const emotions = heuristicEmotions(summary);

  return {
    success: true,
    score: computeScore(summary, emotions),
    summary,
    feedback: { ...parsed, note: 'Frame-by-frame vision coming in a future update.' },
    emotions,
    modality: 'video',
  };
}

async function chatWithCoach(groqKey, groqEndpoint, message, history) {
  const system = `You are Smart Coach AI, a friendly expert coach for interviews, presentations, and public speaking.
Reply in the same language the user uses (French, English, or Arabic/Darija).
Be specific to what they said. Keep answers 2-5 sentences.
Do NOT start with generic phrases like "Great question" unless they asked a real question.
If they greet you (hi, salam, hy), greet back and ask what they want to practice.`;

  const messages = [{ role: 'system', content: system }];
  if (Array.isArray(history)) {
    history.slice(-6).forEach((h) => {
      if (h?.role && h?.content) {
        messages.push({ role: h.role, content: String(h.content) });
      }
    });
  }
  messages.push({ role: 'user', content: message });

  const groqRes = await fetch(groqEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${groqKey}`,
    },
    body: JSON.stringify({
      model: 'llama-3.1-8b-instant',
      messages,
      temperature: 0.7,
    }),
  });

  if (!groqRes.ok) {
    return { success: false, error: await groqRes.text() };
  }

  const groqJson = await groqRes.json();
  const reply = groqJson?.choices?.[0]?.message?.content?.trim()
    || 'Sorry, I could not generate a reply.';

  return {
    success: true,
    summary: reply,
    reply,
    score: 0,
    emotions: {},
    modality: 'chat',
  };
}

async function analyzeTextPipeline(groqKey, groqEndpoint, text, modality) {
  const prompt = `You are a public speaking coach. Analyze this ${modality} content for clarity, tone, confidence, and delivery. Reply JSON only: summary (2 sentences), strengths[], improvements[].\n\nText:\n${text}`;

  const groqRes = await fetch(groqEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${groqKey}`,
    },
    body: JSON.stringify({
      model: 'llama-3.1-8b-instant',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.4,
    }),
  });

  if (!groqRes.ok) {
    return { success: false, error: await groqRes.text() };
  }

  const groqJson = await groqRes.json();
  const content = groqJson?.choices?.[0]?.message?.content || '';
  const parsed = parseJsonFromContent(content);
  const emotions = heuristicEmotions(text);

  return {
    success: true,
    score: computeScore(text, emotions),
    summary: parsed.summary || 'Analysis complete.',
    feedback: { ...parsed, transcript: modality === 'audio' ? text : undefined },
    emotions,
    modality,
  };
}

function parseJsonFromContent(content) {
  try {
    const match = content.match(/\{[\s\S]*\}/);
    if (match) return JSON.parse(match[0]);
  } catch (_) {}
  return { summary: content };
}

function guessImageMime(name) {
  const n = (name || '').toLowerCase();
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.webp')) return 'image/webp';
  if (n.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

function heuristicEmotions(text) {
  const lower = text.toLowerCase();
  const nervous = (lower.match(/\b(nervous|anxious|worried|afraid)\b/g) || []).length;
  const confident = (lower.match(/\b(confident|sure|ready|excited|proud)\b/g) || []).length;
  const stress = (lower.match(/\b(stress|pressure|hard|difficult)\b/g) || []).length;
  const words = text.split(/\s+/).filter(Boolean).length;
  const base = Math.min(1, words / 200);

  return {
    Confidence: Math.min(0.95, 0.45 + confident * 0.08 + base * 0.2),
    Nervousness: Math.min(0.9, 0.2 + nervous * 0.1),
    Excitement: Math.min(0.9, 0.35 + confident * 0.05),
    Stress: Math.min(0.85, 0.15 + stress * 0.12),
    Sadness: Math.min(0.5, 0.08 + (lower.includes('sad') ? 0.25 : 0)),
  };
}

function computeScore(text, emotions) {
  const words = text.split(/\s+/).filter(Boolean).length;
  const lengthScore = Math.min(40, words / 5);
  const confidence = (emotions.Confidence || 0.5) * 40;
  const stressPenalty = (emotions.Stress || 0) * 15;
  return Math.round(
    Math.min(100, Math.max(0, lengthScore + confidence + 25 - stressPenalty)),
  );
}
