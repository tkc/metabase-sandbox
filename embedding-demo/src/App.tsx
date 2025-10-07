import { useCallback, useState } from 'react';
import { MetabaseProvider, Dashboard } from '@metabase/embedding-sdk-react';

const {
  VITE_METABASE_SITE_URL,
  VITE_METABASE_DASHBOARD_ID,
} = import.meta.env;

const siteUrl = VITE_METABASE_SITE_URL ?? 'http://localhost:3000';
const dashboardId = Number(VITE_METABASE_DASHBOARD_ID ?? '0');

function App() {
  const [jwtError, setJwtError] = useState<string | null>(null);

  const jwtProvider = useCallback(async () => {
    try {
      const response = await fetch('/api/metabase-embed-jwt', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          resource: { dashboard: dashboardId },
          params: {},
        }),
      });

      if (!response.ok) {
        throw new Error(
          `JWT request failed with status ${response.status}: ${response.statusText}`,
        );
      }

      const payload = (await response.json()) as { token?: string };
      if (!payload.token) {
        throw new Error('No token field in response payload.');
      }

      setJwtError(null);
      return payload.token;
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Unknown error requesting JWT';
      setJwtError(message);
      throw error;
    }
  }, []);

  const configValid = Boolean(siteUrl && dashboardId > 0);

  return (
    <div className="container">
      <header className="header">
        <h1>Metabase Embedding React Demo</h1>
        <p>This sample renders a Metabase dashboard using the Embedding SDK for React.</p>
      </header>

      {!configValid && (
        <div className="alert">
          <strong>Missing configuration.</strong> Update <code>.env.local</code> with the
          variables <code>VITE_METABASE_SITE_URL</code> and{' '}
          <code>VITE_METABASE_DASHBOARD_ID</code>.
        </div>
      )}

      {jwtError && (
        <div className="alert">
          <strong>JWT error:</strong> {jwtError}
        </div>
      )}

      {configValid ? (
        <MetabaseProvider host={siteUrl} jwtProvider={jwtProvider}>
          <div className="iframe-wrapper">
            <Dashboard
              id={dashboardId}
              height={600}
              LoadingState={
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    height: '100%',
                    fontWeight: 600,
                    color: '#475569',
                  }}
                >
                  Loading dashboard…
                </div>
              }
            />
          </div>
        </MetabaseProvider>
      ) : null}
    </div>
  );
}

export default App;
