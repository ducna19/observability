# Label / Tag Standard cho Observability POC

## Mục tiêu

Mọi metrics, logs, traces và alerts phải có thông tin ownership để DevOps/SRE điều tra nhanh và route đúng team.

## Kubernetes labels bắt buộc

```yaml
env: poc
system: observability-poc
service: <service-name>
team: devops
owner: devops-platform
criticality: tier-3
```

## OpenTelemetry resource attributes bắt buộc

```yaml
service.name: payment-api
service.namespace: payment
service.version: 1.0.0
deployment.environment.name: poc
k8s.cluster.name: k8s-poc-01
k8s.namespace.name: poc-apps
team.name: devops
owner: devops-platform
criticality: tier-3
```

## Quy tắc đặt tên service

```text
<domain>-<service>-<component>

Ví dụ:
payment-api
payment-worker
order-api
order-processor
```

## Quy tắc alert name

```text
<env>:<system>:<service>:<symptom>

Ví dụ:
poc:observability-poc:sample-api:high-error-rate
poc:observability-poc:sample-api:p95-latency-high
```
