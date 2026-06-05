KIND_CLUSTER_NAME ?= observability-poc
SAMPLE_IMAGE ?= observability-sample-api
SAMPLE_TAG ?= 0.1.0
SAMPLE_FULL_IMAGE ?= $(SAMPLE_IMAGE):$(SAMPLE_TAG)

.PHONY: repos ns lgtm-lite mimir signoz router-lite router-mimir build-kind build-minikube app status pf-grafana pf-signoz pf-app load uninstall prod-render prod-lgtm prod-status

repos:
	./scripts/00-bootstrap-repos.sh

ns:
	./scripts/01-create-namespaces.sh

lgtm-lite:
	./scripts/10-install-lgtm-lite.sh

mimir:
	./scripts/11-install-mimir.sh

signoz:
	./scripts/20-install-signoz.sh

router-lite:
	./scripts/30-install-router-lite.sh

router-mimir:
	./scripts/31-install-router-with-mimir.sh

build-kind:
	KIND_CLUSTER_NAME=$(KIND_CLUSTER_NAME) \
	SAMPLE_IMAGE=$(SAMPLE_IMAGE) \
	SAMPLE_TAG=$(SAMPLE_TAG) \
	./scripts/40-build-sample-kind.sh

build-minikube:
	./scripts/40-build-sample-minikube.sh

app:
	./scripts/41-deploy-sample-app.sh

status:
	./scripts/50-status.sh

pf-app:
	./scripts/60-port-forward-sample-app.sh

load:
	./scripts/70-generate-load.sh

pf-grafana:
	./scripts/80-port-forward-grafana.sh

pf-signoz:
	./scripts/81-port-forward-signoz.sh

uninstall:
	./scripts/90-uninstall-all.sh

prod-render:
	./production/lgtm/scripts/render-lgtm-production.sh

prod-lgtm:
	./production/lgtm/scripts/install-lgtm-production.sh

prod-status:
	./production/lgtm/scripts/status-lgtm-production.sh
