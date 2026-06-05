.PHONY: render install status patch-static-collector dashboards pf-signoz

render:
	./scripts/render-signoz-production.sh

install:
	./scripts/install-signoz-production.sh

status:
	./scripts/status-signoz-production.sh

patch-static-collector:
	./scripts/patch-static-collector.sh

dashboards:
	@echo "Import this JSON in SigNoz UI:"
	@echo "/home/ducna/Documents/Observability/signoz-production/dashboards/signoz-stack-overview.json"

pf-signoz:
	./scripts/port-forward-signoz.sh
