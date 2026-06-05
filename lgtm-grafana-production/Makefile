.PHONY: render bootstrap-secrets install status dashboards kind-multinode install-kind-multinode test-kind-multinode pf-grafana placeholders

render:
	./scripts/render-lgtm-production.sh

bootstrap-secrets:
	./scripts/bootstrap-sandbox-secrets.sh

install:
	./scripts/install-lgtm-production.sh

status:
	./scripts/status-lgtm-production.sh

dashboards:
	./scripts/apply-dashboards.sh

kind-multinode:
	./scripts/create-kind-multinode.sh

install-kind-multinode:
	./scripts/install-kind-multinode.sh

test-kind-multinode:
	./scripts/test-lgtm-multinode.sh

pf-grafana:
	./scripts/port-forward-grafana.sh

placeholders:
	@grep -R "REPLACE_ME" values secrets README.md scripts || true
