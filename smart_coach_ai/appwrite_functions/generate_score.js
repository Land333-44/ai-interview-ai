export default async function (req, res) {
  try {
    const body = typeof req.payload === 'string'
      ? JSON.parse(req.payload || '{}')
      : req.payload || {};

    const analysisData = body.analysisData || body;

    if (!analysisData) {
      return res.json({
        success: false,
        error: 'Missing required analysis data',
      });
    }

    // Basic scoring stub. Replace with your own model or business rules.
    const score = Math.min(100, Math.max(0, Math.round(
      (analysisData.length || 0) / 2,
    )));

    return res.json({
      success: true,
      score,
      summary: 'Generated a simple quality score using analysis payload.',
      analysisData,
    });
  } catch (error) {
    return res.json({
      success: false,
      error: error?.message || 'Unknown function error',
    });
  }
};
