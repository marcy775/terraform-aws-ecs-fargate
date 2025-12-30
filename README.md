# terraform-aws-ecs-fargate

このリポジトリは、Terraform を用いて AWS 上に  
**ALB + ECS(Fargate) + ECR + CloudWatch Logs** の構成を構築するサンプルです。

## 目的

- Infrastructure as Code による再現性・安全性のあるインフラ構築
- GitHub Actions によるアプリケーションの自動デプロイ
- SRE 視点での運用・監視・権限設計の学習

## 構成概要

- **Terraform**：インフラ構築（VPC, Subnet, ALB, ECS, ECR, IAM）
- **GitHub Actions**：Docker build → ECR push → ECS 更新
- **CloudWatch Logs**：コンテナログの収集

## アーキテクチャ図

<img width="2442" height="1489" alt="image" src="https://github.com/user-attachments/assets/c774b3ab-ea6c-478c-a4d2-dae79b526d36" />


- VPC
- Public / Private Subnet
- Internet Gateway
- ALB
- ECS (Fargate)
- ECR
- CloudWatch Logs

## ディレクトリ構成
```
├── env/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
├── modules/
│   ├── vpc/
│   ├── alb/
│   ├── ecs/
│   ├── ecr/
│   └── iam/
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

## 補足

本リポジトリは学習・デモ用途のため、インフラとアプリケーションを同居させています。  
実運用では以下のように分離する構成が望ましいです：

- インフラ用リポジトリ（Terraform）
- アプリケーション用リポジトリ（Dockerfile / GitHub Actions）