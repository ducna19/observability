# Quickstart

## 1. Bootstrap

```bash
make repos
make ns
```

## 2. Install LGTM Lite

```bash
make lgtm-lite
```

## 3. Install SigNoz

```bash
make signoz
```

## 4. Install OTel router

```bash
make router-lite
```

## 5. Build sample app

Kind:

```bash
make build-kind
```

Minikube:

```bash
make build-minikube
```

## 6. Deploy app

```bash
make app
```

## 7. Port-forward app

Terminal 1:

```bash
make pf-app
```

## 8. Generate load

Terminal 2:

```bash
make load
```

## 9. Open UI

Terminal 3:

```bash
make pf-grafana
```

Terminal 4:

```bash
make pf-signoz
```

## 10. Optional Mimir

```bash
make mimir
make router-mimir
```
