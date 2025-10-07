import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import jwt from 'jsonwebtoken';

const app = express();

const PORT = Number(process.env.SERVER_PORT || 4000);
const METABASE_SITE_URL = process.env.METABASE_SITE_URL || 'http://localhost:3000';
const METABASE_EMBED_SECRET = process.env.METABASE_EMBED_SECRET;
const METABASE_DASHBOARD_ID = Number(process.env.METABASE_DASHBOARD_ID || '0');

app.use(cors());
app.use(express.json());

if (!METABASE_EMBED_SECRET) {
  console.warn(
    '[embedding-demo] METABASE_EMBED_SECRET is not set. JWT requests will fail until it is provided.',
  );
}

app.get('/healthz', (_req, res) => {
  res.json({ ok: true });
});

app.post('/api/metabase-embed-jwt', (req, res) => {
  if (!METABASE_EMBED_SECRET || METABASE_DASHBOARD_ID <= 0) {
    res.status(500).json({
      error:
        'Server is missing METABASE_EMBED_SECRET or METABASE_DASHBOARD_ID configuration.',
    });
    return;
  }

  const resource = req.body?.resource || { dashboard: METABASE_DASHBOARD_ID };
  const params = req.body?.params || {};

  const payload = {
    resource,
    params,
    exp: Math.round(Date.now() / 1000) + 10 * 60,
  };

  try {
    const token = jwt.sign(payload, METABASE_EMBED_SECRET);
    res.json({ token, host: METABASE_SITE_URL });
  } catch (error) {
    console.error('[embedding-demo] Failed to sign token', error);
    res.status(500).json({ error: 'Failed to sign token' });
  }
});

app.listen(PORT, () => {
  console.log(
    `[embedding-demo] Metabase embedding helper server listening on http://localhost:${PORT}`,
  );
});
