# Observability Demo Playbook: LGTM Grafana vs SigNoz

Tai lieu nay dung de demo hai stack observability dang chay trong lab:

- `lgtm-grafana-production`: Grafana + Loki + Tempo + Mimir + Alloy
- `signoz-production`: SigNoz + ClickHouse + k8s-infra collectors

Muc tieu cua demo khong phai chi la "mo dashboard", ma la chung minh khi production co van de, team co the tra loi nhanh:

- He thong co dang khoe khong?
- Service nao bi anh huong?
- Loi xay ra tu luc nao?
- Log nao lien quan?
- Trace nao cham?
- Co can alert/on-call khong?

## 1. Thong Diep Mo Dau

Noi ngan gon voi sep:

```text
Em dung hai stack observability production-like de so sanh.

Stack thu nhat la LGTM:
Grafana + Loki + Tempo + Mimir. Day la huong modular, moi loai du lieu co backend rieng.

Stack thu hai la SigNoz:
SigNoz UI + ClickHouse. Day la huong all-in-one APM, trai nghiem lien mach hon cho developer.

Hom nay em se demo:
1. Metrics: he thong co khoe khong.
2. Logs: loi nam o dau.
3. Traces: request di qua dau va cham o dau.
4. Alerting: co the canh bao nhu the nao.
5. So sanh diem manh, diem yeu cua tung stack.
```

## 2. Chuan Bi Truoc Demo

Mo terminal 1 va kiem tra LGTM:

```bash
cd /home/ducna/Documents/Observability/lgtm-grafana-production
make status
```

Mo terminal 2 va kiem tra SigNoz:

```bash
cd /home/ducna/Documents/Observability/signoz-production
make status
```

Neu port-forward chua mo, chay:

```bash
kubectl -n observability port-forward svc/kps-grafana 3000:80
```

Terminal khac:

```bash
kubectl -n signoz-production port-forward svc/signoz 8081:8080
```

URL demo:

```text
LGTM Grafana: http://127.0.0.1:3000
SigNoz:       http://127.0.0.1:8081
```

Grafana login:

```text
User: admin
Pass: admin-learning-lab-change-me
```

SigNoz:

```text
Neu lan dau vao UI, tao admin account tren man hinh.
```

## 3. Kich Ban 20 Phut

| Thoi gian | Noi dung | Muc tieu |
|---|---|---|
| 0-2 phut | Gioi thieu bai toan observability | Dat boi canh |
| 2-9 phut | Demo LGTM Grafana | Chung minh modular stack |
| 9-16 phut | Demo SigNoz | Chung minh APM all-in-one |
| 16-20 phut | So sanh va de xuat | Chot huong di tiep |

## 4. Demo LGTM Grafana

Mo:

```text
http://127.0.0.1:3000
```

Neu muon demo bang dashboard da dong goi san, mo:

```text
Dashboards > Stack Overview > LGTM Production Stack Overview
```

Xem giai thich tung panel tai:

```text
STACK_DASHBOARDS_GUIDE.md
```

### 4.1 Noi Ve Kien Truc

Noi:

```text
LGTM la stack tach rieng cac backend:

Loki luu logs.
Tempo luu traces.
Mimir luu metrics dai han.
Grafana la UI de query va hien thi.
Alloy la collector/gateway de thu thap telemetry.

Uu diem cua huong nay la linh hoat, tung thanh phan co the scale va thay the rieng.
```

Mo `Connections > Data sources`.

Chi cho sep thay:

```text
Prometheus: metrics realtime tu Kubernetes
Mimir: metrics backend dai han
Loki: logs backend
Tempo: traces backend
Alertmanager: canh bao
```

Noi:

```text
Grafana khong ep minh dung mot backend duy nhat. 
No dong vai tro control plane de xem tat ca du lieu observability.
```

### 4.2 Demo Metrics

Vao `Explore`, chon `Prometheus` hoac `Mimir`.

Query:

```promql
up
```

Noi:

```text
Query nay cho biet target nao dang duoc scrape va con song.
Trong production, metrics giup minh thay tinh trang he thong: CPU, memory, pod status, request rate, latency va error rate.
```

Query them neu muon:

```promql
container_cpu_usage_seconds_total
```

Noi:

```text
Day la du lieu dang duoc thu tu Kubernetes. Khi co su co tai nguyen, team co the nhin metrics de biet node/pod nao dang bat thuong.
```

### 4.3 Demo Logs

Vao `Explore`, chon `Loki`.

Query:

```logql
{namespace="observability"}
```

Neu qua nhieu logs, loc theo pod hoac container:

```logql
{namespace="observability", container="alloy"}
```

Noi:

```text
Logs tra loi cau hoi: ung dung da noi gi tai thoi diem loi.
Voi Loki, minh co the loc theo namespace, pod, container, service.
```

### 4.4 Demo Traces

Vao `Explore`, chon `Tempo`.

Noi:

```text
Traces dung de xem mot request di qua nhung service nao va mat bao lau o tung buoc.
Trong production, traces rat quan trong khi he thong co nhieu microservices.
```

Neu chua co service app that gui trace vao LGTM, noi ro:

```text
Stack da san sang nhan traces qua Alloy Gateway.
Voi app trong cluster, endpoint la:
alloy-gateway.observability.svc.cluster.local:4317 hoac :4318.
```

### 4.5 Demo Alerting

Mo `Alerting`.

Noi:

```text
Canh bao trong Grafana/Prometheus co the dat theo SLO/SLA:
- Pod down
- Error rate cao
- Latency vuot nguong
- CPU/memory canh gioi han

Production can cau hinh route sang Slack, email, MS Teams hoac he thong on-call.
```

### 4.6 Chot LGTM

Noi:

```text
LGTM phu hop neu cong ty muon mot nen tang mo, linh hoat, dung chuan Grafana, co the scale tung backend rieng.

Diem doi lai la van hanh phuc tap hon vi co nhieu thanh phan.
```

## 5. Demo SigNoz

Mo:

```text
http://127.0.0.1:8081
```

Import dashboard:

```text
signoz-production/dashboards/signoz-stack-overview.json
```

Sau do mo:

```text
SigNoz Production Stack Overview
```

Xem giai thich tung panel tai:

```text
STACK_DASHBOARDS_GUIDE.md
```

### 5.1 Noi Ve Kien Truc

Noi:

```text
SigNoz di theo huong all-in-one APM.
UI, query service, collector va storage duoc thiet ke de lam viec cung nhau.

Du lieu logs, metrics, traces duoc ghi vao ClickHouse.
Trai nghiem cua SigNoz thuong de hieu hon cho developer vi no bat dau tu service va request.
```

Kien truc:

```text
Application / Kubernetes
        |
        v
SigNoz OpenTelemetry Collector
        |
        v
ClickHouse
        |
        v
SigNoz UI
```

### 5.2 Demo Services/APM

Vao `Services`.

Tim service:

```text
signoz-production-smoke
```

Noi:

```text
Day la service smoke-test em da gui trace vao SigNoz.
No chung minh duong traces dang hoat dong:
Application -> OTel Collector -> ClickHouse -> SigNoz UI.
```

Neu service chua hien ngay, vao `Traces` va tim theo service name:

```text
signoz-production-smoke
```

### 5.3 Demo Traces

Mo trace `GET /smoke`.

Noi:

```text
Trace cho thay mot request cu the.
Trong ung dung that, moi span se dai dien cho mot buoc: API, DB call, call sang service khac.

Khi latency tang, minh nhin trace de biet cham o API, database hay downstream service.
```

### 5.4 Demo Logs

Vao `Logs`.

Noi:

```text
SigNoz k8s-infra collector dang thu logs tu Kubernetes.
Logs duoc day vao ClickHouse va co the query truc tiep trong UI.
```

Loc theo namespace neu UI co filter:

```text
namespace = signoz-production
```

Hoac:

```text
namespace = observability
```

Noi:

```text
Day la diem tien loi cua SigNoz: developer co the di tu service sang trace, roi sang log lien quan trong cung mot san pham.
```

### 5.5 Demo Metrics / Infrastructure

Vao phan `Infrastructure`, `Kubernetes`, hoac `Dashboards` tuy UI hien thi.

Noi:

```text
SigNoz k8s-infra dang thu:
- Pod logs
- Host metrics
- Kubelet metrics
- Cluster metrics
- Kubernetes events

Nghia la minh khong chi theo doi application, ma con theo doi duoc nen Kubernetes dang chay app.
```

### 5.6 Chot SigNoz

Noi:

```text
SigNoz phu hop neu cong ty muon mot APM nhanh, de dung cho developer, it phai ghep nhieu thanh phan.

Diem doi lai la phu thuoc nhieu vao ClickHouse va ecosystem cua SigNoz.
```

## 6. Bang So Sanh Ngan Gon

| Tieu chi | LGTM Grafana | SigNoz |
|---|---|---|
| Huong tiep can | Modular | All-in-one APM |
| UI chinh | Grafana | SigNoz |
| Metrics | Prometheus/Mimir | ClickHouse |
| Logs | Loki | ClickHouse |
| Traces | Tempo | ClickHouse |
| Collector | Alloy | OpenTelemetry Collector |
| Dashboard | Rat manh, linh hoat | Co san theo APM |
| Developer experience | Can cau hinh dashboard/query nhieu hon | De vao viec nhanh hon |
| Platform/SRE experience | Rat tot neu team quen Grafana | Tot, nhung gan voi SigNoz |
| Van hanh | Nhieu component | It manh ghep hon, nhung ClickHouse la diem trong tam |
| Scale | Scale tung backend rieng | Scale quanh ClickHouse va SigNoz collectors |

## 7. Phan Ket Luan De Xuat

Noi voi sep:

```text
Neu cong ty uu tien nen tang linh hoat, chuan Grafana, de tich hop nhieu datasource va scale tung backend rieng, LGTM la huong manh.

Neu cong ty uu tien APM nhanh, developer de dung, co san service view, trace view, log view trong mot san pham, SigNoz la huong rat dang thu.

De quyet dinh that su, buoc tiep theo nen lay 1-2 service that cua cong ty instrument OpenTelemetry, gui du lieu vao ca hai stack trong 1-2 tuan, roi so sanh:
- Do de dung cua developer
- Toc do query
- Do on dinh khi co nhieu du lieu
- Chi phi storage
- Alerting
- Phan quyen
- Retention
- Cong suc van hanh
```

## 8. Cau Hoi Sep Co The Hoi Va Cach Tra Loi

### Cau hoi: Cai nao production hon?

Tra loi:

```text
Ca hai deu co the dung production.
LGTM production hon theo nghia no la bo cong cu modular, pho bien trong SRE/platform.
SigNoz production hon theo nghia no la APM san pham hoa, de developer dung nhanh.
Lua chon phu thuoc team minh muon van hanh platform mo hay muon trai nghiem APM lien mach.
```

### Cau hoi: Cai nao de van hanh hon?

Tra loi:

```text
SigNoz de bat dau hon vi it manh ghep ve mat UI va workflow.
LGTM phuc tap hon vi tach Loki, Tempo, Mimir, Grafana, Alloy, nhung linh hoat va chuan cong dong hon.
```

### Cau hoi: Cai nao re hon?

Tra loi:

```text
Chi phi phu thuoc data volume va retention.
LGTM co the toi uu tung backend rieng.
SigNoz dua nhieu vao ClickHouse, neu ClickHouse duoc tune tot thi rat manh, nhung can quan ly storage/TTL can than.
Can benchmark bang du lieu service that moi ket luan chinh xac.
```

### Cau hoi: Co can ca hai khong?

Tra loi:

```text
Khong nen production ca hai neu khong co ly do ro rang, vi se tang chi phi va cong van hanh.
Giai doan POC co the chay song song de so sanh.
Sau do nen chon mot huong chinh.
```

### Cau hoi: Buoc tiep theo la gi?

Tra loi:

```text
Buoc tiep theo la instrument OpenTelemetry cho mot service that.
Sau do gui telemetry vao hai stack, tao dashboard va alert giong nhau, roi so sanh bang du lieu that.
```

## 9. Lenh Huu Ich Khi Demo

Kiem tra LGTM:

```bash
cd /home/ducna/Documents/Observability/lgtm-grafana-production
make status
```

Kiem tra SigNoz:

```bash
cd /home/ducna/Documents/Observability/signoz-production
make status
```

Mo Grafana:

```bash
kubectl -n observability port-forward svc/kps-grafana 3000:80
```

Mo SigNoz:

```bash
kubectl -n signoz-production port-forward svc/signoz 8081:8080
```

Kiem tra SigNoz health:

```bash
curl http://127.0.0.1:8081/api/v1/health
```

Kiem tra du lieu trong SigNoz ClickHouse:

```bash
kubectl -n signoz-production exec chi-signoz-clickhouse-cluster-0-0-0 -- \
  clickhouse-client -u admin --password 27ff0399-0d3a-4bd8-919d-17c2181e6fb9 \
  --query "SELECT 'logs' AS kind, count() FROM signoz_logs.logs_v2 UNION ALL SELECT 'metric_samples', count() FROM signoz_metrics.samples_v4 UNION ALL SELECT 'traces', count() FROM signoz_traces.signoz_index_v3"
```

Neu Helm upgrade SigNoz lam collector quay ve OpAMP/nop pipeline:

```bash
cd /home/ducna/Documents/Observability/signoz-production
make patch-static-collector
```

## 10. Mot Cau Chot Manh

Co the ket thuc demo bang cau nay:

```text
Observability khong chi la dashboard.
Gia tri that cua no la giam MTTR: khi production loi, team tim duoc nguyen nhan nhanh hon, co bang chung hon, va it tranh luan cam tinh hon.
```
