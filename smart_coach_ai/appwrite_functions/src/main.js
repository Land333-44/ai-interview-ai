import { Client, Storage, Databases, ID } from "node-appwrite";

// Appwrite client is initialized lazily inside the handler
// so missing env vars return a proper error instead of a 503 crash.
let storage;
let databases;

function getAppwriteClient(log) {
  const endpoint = process.env.APPWRITE_ENDPOINT;
  const projectId = process.env.APPWRITE_PROJECT_ID;
  const apiKey   = process.env.APPWRITE_API_KEY;

  if (log) {
    log("APPWRITE_ENDPOINT: " + (endpoint || "MISSING"));
    log("APPWRITE_PROJECT_ID length: " + (projectId?.length ?? 0));
    log("APPWRITE_API_KEY length: "   + (apiKey?.length   ?? 0));
  }

  if (!endpoint || !projectId || !apiKey) {
    return null;
  }

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);

  storage   = new Storage(client);
  databases = new Databases(client);
  return client;
}

// ======================
// MAIN FUNCTION
// ======================

export default async ({ req, res, log }) => {
  try {
    log("START FUNCTION");

    // Initialize Appwrite client (logs env var status)
    getAppwriteClient(log);

    // ======================
    // BODY
    // ======================

    const body =
      typeof req.body === "string"
        ? JSON.parse(req.body)
        : req.body || {};

    const type = (body.type || "text").toLowerCase();

    const GROQ_API_KEY = process.env.GROQ_API_KEY;
    const HUME_API_KEY = process.env.HUME_API_KEY;

    log("GROQ_API_KEY length: " + (GROQ_API_KEY?.length ?? 0));

    if (!GROQ_API_KEY) {
      return res.json({
        success: false,
        error: "Missing GROQ_API_KEY"
      });
    }

    // ======================
    // CHAT MODE
    // ======================

    if (type === "chat") {
      const message = body.text || body.message;

      if (!message) {
        return res.json({
          success: false,
          error: "Missing chat message"
        });
      }

      const chatResult = await groqChat(
        GROQ_API_KEY,
        message
      );

      return res.json(chatResult);
    }

    // ======================
    // TEXT MODE
    // ======================

    if (type === "text") {
      const text = body.text;

      if (!text) {
        return res.json({
          success: false,
          error: "Missing text"
        });
      }

      const analysis = await analyzeText(
        GROQ_API_KEY,
        HUME_API_KEY,
        text,
        log
      );

      // SAVE CHAT
      await saveChat(body, text);

      // SAVE ANALYSIS
      await saveAnalysis(body, analysis);

      return res.json({
        success: true,
        data: analysis
      });
    }

    // ======================
    // AUDIO MODE
    // ======================

    if (type === "audio") {
      const fileId = body.fileId;

      if (!fileId) {
        return res.json({
          success: false,
          error: "Missing fileId"
        });
      }

      const transcript =
        "Audio transcription placeholder";

      const analysis = await analyzeText(
        GROQ_API_KEY,
        HUME_API_KEY,
        transcript,
        log
      );

      return res.json({
        success: true,
        transcript,
        data: analysis
      });
    }

    // ======================
    // IMAGE MODE
    // ======================

    if (type === "image") {
      return res.json({
        success: true,
        message: "Image analysis ready"
      });
    }

    // ======================
    // VIDEO MODE
    // ======================

    if (type === "video") {
      return res.json({
        success: true,
        message: "Video analysis ready"
      });
    }

    // ======================
    // UNKNOWN TYPE
    // ======================

    return res.json({
      success: false,
      error: `Unknown type: ${type}`
    });

  } catch (error) {
    return res.json({
      success: false,
      error: error.message
    });
  }
};

// ======================
// GROQ CHAT
// ======================

async function groqChat(apiKey, message) {

  const response = await fetch(
    "https://api.groq.com/openai/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "llama-3.1-8b-instant",
        messages: [
          {
            role: "system",
            content:
              "You are Smart Interview AI Coach."
          },
          {
            role: "user",
            content: message
          }
        ],
        temperature: 0.7
      })
    }
  );

  console.log("GROQ CHAT STATUS:", response.status);

  const raw = await response.text();
  console.log("GROQ CHAT RAW:", raw.substring(0, 500));

  let json = {};
  try {
    json = JSON.parse(raw);
  } catch {
    return {
      success: false,
      error: "Groq chat returned non-JSON: " + raw.substring(0, 200)
    };
  }

  if (!response.ok) {
    return {
      success: false,
      error: json?.error?.message || `Groq error ${response.status}`
    };
  }

  return {
    success: true,
    reply:
      json?.choices?.[0]?.message?.content ||
      "No response"
  };
}

// ======================
// ANALYZE TEXT
// ======================

async function analyzeText(
  GROQ_API_KEY,
  HUME_API_KEY,
  text,
  log
) {

  // ======================
  // GROQ
  // ======================

  log("GROQ KEY EXISTS: " + !!GROQ_API_KEY);
  log("GROQ KEY LENGTH: " + (GROQ_API_KEY?.length ?? 0));

  const groqRes = await fetch(
    "https://api.groq.com/openai/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${GROQ_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "llama-3.1-8b-instant",
        messages: [
          {
            role: "system",
            content:
              "Return ONLY valid JSON."
          },
          {
            role: "user",
            content: `
Analyze this interview answer:

"""${text}"""

Return JSON:
{
  "summary": "",
  "strengths": [],
  "weaknesses": [],
  "improvements": [],
  "score": 0,
  "better_answer": "",
  "next_question": ""
}
`
          }
        ],
        temperature: 0.2,
        max_tokens: 700
      })
    }
  );

  log("GROQ STATUS: " + groqRes.status);

  const groqRawText = await groqRes.text();
  log("GROQ RAW RESPONSE: " + groqRawText.substring(0, 500));

  let groqJson = {};
  try {
    groqJson = JSON.parse(groqRawText);
  } catch {
    return {
      input: text,
      groq: { error: "Groq returned non-JSON: " + groqRawText.substring(0, 200) },
      hume: null
    };
  }

  if (!groqRes.ok) {
    return {
      input: text,
      groq: { error: groqJson?.error?.message || `Groq error ${groqRes.status}` },
      hume: null
    };
  }

  const groqRaw =
    groqJson?.choices?.[0]?.message?.content || "{}";

  log("GROQ CONTENT:");
  log(groqRaw);

  const groq = safeParse(groqRaw);

  // ======================
  // HUME
  // ======================

  let humeResult = null;

  if (HUME_API_KEY) {

    try {

      const humeStart = await fetch(
        "https://api.hume.ai/v0/batch/jobs",
        {
          method: "POST",
          headers: {
            "X-Hume-Api-Key": HUME_API_KEY,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            models: {
              language: {
                granularity: "word"
              }
            },
            texts: [text]
          })
        }
      );

      const humeJob = await humeStart.json();

      const job_id = humeJob?.job_id;

      if (job_id) {

        await sleep(3000);

        const humeRes = await fetch(
          `https://api.hume.ai/v0/batch/jobs/${job_id}`,
          {
            method: "GET",
            headers: {
              "X-Hume-Api-Key": HUME_API_KEY
            }
          }
        );

        humeResult = await humeRes.json();
      }

    } catch (e) {
      log("HUME ERROR:");
      log(e.message);
    }
  }

  return {
    input: text,
    groq,
    hume: humeResult
  };
}

// ======================
// SAVE CHAT
// ======================

async function saveChat(body, text) {

  try {

    if (!process.env.DATABASE_ID) return;

    await databases.createDocument(
      process.env.DATABASE_ID,
      process.env.CHAT_COLLECTION_ID,
      ID.unique(),
      {
        sessionId:
          body.sessionId || "default",

        userId:
          body.userId || "unknown",

        sender: "user",

        messageText: text,

        timestamp:
          new Date().toISOString(),

        isRead: false,

        messageType: "text"
      }
    );

  } catch (e) {
    console.log(e.message);
  }
}

// ======================
// SAVE ANALYSIS
// ======================

async function saveAnalysis(body, analysis) {

  try {

    if (!process.env.DATABASE_ID) return;

    await databases.createDocument(
      process.env.DATABASE_ID,
      process.env.ANALYSES_COLLECTION_ID,
      ID.unique(),
      {
        userId:
          body.userId || "unknown",

        title: "Interview Analysis",

        status: "completed",

        analysisType: "AI",

        runDate:
          new Date().toISOString(),

        note:
          JSON.stringify(analysis.groq)
      }
    );

  } catch (e) {
    console.log(e.message);
  }
}

// ======================
// SAFE PARSER
// ======================

function safeParse(raw) {

  try {

    const match =
      raw.match(/\{[\s\S]*\}/);

    return match
      ? JSON.parse(match[0])
      : {};

  } catch {

    return {
      summary: "parse_error",
      strengths: [],
      weaknesses: [],
      improvements: [],
      score: 0
    };
  }
}

// ======================
// SLEEP
// ======================

function sleep(ms) {
  return new Promise(resolve =>
    setTimeout(resolve, ms)
  );
}
