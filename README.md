# terraform-aws-ecs-fargate

このリポジトリは、Terraform を用いて AWS 上に  
**ALB + ECS(Fargate) + ECR + CloudWatch Logs** の構成を構築するサンプルです。

## 目的

- Infrastructure as Code による再現性・安全性のあるインフラ構築
- GitHub Actions によるアプリケーションの自動デプロイ
- SRE視点でのヘルスチェック・ログ・権限設計の実践

## 構成概要

- **Terraform**：インフラ構築（VPC, Subnet, ALB, ECS, ECR, IAM, CloudWatch）
- **GitHub Actions**：Docker build → ECR push → ECS 更新
- **CloudWatch**：コンテナログの収集/メトリクス監視/アラーム通知(SNS)

## 構成図
<img width="2964" height="1402" alt="image" src="https://github.com/user-attachments/assets/aa0a6893-9261-4949-9169-25c440ff2b99" />



- VPC
- Public / Private Subnet
- Internet Gateway
- IAM(OIDC) 
- ALB
- ECS (Fargate)
- ECR
- CloudWatch(Logs/Alarm)

## ディレクトリ構成
```
├── env/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
├── modules/
│   └── vpc/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
│   ├── alb/
│   ├── ecs/
│   ├── ecr/
│   └── iam/
│   └── sns/
│   └── cloudwatch/
├── .github/
│   └── workflows/
│       └── docker-ecr.yml
├── app/
│   └── Dockerfile
│   └── nginx.conf
```

## Terraform Design

Terraform の構成は以下の2レイヤーに分離しています：

### `env/` レイヤー（環境定義）

- 利用する module の選択
- 環境固有の値（CIDR、リージョン等）の定義
- module 間の依存関係の定義

> `env/` では `aws_*` リソースは定義せず、インフラ構成の「組み立て」のみを行います。

### `modules/` レイヤー（リソース定義）

- AWS リソースの具体的な定義
- 環境に依存しない設計
- 単一責務を意識した module 分割

> 各 module は他の module の存在を直接知らず、必要な情報は `variables` を通じて受け取ります。

## GitHub Actions CI/CD

- `main` ブランチに push → GitHub Actions 実行
- Docker build → ECR push
- `aws ecs update-service` により ECS タスクが再起動
- 新しいタスクが起動し、ALB のヘルスチェックを通過後に切り替え

## ECS 自動ロールバック設計
ECS の Deployment Circuit Breaker を有効化し、 デプロイ失敗時の自動ロールバックを実装しています。
```
deployment_controller {
type = "ECS"
}


deployment_circuit_breaker {
enable = true
rollback = true
}
```
- タスク起動失敗やヘルスチェック NG 時に自動で前バージョンへ復旧

## IAM / セキュリティ設計

- GitHub Actions から AWS にアクセスするために OIDC を使用
- Terraform module において IAM ロールを明示的に分離
- ECS タスクロールに最小権限を付与（ECR pull / CloudWatch Logs write）

## 運用設計（監視・ログ）
- ALB のヘルスチェックを `/health` に設定し、デプロイ安定性を確保
- ECS タスクのログは CloudWatch Logs に自動送信
- ECS サービスは `minimumHealthyPercent` を調整し、ローリング更新を制御
- ECS サービスの CPU / メモリ使用率 を監視 > SNS 経由で メール通知 を送信

## 改善ポイント / 今後の展望

- Terraform の CI/CD（plan/apply）を GitHub Actions に統合する構成を検討中
- ECS タスク定義のバージョン管理をより明示的に行いたい
- ECS 無停止デプロイの実装


## 補足

本リポジトリは学習・デモ用途のため、インフラとアプリケーションを同居させています。  
実運用では以下のように分離する構成が望ましいです：

- インフラ用リポジトリ（Terraform）
- アプリケーション用リポジトリ（Dockerfile / GitHub Actions）
