# terraform-aws-ecs-fargate

Terraform を用いて AWS 上に  
ALB + ECS(Fargate) + ECR + CloudWatch Logs の構成を構築するサンプルです。

## Architecture
<img width="2442" height="1489" alt="image" src="https://github.com/user-attachments/assets/c774b3ab-ea6c-478c-a4d2-dae79b526d36" />

## Overview
Terraform を使って ALB + ECS(Fargate) 構成を構築するポートフォリオ

## Architecture
- VPC
- Public / Private Subnet
- Internet Gateway
- ALB
- ECS (Fargate)
- CloudWatch Logs

## Motivation
手動作業ではなく Infrastructure as Code による再現性・安全性を重視し、
SRE 的な視点でインフラを構築した。
