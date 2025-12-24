# terraform-aws-ecs-fargate
Terraform を用いて AWS 上に  
ALB + ECS(Fargate) + ECR + CloudWatch Logs の構成を構築するサンプルです。

本リポジトリはインフラ構築（Terraform）を主目的としていますが、
学習およびデモ用途として、ECS 上で動作させる最小構成のアプリケーション
（Dockerfile / GitHub Actions）も同一リポジトリ内に含めています。

実運用を想定した場合は、以下のように
- インフラ用リポジトリ
- アプリケーション用リポジトリ

を分離する構成が望ましいと考えています。

## Architecture
<img width="2442" height="1489" alt="image" src="https://github.com/user-attachments/assets/c774b3ab-ea6c-478c-a4d2-dae79b526d36" />

- VPC
- Public / Private Subnet
- Internet Gateway
- ALB
- ECS (Fargate)
- CloudWatch Logs

## Motivation
手動作業ではなく Infrastructure as Code による再現性・安全性を重視し、
SRE 的な視点でインフラを構築した。

## ディレクトリ構成
Terraform未経験として構成が直感的にわかる環境分離の構成
```
├── env/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── vpc/
│   ├── alb/
│   ├── ecs/
│   ├── ecr/
│   └── iam/
```
## Terraform Design

本リポジトリでは、Terraform の構成を以下の2レイヤーに分離しています。

- env/: 環境ごとの差分を管理するレイヤー（配線）
- modules/: 再利用可能な AWS リソースの部品

### env レイヤーの責務
- 利用する module の選択
- 環境固有の値（CIDR、リージョン等）の定義
- module 間の依存関係の定義

> env レイヤーでは aws_* リソースは定義せず、インフラ構成の「組み立て」のみを行います。

### modules レイヤーの責務
- AWS リソースの具体的な定義
- 環境に依存しない設計
- 単一責務を意識した module 分割

> 各 module は他の module の存在を直接知らず、必要な情報は variables を通じて受け取ります。