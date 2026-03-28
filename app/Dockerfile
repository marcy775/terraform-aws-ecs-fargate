# ベースイメージ
FROM python:3.11-slim as builder

WORKDIR /app

# 依存関係のインストール
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# 3. Traces: OpenTelemetryの自動計装パッケージをインストール
RUN pip install --no-cache-dir opentelemetry-distro opentelemetry-instrumentation-fastapi opentelemetry-exporter-otlp

# アプリケーションコードとテンプレートのコピー
COPY main.py .
COPY templates/ ./templates/

# 実行ユーザーを非rootに変更（セキュリティのベストプラクティス）
RUN useradd -m appuser
USER appuser

# ポートの公開（ALBからのトラフィックを受け取る）
EXPOSE 80

# OpenTelemetryでラップしてUvicornサーバーを起動
CMD ["opentelemetry-instrument", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]