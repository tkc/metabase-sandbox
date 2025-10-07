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

## 構成ファイル概要

- `Makefile`: docker-compose やスクリプトをラップする操作コマンド
- `docker-compose.yml`: Metabase コンテナとボリューム設定
- `duckdb/seed.sql`: サンプルデータ作成用 SQL
- `scripts/seed_duckdb.sh`: DuckDB ファイルを Docker 経由で生成
- `scripts/bootstrap_metabase_content.sh`: Metabase API でカードとダッシュボードを自動作成
