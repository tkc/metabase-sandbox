# metabase-sandbox

Docker と DuckDB を用いた、Metabase をローカルで試せる構成です。DuckDB はファイルベースの分析用データベースで、サンプル売上データを収録した `.duckdb` ファイルを Metabase から参照します。

## 前提

- Docker Desktop もしくは docker + docker compose が動作する環境
- `curl` と `jq`（ダッシュボード自動作成スクリプトで利用）

## セットアップ手順

1. DuckDB ファイルを生成
   ```bash
   make seed
   ```
   `duckdb/sample.duckdb` にサンプルデータが作成されます。
2. Metabase を起動
   ```bash
   make up
   ```
   ブラウザで `http://localhost:3000` を開き、管理者アカウントの初期設定を完了させます。
3. DuckDB を Metabase に登録  
   Metabase の管理画面から「データベースを追加」→「DuckDB」を選択し、以下の値を入力します。
   - Database file: `/app/duckdb/sample.duckdb`  
     その他の設定は既定のままで構いません。

## ダッシュボードの自動作成（任意）

API 経由で接続設定・カード・ダッシュボードを生成するには以下を実行します。

```bash
export MB_EMAIL="admin@example.com"   # Metabase で作成した管理者メール
export MB_PASSWORD="your_password"    # そのパスワード

make bootstrap
```

完了すると Metabase 上に以下が作成されます。

- DuckDB の Sample Sales データベース接続（既存の場合は再利用）
- 「Monthly Revenue」「Top Customers」の 2 つのカード
- カードを配置した「Sales Overview」ダッシュボード

## 停止・クリーンアップ

- 停止: `make down`
- 状態確認: `make status`
- ログ閲覧: `make logs`
- ボリュームも含めて削除: `make clean`
- DuckDB ファイルのみ再生成: `make seed`

## Embedding React デモ

Metabase の [Embedding SDK](https://www.metabase.com/docs/latest/embedding/sdk/introduction) を使った React サンプルを `embedding-demo/` に用意しています。Metabase の「アプリに埋め込み」機能を有効にし、埋め込みシークレットと埋め込み用ダッシュボード ID を取得した上で以下を実施してください。

1. 依存関係のインストール（Bun 使用）
   ```bash
   cd embedding-demo
   cp .env.example .env.local
   bun install
   ```
   `.env.local` の `METABASE_EMBED_SECRET` とダッシュボード ID を実際の値に更新します（Vite 用 `VITE_` 付き変数も同じ値に揃えてください）。
2. 署名サーバーを起動
   ```bash
   bun run server
   ```
   4000 番ポートで `/api/metabase-embed-jwt` エンドポイントが立ち上がり、埋め込みトークンを生成します。
3. 別ターミナルでフロントエンドを起動
   ```bash
   bun run dev
   ```
   ブラウザで `http://localhost:5173` を開くと、Metabase のダッシュボードが React コンポーネントとしてレンダリングされます。

コード整形は `bun run format`、lint チェックは `bun run lint` で実行できます。

必要に応じて `METABASE_SITE_URL` をホストに合わせて変更してください。Metabase が Basic 認証や VPN の裏にある場合は、署名サーバーからアクセス可能であることを確認してください。

## 構成ファイル概要

- `Makefile`: docker-compose やスクリプトをラップする操作コマンド
- `docker-compose.yml`: Metabase コンテナとボリューム設定
- `duckdb/seed.sql`: サンプルデータ作成用 SQL
- `scripts/seed_duckdb.sh`: DuckDB ファイルを Docker 経由で生成
- `scripts/bootstrap_metabase_content.sh`: Metabase API でカードとダッシュボードを自動作成
- `embedding-demo/`: React + Vite 製の埋め込みデモ（フロントエンドと署名サーバー）
