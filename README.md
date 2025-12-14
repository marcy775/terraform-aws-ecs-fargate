# terraform-aws-ecs-fargate

Terraform を用いて AWS 上に  
ALB + ECS(Fargate) + ECR + CloudWatch Logs の構成を構築するサンプルです。

## Architecture
<img width="2442" height="1489" alt="image" src="https://github.com/user-attachments/assets/c774b3ab-ea6c-478c-a4d2-dae79b526d36" />

## 採用した AWS リソース

- VPC  
  - Public Subnet（ALB）
  - Private Subnet（ECS Fargate）

- Application Load Balancer  
  - インターネットからのリクエストを受け付け

- ECS (Fargate)  
  - コンテナ実行基盤
  - ECR からイメージを pull

- Amazon ECR  
  - GitHub Actions からビルドしたイメージを push

- CloudWatch Logs  
  - ECS タスクのログを集約
