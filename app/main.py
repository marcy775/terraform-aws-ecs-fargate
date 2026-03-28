import time
import random
import logging
from fastapi import FastAPI, Response, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from prometheus_client import make_asgi_app, Counter, Histogram

# 1. Logs: 構造化ログ
logging.basicConfig(level=logging.INFO, format='{"time": "%(asctime)s", "level": "%(levelname)s", "message": "%(message)s"}')
logger = logging.getLogger(__name__)

app = FastAPI()

# HTMLテンプレートの設定
templates = Jinja2Templates(directory="templates")

# 2. Metrics: Prometheus形式のメトリクス定義
REQUEST_COUNT = Counter('app_request_count_total', 'Total HTTP Requests', ['method', 'endpoint', 'http_status'])
REQUEST_LATENCY = Histogram('app_request_latency_seconds', 'HTTP Request Latency', ['endpoint'])

# /metrics エンドポイントを追加
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

@app.get("/", response_class=HTMLResponse)
async def read_item(request: Request):
    """トップページ（RPG風UIを表示）"""
    return templates.TemplateResponse("index.html", {"request": request})

@app.get("/health")
def health_check():
    """ALBのヘルスチェック用エンドポイント"""
    return {"status": "ok"}

@app.get("/api/data")
def get_data(response: Response):
    """メインのAPI（意図的に遅延とエラーを発生させる）"""
    start_time = time.time()
    logger.info("API requested from frontend.")
    
    # トレース検証用：ランダムな処理遅延 (0.1秒 〜 1.0秒)
    time.sleep(random.uniform(0.1, 1.0))
    
    # 意図的なエラー (約20%の確率で500エラーを返す)
    if random.random() < 0.2:
        response.status_code = 500
        logger.error("Internal Server Error occurred during processing.")
        REQUEST_COUNT.labels('GET', '/api/data', 500).inc()
        REQUEST_LATENCY.labels('/api/data').observe(time.time() - start_time)
        return {"error": "Critical HIT! (Server Error)"}

    logger.info("Successfully processed the request.")
    REQUEST_COUNT.labels('GET', '/api/data', 200).inc()
    REQUEST_LATENCY.labels('/api/data').observe(time.time() - start_time)
    
    return {"message": "Data retrieved successfully!", "latency": f"{time.time() - start_time:.2f}s"}