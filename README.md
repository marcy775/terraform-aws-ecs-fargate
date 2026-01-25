# Terraform × AWS ECS Fargate ポートフォリオ

未経験からSREを目指すために作成した、AWS ECS (Fargate) のインフラ構築リポジトリです。    
チュートリアルをなぞるだけではなく、「現場で使えるレベルとは何か？」を考え、    
**Stateの排他制御**や**CI/CDの完全自動化,セキュリティtfsec / OIDC**にこだわって実装しました。

---

## 🏗 アーキテクチャ
<img width="1435" height="613" alt="image" src="https://github.com/user-attachments/assets/22bab105-834e-4391-8342-3ed3887a1367" />

---

## 🛠 技術スタック

| カテゴリ | 詳細 |
| :--- | :--- |
| **IaC** | Terraform v1.14.2 (Module設計) |
| **Compute** | Amazon ECS (Fargate) |
| **Container Registry** | Amazon ECR |
| **Network** | VPC, Public/Private Subnet, ALB, VPC Endpoints |
| **CI/CD** | GitHub Actions (GitOps) |
| **Security** | IAM (Least Privilege), OIDC, tfsec |
| **Observability** | CloudWatch (Logs, Metrics, Alarm), SNS |
| **State Management** | Amazon S3 + DynamoDB (State Lock) |

---

## 💰 想定コスト試算 (Monthly Cost Estimation)
個人開発レベルのトラフィックを想定し、セキュリティとコストのバランスを最適化した月額試算です。
NAT Gateway（約 $30/月）を廃止し、VPCエンドポイントを活用することで固定費を抑えています。

| Service | Spec / Configuration | Cost | Note |
| :--- | :--- | :--- | :--- |
| **ALB** | Application Load Balancer | $18.00 | 常時稼働 |
| **Fargate** | 0.25 vCPU / 0.5 GB Mem | $10.00 | 2タスク稼働想定 |
| **VPC Endpoints** | Interface Type (x3) | $25.00 | ECR(api/dkr), Logs用 |
| **CloudWatch** | Logs & Metrics | $3.00 | ログ量に依存 |
| **Others** | S3, DynamoDB, ECR, Data Transfer | $2.00 | 従量課金 |
| **Total** | | **~$58.00 / month** | **NAT GW利用時より約30%削減** |

---

## 🧠 技術選定の背景

### Compute: なぜ EC2 ではなく ECS Fargate か？
本プロジェクトでは「インフラ管理コストの最小化」を優先しました。
- **No Ops**: EC2 インスタンスの OS パッチ適用やスケーリング管理から解放され、コンテナ定義のみに集中するため。
- **Security**: ホスト OS への SSH 管理が不要になり、攻撃対象領域を最小化できるため。

### Network: なぜ VPC エンドポイントを採用したか？
セキュリティとコストのバランスを考慮し、インターネットを経由しないプライベートな通信経路を確保しました。
- **Security**: ECR や CloudWatch Logs への通信を AWS 内網（PrivateLink）に閉じることで、セキュリティリスクを軽減。
- **Cost/Performance**: 特に S3 への通信（Docker レイヤー取得など）には **ゲートウェイ型エンドポイント** を採用。    NAT Gateway を経由させる場合に比べ、通信コストをゼロにしつつ、スループットを向上させています。

---
## 💡 こだわりポイント

### 1. State 管理と排他制御
チーム開発を想定し、Terraform State を **S3** で一元管理し、**DynamoDB** による State Lock を実装しています。    
これにより、複数人が同時に `terraform apply` を実行してステートが破損する事故を物理的に防いでいます。

### 2. GitOps スタイルの CI/CD パイプライン
GitHub Actions を活用し、インフラとアプリケーションのデプロイを完全自動化しました。
- **Infrastructure**: PR 作成時に `terraform plan` を実行し、結果を Bot がコメント通知。`main` マージで `terraform apply` が自動実行されます。
- **Application**: コード修正をトリガーに Docker Build → ECR Push → ECS Rolling Update までを全自動で行います。

### 3. セキュリティ・ガードレール (Shift Left)
- **OIDC 認証**: AWS アクセスキー（AK/SK）を一切発行せず、GitHub Actions と AWS を OIDC で連携させることで、認証情報の漏洩リスクを排除しました。
- **tfsec 導入**: CI パイプラインに静的解析ツール `tfsec` を組み込み、セキュリティリスクのある設定（例: S3 公開設定漏れなど）をデプロイ前に検知・ブロックする仕組みを構築しました。
- **最小権限の原則**: IAM ロールには Wildcard (`*`) を極力使用せず、必要なアクションのみを許可する厳格なポリシー設計を行っています。

### 4. 信頼性向上のための自動ロールバック
ECS の **Deployment Circuit Breaker** を有効化しています。    
デプロイしたコンテナがヘルスチェックに失敗した場合、自動的に健全な旧バージョンへロールバックし、サービスダウンタイムを最小限に抑えます。

### 5. コスト最適化とリソース管理 (Cost Optimization)
ストレージコストの肥大化を防ぐライフサイクルポリシーを導入しました。
- **ECR**: 過去のイメージが無限に溜まらないよう、最新の 10 世代のみを保持し、古いイメージを自動削除する設定を入れています。
- **S3 (State Bucket)**: Terraform State のバージョニングを有効化しつつ、古すぎるバージョン（非現行バージョン）を自動的にクリーンアップするルールを適用し、容量を節約しています。

---

## 🔧 Terraform 設計戦略

Terraform の構成は、再利用性と環境分離を意識して 2 レイヤーに分割しています。

### `env/` (Environment Layer)
環境固有の値（CIDR, Region, Instance Size）を定義し、モジュールを呼び出します。
> `env` ディレクトリ内では `aws_` リソースを直接定義せず、インフラの「組み立て」に専念させています。

### `modules/` (Resource Layer)
AWS リソースの具体的な定義を行う「部品」です。
各モジュールは単一責任の原則に基づき分割されており、環境（dev/stg/prod）に依存しない設計としています。

---

## 📂 ディレクトリ構成
```text
├── env/
│   └── dev/                 # 開発環境用エントリポイント
│       ├── main.tf          # モジュール呼び出し
│       ├── variables.tf     # 環境変数定義
│       └── terraform.tfvars # 具体的なパラメータ
├── modules/                 # 再利用可能なリソース部品
│   ├── vpc/
│   ├── alb/
│   ├── ecs/
│   ├── ecr/
│   ├── iam/
│   ├── sns/
│   ├── s3/
│   ├── dynamodb/
│   └── cloudwatch/
├── .github/
│   └── workflows/
│       ├── docker-ecr.yml      # アプリデプロイ用 (Build & Push)
│       ├── terraform-plan.yml  # PR時のPlan自動実行 & tfsec
│       └── terraform-apply.yml # Merge時のApply自動実行
├── app/
│   ├── Dockerfile
│   └── nginx.conf
```

---

## 📊 SLO/SLI

本プロジェクトでは、明確な信頼性目標（SLO）を定義して運用設計を行っています。

| Metric | SLI (Service Level Indicator) | SLO (Service Level Objective) | Monitoring |
| --- | --- | --- | --- |
| **Availability** | (Total Requests - 5xx Errors) / Total Requests | **99.9%** | CloudWatch Alarm (ALB 5xx Count) |
| **Latency** | Target Response Time | **P99 < 1.0s** | CloudWatch Alarm (TargetResponseTime) |

### 障害対応フロー
アラート発報から復旧までのフローを以下のように定めています。    
現在は個人開発のためメール通知ですが、チーム運用を想定した設計を意識しています。

1.  **Detection (検知)**:
    CloudWatch Alarm が SLO 違反（レイテンシ悪化 / 5xx エラー）を検知。
2.  **Notification (通知)**:
    SNS 経由で管理者へアラートメールを送信。
    *（Future Plan: AWS Chatbot を導入し、Slack への通知と ChatOps による迅速な情報共有を想定）*
3.  **Triage (一次対応)**:
    * **原因特定と復旧**: CloudWatch Logs Insights からエラー原因を特定し、ECS タスクの再起動、または旧バージョンへのロールバックを実施。
4.  **Post-Mortem (事後分析)**:
    * 障害原因を特定し、再発防止策（コード修正やオートスケーリング設定の見直し）を実施。
---

## 🌀 開発中にハマったポイント
### ECSからECRへのPullがタイムアウトする問題
構築中、コンテナが起動せず `ImagePullBackOff` のようなタイムアウトエラーが発生しました。    
セキュリティグループやルートテーブルは正しいはずなのに繋がらない...と数時間悩みました。

**【原因と解決】**    
ECRのエンドポイント設定（PrivateLink）はしていましたが、**「ECRの実体（レイヤーデータ）はS3にある」** という仕様を見落としていました。    
Docker PullにはS3への通信経路が必要だったため、ゲートウェイ型のS3エンドポイントを追加することで解決しました。    
「エンドポイントを作れば繋がる」という思い込みが原因でした。AWSの裏側の仕組みを理解する良い経験になりました。

### CI/CD 構築における IAM 権限の「イタチごっこ」と最小権限の設計
Terraform の実行環境をローカル（AdministratorAccess）から GitHub Actions（OIDC ロール）へ移行する際、権限不足によるパイプラインの失敗が多発しました。    

**【課題：ブートストラップ問題】**    
最初は「ECR への Push」などアプリケーションデプロイに必要な最小限の権限のみを与えていました。    
しかし、Terraform Apply はインフラ全体の変更（IAM ロール自体の作成や、CloudWatch アラームの追加など）を伴うため、    
リソースを追加するたびに「CI が権限エラーで落ちる → ポリシーを追加する」という**イタチごっこ（手戻り）**が発生しました。

**【解決と学び】**    
「Terraform を実行する CI ロール」には、**インフラを変更するための広範な権限（PowerUser 相当に近い権限と IAM 操作権限）が必要である**と再認識しました。    
最終的に、`modules/iam/main.tf` にて Terraform Apply 用のポリシーを体系的に整理し、    
以下のカテゴリごとに必要なアクションを明示的に許可することで、セキュリティと運用効率のバランスを取りました。

- **State 管理**: S3/DynamoDB へのアクセス
- **リソース操作**: VPC, ALB, ECS, CloudWatch へのフルアクセス
- **IAM 操作**: `iam:PassRole` や `iam:CreateRole`（Terraform がロールを作成・紐付けするために必須）

---

## 🚀 今後の展望
### 1. Service Auto Scaling の導入
現在は固定タスク数で運用していますが、CPU/メモリ使用率に応じた **Target Tracking Scaling** を導入し、    
スパイクアクセスへの耐性と、夜間帯のコスト削減（スケールイン）の両立を目指します。

### 2. Blue/Green デプロイメント (AWS CodeDeploy)
現在のローリングアップデートに加え、**CodeDeploy** を導入することで Blue/Green デプロイメントを実現したいと考えています。    
これにより、本番切り替え前の検証が可能になり、リリースリスクをさらに低減させます。

### 3. AWS WAF によるセキュリティ強化
ALB に **AWS WAF (Web Application Firewall)** をアタッチし、一般的な Web 脆弱性（OWASP Top 10）への防御層を追加することを検討しています。

### 4. 可観測性 (Observability) の深化
現在はメトリクス監視が中心ですが、より深い異常検知と可視化を目指します。
- **CloudWatch Logs Insights**: 特定のエラーメッセージ（例: `Exception`, `Timeout`）をクエリで抽出し、アラート発火させる仕組みの導入。
- **Dashboard 整備**: 「Golden Signals（レイテンシ、トラフィック、エラー、サチュレーション）」を一覧できる CloudWatch Dashboard の作成。
---

## 補足

本リポジトリはポートフォリオとしての可読性を重視し、    
インフラ (Terraform) とアプリケーションを単一のリポジトリで管理する **Monorepo** 構成を採用しています。

実際のチーム開発や本番運用においては、ライフサイクルの違いや権限分離の観点から、以下のようにリポジトリを分割する構成が一般的であると理解しています。
- **Infrastructure Repo**: Terraform コードのみを管理（SRE チームがオーナー）
- **Application Repo**: ソースコードと Dockerfile を管理（開発チームがオーナー）
