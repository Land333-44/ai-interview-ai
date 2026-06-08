import { Client, Storage, Databases, ID } from "node-appwrite";

let storage;
let databases;

function getAppwriteClient(log) {
  const endpoint  = process.env.APPWRITE_ENDPOINT;
  const projectId = process.env.APPWRITE_PROJECT_ID;
  const apiKey    = process.env.APPWRITE_API_KEY;

  if (log) {
    log("APPWRITE_ENDPOINT: "    + (endpoint   || "MISSING"));
    log("APPWRITE_PROJECT_ID: "  + (projectId  || "MISSING"));
    log("APPWRITE_API_KEY len: " + (apiKey?.length ?? 0));
  }

  if (!endpoint || !projectId || !apiKey) return null;

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);

  storage   = new Storage(client);
  databases = new Databases(client);
  return client;
}

// ─── MAIN HANDLER ────────────────────────────────────────────────────────────

export default async ({ req, res, log }) => {
  try {
    log("START FUNCTION");
    getAppwriteClient(log);

    const body =
      typeof req.body === "string"
        ? JSON.parse(req.body)
        : req.body || {};

    const type     = (body.type || "text").toLowerCase();
    const language = body.language || "fr";
    const scenario = body.scenario || "interview";

    const GROQ_API_KEY = process.env.GROQ_API_KEY;
    const HUME_API_KEY = process.env.HUME_API_KEY;

    log("type: " + type + " | language: " + language + " | scenario: " + scenario);
    log("GROQ_API_KEY len: " + (GROQ_API_KEY?.length ?? 0));

    if (!GROQ_API_KEY) {
      return res.json({ success: false, error: "Missing GROQ_API_KEY" });
    }

    // ── CHAT ─────────────────────────────────────────────────────────────────
    if (type === "chat") {
      const message = body.text || body.message;
      const history = body.history || [];

      if (!message) {
        return res.json({ success: false, error: "Missing chat message" });
      }

      const chatResult = await groqChat(GROQ_API_KEY, message, history, language, scenario, log);

      if (chatResult.success) {
        await saveChatMessage(body, message, "user");
        await saveChatMessage(body, chatResult.reply, "ai");
      }

      return res.json(chatResult);
    }

    // ── TEXT ─────────────────────────────────────────────────────────────────
    if (type === "text") {
      const text = body.text?.trim();
      if (!text) return res.json({ success: false, error: "Missing text" });

      const result = await analyzeText(GROQ_API_KEY, HUME_API_KEY, text, language, scenario, log);

      await saveChatMessage(body, text, "user");
      await saveAnalysis(body, result);

      return res.json({ success: true, ...result });
    }

    // ── AUDIO ─────────────────────────────────────────────────────────────────
    if (type === "audio") {
      const fileId = body.fileId;
      if (!fileId) return res.json({ success: false, error: "Missing fileId" });

      const transcript = await transcribeAudio(fileId, GROQ_API_KEY, log);
      if (!transcript) {
        return res.json({ success: false, error: "Transcription échouée" });
      }

      const result = await analyzeText(GROQ_API_KEY, HUME_API_KEY, transcript, language, scenario, log);

      await saveAnalysis(body, result);

      return res.json({
        success: true,
        ...result,
        feedback: { ...result.feedback, transcript },
        modality: "audio",
      });
    }

    // ── IMAGE ─────────────────────────────────────────────────────────────────
    if (type === "image") {
      return res.json({
        success: false,
        error: "L'analyse d'image n'est pas encore disponible.",
      });
    }

    // ── VIDEO ─────────────────────────────────────────────────────────────────
    if (type === "video") {
      return res.json({
        success: false,
        error: "L'analyse vidéo n'est pas encore disponible.",
      });
    }

    return res.json({ success: false, error: `Type inconnu: ${type}` });

  } catch (error) {
    return res.json({ success: false, error: error.message });
  }
};

// ─── GROQ CHAT ───────────────────────────────────────────────────────────────

async function groqChat(apiKey, message, history, language, scenario, log) {
  const systemPrompt = buildSystemPrompt(language, scenario);

  const messages = [
    { role: "system", content: systemPrompt },
    ...history.map(h => ({ role: h.role || "user", content: h.content || h.text || "" })),
    { role: "user", content: message },
  ];

  const response = await fetchWithTimeout(
    "https://api.groq.com/openai/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages,
        temperature: 0.7,
        max_tokens: 500,
      }),
    },
    20000
  );

  log("GROQ CHAT STATUS: " + response.status);
  const raw = await response.text();

  let json = {};
  try { json = JSON.parse(raw); } catch {
    return { success: false, error: "Groq chat non-JSON: " + raw.substring(0, 200) };
  }

  if (!response.ok) {
    return { success: false, error: json?.error?.message || `Groq error ${response.status}` };
  }

  return {
    success: true,
    reply: json?.choices?.[0]?.message?.content || "Pas de réponse",
  };
}

// ─── ANALYZE TEXT ─────────────────────────────────────────────────────────────

async function analyzeText(GROQ_API_KEY, HUME_API_KEY, text, language, scenario, log) {
  const langLabel = language === "fr" ? "français" : "English";

  const groqRes = await fetchWithTimeout(
    "https://api.groq.com/openai/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${GROQ_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [
          {
            role: "system",
            content: `Tu es un coach expert en ${scenario}. Réponds uniquement en JSON valide, en ${langLabel}.`,
          },
          {
            role: "user",
            content: `Analyse cette réponse de ${scenario} :

"""${text}"""

Retourne UNIQUEMENT ce JSON (score de 0 à 100) :
{
  "summary": "résumé court",
  "score": 0,
  "strengths": ["point fort 1", "point fort 2"],
  "weaknesses": ["point faible 1"],
  "improvements": ["conseil 1", "conseil 2"],
  "better_answer": "exemple de meilleure réponse",
  "next_question": "prochaine question suggérée"
}`,
          },
        ],
        temperature: 0.2,
        max_tokens: 800,
      }),
    },
    20000
  );

  log("GROQ ANALYZE STATUS: " + groqRes.status);
  const groqRawText = await groqRes.text();
  log("GROQ RAW: " + groqRawText.substring(0, 300));

  let groqJson = {};
  try { groqJson = JSON.parse(groqRawText); } catch {
    return buildErrorResult(text, "Groq returned non-JSON");
  }

  if (!groqRes.ok) {
    return buildErrorResult(text, groqJson?.error?.message || `Groq error ${groqRes.status}`);
  }

  const groqContent = groqJson?.choices?.[0]?.message?.content || "{}";
  const parsed = safeParse(groqContent);

  // ── HUME emotions ────────────────────────────────────────────────────────
  let emotions = {};

  if (HUME_API_KEY) {
    try {
      emotions = await getHumeEmotions(HUME_API_KEY, text, log);
    } catch (e) {
      log("HUME ERROR: " + e.message);
    }
  }

  // ── Format final attendu par le frontend ─────────────────────────────────
  return {
    score:    Math.min(100, Math.max(0, parsed.score || 0)),
    summary:  parsed.summary  || "",
    modality: "text",
    feedback: {
      strengths:   parsed.strengths   || [],
      weaknesses:  parsed.weaknesses  || [],
      improvements: parsed.improvements || [],
      better_answer: parsed.better_answer || "",
      next_question: parsed.next_question || "",
    },
    emotions,
  };
}

// ─── TRANSCRIBE AUDIO (Groq Whisper) ─────────────────────────────────────────

async function transcribeAudio(fileId, groqApiKey, log) {
  try {
    if (!storage) { log("Storage not initialized"); return null; }

    log("Downloading file: " + fileId);
    const bucketId = process.env.BUCKET_ID || process.env.APPWRITE_BUCKET_ID;
    if (!bucketId) { log("BUCKET_ID missing"); return null; }

    const fileBuffer = await storage.getFileDownload(bucketId, fileId);
    const blob = new Blob([fileBuffer]);

    const formData = new FormData();
    formData.append("file", blob, "audio.m4a");
    formData.append("model", "whisper-large-v3-turbo");
    formData.append("response_format", "text");

    const response = await fetchWithTimeout(
      "https://api.groq.com/openai/v1/audio/transcriptions",
      {
        method: "POST",
        headers: { Authorization: `Bearer ${groqApiKey}` },
        body: formData,
      },
      30000
    );

    log("WHISPER STATUS: " + response.status);
    if (!response.ok) return null;

    const transcript = await response.text();
    log("TRANSCRIPT: " + transcript.substring(0, 200));
    return transcript.trim() || null;

  } catch (e) {
    log("TRANSCRIBE ERROR: " + e.message);
    return null;
  }
}

// ─── HUME EMOTIONS ───────────────────────────────────────────────────────────

async function getHumeEmotions(apiKey, text, log) {
  try {
    const startRes = await fetchWithTimeout(
      "https://api.hume.ai/v0/batch/jobs",
      {
        method: "POST",
        headers: {
          "X-Hume-Api-Key": apiKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          models: { language: { granularity: "sentence" } },
          texts: [text],
        }),
      },
      8000
    );

    const rawStart = await startRes.text();
    log("HUME START RAW: " + rawStart.substring(0, 200));

    let jobData = {};
    try { jobData = JSON.parse(rawStart); } catch { return {}; }

    const job_id = jobData?.job_id;
    if (!job_id) { log("HUME: no job_id"); return {}; }

    log("HUME JOB: " + job_id);

    // Poll up to 5 times (4s apart) — check status before fetching predictions
    for (let i = 0; i < 5; i++) {
      await sleep(4000);

      // 1. Check job status
      const statusRes = await fetchWithTimeout(
        `https://api.hume.ai/v0/batch/jobs/${job_id}`,
        { method: "GET", headers: { "X-Hume-Api-Key": apiKey } },
        8000
      );
      const rawStatus = await statusRes.text();
      let statusData = {};
      try { statusData = JSON.parse(rawStatus); } catch {}
      const jobStatus = statusData?.state?.status;
      log("HUME STATUS " + i + ": " + jobStatus);

      if (jobStatus !== "completed") continue;

      // 2. Fetch predictions only when completed
      const pollRes = await fetchWithTimeout(
        `https://api.hume.ai/v0/batch/jobs/${job_id}/predictions`,
        { method: "GET", headers: { "X-Hume-Api-Key": apiKey } },
        8000
      );
      const rawPoll = await pollRes.text();
      log("HUME PREDICTIONS: " + rawPoll.substring(0, 300));

      let predictions = [];
      try { predictions = JSON.parse(rawPoll); } catch { break; }

      const emotions = extractHumeEmotions(predictions);
      if (Object.keys(emotions).length > 0) return emotions;
      break;
    }
  } catch (e) {
    log("HUME EXCEPTION: " + e.message);
  }

  return {};
}

function extractHumeEmotions(predictions) {
  try {
    const emotions = {};
    const results  = predictions?.[0]?.results?.predictions?.[0]?.models?.language?.grouped_predictions;
    if (!results) return {};

    const entries = results[0]?.predictions?.[0]?.emotions || [];
    const top = entries
      .sort((a, b) => b.score - a.score)
      .slice(0, 6);

    for (const e of top) {
      emotions[e.name.toLowerCase()] = parseFloat(e.score.toFixed(3));
    }
    return emotions;
  } catch {
    return {};
  }
}

// ─── SAVE HELPERS ────────────────────────────────────────────────────────────

async function saveChatMessage(body, text, sender) {
  try {
    const dbId   = process.env.DATABASE_ID;
    const colId  = process.env.CHAT_COLLECTION_ID;
    if (!dbId || !colId || !databases) return;

    await databases.createDocument(dbId, colId, ID.unique(), {
      sessionId:   body.sessionId || "default",
      userId:      body.userId    || "unknown",
      sender,
      messageText: text,
      timestamp:   new Date().toISOString(),
      isRead:      false,
      messageType: "text",
    });
  } catch (e) {
    console.log("saveChat error: " + e.message);
  }
}

async function saveAnalysis(body, result) {
  try {
    const dbId  = process.env.DATABASE_ID;
    const colId = process.env.ANALYSES_COLLECTION_ID;
    if (!dbId || !colId || !databases) return;

    await databases.createDocument(dbId, colId, ID.unique(), {
      userId:       body.userId  || "unknown",
      title:        body.title   || "Session Analysis",
      status:       "complete",
      analysisType: "quick",
      runDate:      new Date().toISOString(),
      note:         JSON.stringify(result.feedback || {}).substring(0, 490),
      fileId:       body.fileId  || "",
    });
  } catch (e) {
    console.log("saveAnalysis error: " + e.message);
  }
}

// ─── UTILITIES ───────────────────────────────────────────────────────────────

function buildSystemPrompt(language, scenario) {
  const lang = language === "fr" ? "français" : "English";
  return `Tu es Smart Coach AI, un coach expert en ${scenario}. Réponds toujours en ${lang}. Sois encourageant, précis et constructif.`;
}

function buildErrorResult(text, errorMsg) {
  return {
    score:    0,
    summary:  errorMsg,
    modality: "text",
    feedback: { strengths: [], weaknesses: [], improvements: [] },
    emotions: {},
  };
}

function fetchWithTimeout(url, options, timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  return fetch(url, { ...options, signal: controller.signal })
    .finally(() => clearTimeout(timer));
}

function safeParse(raw) {
  try {
    const match = raw.match(/\{[\s\S]*\}/);
    return match ? JSON.parse(match[0]) : {};
  } catch {
    return {};
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
