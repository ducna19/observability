# Stack Dashboards Guide

Tai lieu nay giai thich hai dashboard moi duoc tao:

- LGTM: `LGTM Production Stack Overview`
- SigNoz: `SigNoz Production Stack Overview`

Muc tieu la de demo cho sep thay tung stack gom nhung thanh phan nao, du lieu chay qua dau, va minh giam sat duoc gi.

## 1. LGTM Production Stack Overview

File:

```text
lgtm-grafana-production/dashboards/lgtm-stack-overview.json
```

Da apply vao Grafana bang ConfigMap:

```text
observability/lgtm-stack-overview-dashboard
```

Mo dashboard:

```text
http://127.0.0.1:3000
Dashboards > Stack Overview > LGTM Production Stack Overview
```

## 1.1 Dashboard Nay The Hien Gi?

Dashboard nay the hien toan bo stack LGTM:

- Grafana: UI/dashboard
- Prometheus: scrape metrics Kubernetes
- Alertmanager: alert routing
- Mimir: long-term metrics backend
- Loki: logs backend
- Tempo: traces backend
- Alloy Gateway: OTLP ingestion gateway
- Alloy Agent: Kubernetes log collector
- MinIO: object storage sandbox
- PVC/storage: persistent volumes cho backend

## 1.2 Cach Giai Thich Tung Panel

### Running Pods

Y nghia:

```text
Tong pod dang Running trong namespace observability va observability-agents.
```

Noi voi sep:

```text
Day la tin hieu tong quan dau tien. Neu pod cua stack observability khong Running, minh khong nen tin dashboard phia sau.
```

### Restarts Last 1h

Y nghia:

```text
Tong so lan container restart trong 1 gio gan nhat.
```

Noi:

```text
Neu restart tang, mot thanh phan nao do dang bat on. Day la dau hieu de minh drill-down vao pod/log.
```

### Bound PVCs

Y nghia:

```text
So persistent volume claim dang Bound.
```

Noi:

```text
Observability production can storage on dinh. Logs, metrics, traces deu can noi luu tru. PVC Bound nghia la storage duoc cap thanh cong.
```

### Mimir Query OK

Y nghia:

```text
Grafana query duoc vao Mimir datasource.
```

Noi:

```text
Prometheus remote_write metrics sang Mimir. Panel nay chung minh long-term metrics backend dang query duoc.
```

### All LGTM Component Pods

Y nghia:

```text
Bang readiness cua tung pod trong stack.
```

Noi:

```text
Bang nay la inventory song cua stack LGTM. Minh thay ro cac nhom: Grafana, Prometheus, Alertmanager, Loki, Tempo, Mimir, Alloy, MinIO.
```

### CPU Usage By Pod

Y nghia:

```text
CPU usage theo pod.
```

Noi:

```text
Panel nay dung de xem thanh phan nao dang tieu ton CPU. Khi scale production, day la co so de sizing va capacity planning.
```

### Memory Usage By Pod

Y nghia:

```text
Memory working set theo pod.
```

Noi:

```text
Nhieu backend observability nhu Mimir, Loki, Tempo, ClickHouse rat nhay voi memory. Theo doi memory giup tranh OOM va mat du lieu tam thoi.
```

### PVC Usage Ratio

Y nghia:

```text
Ti le su dung volume cua storage backend.
```

Noi:

```text
Day la panel rat quan trong trong production. Neu storage day, logs/metrics/traces co the bi drop hoac query cham. Production can alert o nguong 70/85/95%.
```

### Recent LGTM Stack Logs

Y nghia:

```text
Logs gan nhat cua chinh stack LGTM, doc tu Loki.
```

Noi:

```text
Day la diem hay cua observability: minh dung Loki de xem logs cua chinh stack observability. Neu component loi, minh chuyen tu metrics sang logs ngay tren dashboard.
```

## 1.3 Thong Diep Chot Cho LGTM

```text
LGTM phu hop khi cong ty muon stack mo, modular, linh hoat.
Moi loai du lieu co backend rieng: Loki cho logs, Tempo cho traces, Mimir cho metrics.
Doi lai, cong van hanh cao hon vi co nhieu thanh phan can quan ly.
```

## 2. SigNoz Production Stack Overview

File:

```text
signoz-production/dashboards/signoz-stack-overview.json
```

Import trong SigNoz UI:

```text
http://127.0.0.1:8081
Dashboards > Import JSON
```

Neu SigNoz UI chua co admin account, tao account truoc.

## 2.1 Dashboard Nay The Hien Gi?

Dashboard nay the hien toan bo stack SigNoz:

- SigNoz UI/query service
- SigNoz OTel Collector
- ClickHouse
- Zookeeper
- ClickHouse Operator
- k8s-infra OTel Agent
- k8s-infra OTel Deployment
- Logs, metrics, traces da vao ClickHouse
- Kubernetes events
- Smoke-test trace

## 2.2 Cach Giai Thich Tung Panel

### SigNoz Component Inventory

Y nghia:

```text
Bang liet ke thanh phan va vai tro cua tung component trong stack SigNoz.
```

Noi:

```text
SigNoz co it manh ghep hon LGTM. UI, query service va collector duoc thiet ke di cung nhau, storage chinh la ClickHouse.
```

### Telemetry Volume - Last 24h

Y nghia:

```text
Dem so dong logs, metric samples, metric series va traces trong ClickHouse.
```

Noi:

```text
Panel nay chung minh SigNoz khong chi chay UI, ma da ingest du lieu that vao ClickHouse.
```

### Logs By SigNoz Component - Last 30m

Y nghia:

```text
Dem logs theo resource attribute signoz.component.
```

Noi:

```text
k8s-infra collector dang gan metadata vao logs. Nho metadata nay, minh loc duoc log theo component, namespace, pod, node.
```

### Recent Kubernetes Events

Y nghia:

```text
Kubernetes events duoc ghi vao bang logs_v2.
```

Noi:

```text
Khi pod bi restart, image pull loi, scheduling loi, event Kubernetes la dau moi rat quan trong. SigNoz dua event nay vao chung dong quan sat.
```

### Metric Samples By Minute

Y nghia:

```text
Throughput metric samples vao ClickHouse theo phut.
```

Noi:

```text
Duong nay cho thay metrics pipeline dang song. Trong production, neu duong nay ve 0 bat thuong, collector hoac ClickHouse co van de.
```

### Logs By Minute

Y nghia:

```text
Throughput logs/events vao ClickHouse theo phut.
```

Noi:

```text
Panel nay cho thay logs dang chay lien tuc. Neu deploy app moi, minh se thay log volume thay doi.
```

### Smoke Test Traces

Y nghia:

```text
Trace test cua service signoz-production-smoke.
```

Noi:

```text
Trace nay chung minh duong OTLP traces hoat dong: app -> collector -> ClickHouse -> SigNoz UI.
Voi app that, day se la noi minh xem request cham o dau.
```

## 2.3 Thong Diep Chot Cho SigNoz

```text
SigNoz phu hop khi cong ty muon APM nhanh, de hieu voi developer, it phai ghep nhieu manh UI/backend.
Doi lai, storage va performance phu thuoc nhieu vao ClickHouse, can tune retention, TTL, partition va backup can than.
```

## 3. So Sanh Hai Dashboard Khi Demo

Noi voi sep:

```text
LGTM dashboard nhan manh platform health: tung backend co on khong, storage co on khong, logs co vao Loki khong, metrics co vao Mimir khong.

SigNoz dashboard nhan manh APM/data ingestion: ClickHouse dang co logs, metrics, traces; Kubernetes events va service traces nam chung trong mot san pham.
```

Bang so sanh:

| Goc nhin | LGTM dashboard | SigNoz dashboard |
|---|---|---|
| Dieu hanh platform | Rat tot | Tot |
| APM developer | Can cau hinh them | Manh hon |
| Backend model | Tach logs/metrics/traces | Tap trung ClickHouse |
| Debug theo component | Tot qua pod/log panel | Tot qua component inventory va ClickHouse data |
| Demo cho sep | The hien kien truc mo | The hien trai nghiem lien mach |

## 4. Thu Tu Demo Dashboard

Thu tu de demo gon:

1. Mo LGTM dashboard.
2. Chi 4 stat dau: Running Pods, Restarts, PVCs, Mimir.
3. Chi readiness table: day la toan bo thanh phan cua LGTM.
4. Chi CPU/memory/storage: day la van hanh production.
5. Chi logs: day la debug khi co loi.
6. Chuyen sang SigNoz dashboard.
7. Chi component inventory: stack SigNoz gon hon.
8. Chi telemetry volume: data da vao ClickHouse.
9. Chi Kubernetes events/logs/metrics throughput.
10. Chi smoke trace: duong traces hoat dong.

## 5. Cau Chot

```text
Hai dashboard nay khong chi de xem dep.
No cho sep thay khi production gap su co, minh co du lieu de dieu tra: health, resource, storage, logs, events, traces.
```
