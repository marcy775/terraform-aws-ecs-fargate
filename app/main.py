import time
import random
import logging
from fastapi import FastAPI, Response, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from prometheus_client import make_asgi_app, Counter, Histogram
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.extension.aws.trace import AwsXRayIdGenerator
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# 1. Logs: 構造化ログ
logging.basicConfig(level=logging.INFO, format='{"time": "%(asctime)s", "level": "%(levelname)s", "message": "%(message)s"}')
logger = logging.getLogger(__name__)

# 2. X-Ray (ADOT) トレーシング設定
resource = Resource(attributes={"service.name": "ecs-portfolio-fastapi"})
trace.set_tracer_provider(
    TracerProvider(
        id_generator=AwsXRayIdGenerator(),
        resource=resource
    )
)

# 出力先を「隣にいるADOTコンテナ」のポート4317(gRPC)に変更
otlp_exporter = OTLPSpanExporter(endpoint="http://localhost:4317", insecure=True)
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)

app = FastAPI()

# FastAPIとRequestsライブラリを自動計測
FastAPIInstrumentor.instrument_app(app)
RequestsInstrumentor().instrument()

tracer = trace.get_tracer(__name__)

# HTML画像
app.mount("/static", StaticFiles(directory="static"), name="static")

# HTMLテンプレートの設定
templates = Jinja2Templates(directory="templates")

# /metrics エンドポイントを追加
REQUEST_COUNT = Counter('app_request_count_total', 'Total HTTP Requests', ['method', 'endpoint', 'http_status'])
REQUEST_LATENCY = Histogram('app_request_latency_seconds', 'HTTP Request Latency', ['endpoint'])
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

    # データベースからモンスター情報を取得する（フリ）
    with tracer.start_as_current_span("db_select_monster") as span:
        # スパンに独自のタグ（属性）をつけることも可能！
        span.set_attribute("db.system", "mysql")
        span.set_attribute("monster.type", "red_dragon")
        time.sleep(random.uniform(0.1, 0.4)) # 0.1〜0.4秒かかる

    # 外部APIに攻撃のダメージ計算を依頼する（フリ）
    with tracer.start_as_current_span("api_calculate_damage") as span:
        time.sleep(random.uniform(0.1, 0.4)) # 0.1〜0.4秒かかる
        
        # 意図的なエラー (約20%の確率で500エラー)
        if random.random() < 0.2:
            response.status_code = 500
            logger.error("Internal Server Error occurred during processing.")
            
            # スパンにも「ここでエラーが起きたぞ！」と記録する
            span.set_attribute("error", True)
            span.set_attribute("error.message", "Critical HIT! (Server Error)")
            
            REQUEST_COUNT.labels('GET', '/api/data', 500).inc()
            REQUEST_LATENCY.labels('/api/data').observe(time.time() - start_time)
            return {"error": "Critical HIT! (Server Error)"}
    
    # トレース検証用：ランダムな処理遅延 (0.1秒 〜 1.0秒)
    time.sleep(random.uniform(0.1, 1.0))
    
    # 意図的なエラー (約20%の確率で500エラーを返す)
    # if random.random() < 0.2:
    #     response.status_code = 500
    #     logger.error("Internal Server Error occurred during processing.")
    #     REQUEST_COUNT.labels('GET', '/api/data', 500).inc()
    #     REQUEST_LATENCY.labels('/api/data').observe(time.time() - start_time)
    #     return {"error": "Critical HIT! (Server Error)"}

    logger.info("Successfully processed the request.")
    REQUEST_COUNT.labels('GET', '/api/data', 200).inc()
    REQUEST_LATENCY.labels('/api/data').observe(time.time() - start_time)
    
    return {"message": "Data retrieved successfully!", "latency": f"{time.time() - start_time:.2f}s"}