.PHONY: render bootstrap-secrets install status dashboards placeholders

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

placeholders:
	@grep -R "REPLACE_ME" values secrets README.md scripts || true
