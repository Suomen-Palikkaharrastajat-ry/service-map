.PHONY: help
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: shell
shell: ## Enter devenv shell
	devenv shell

.PHONY: basemap
basemap: dist/basemap.pmtiles ## Generate the PMTiles basemap from official Finnish open data

dist/basemap.pmtiles: scripts/generate-basemap.sh
	bash scripts/generate-basemap.sh

.PHONY: clean
clean: ## Remove generated basemap output
	rm -rf dist

.PHONY: clean-cache
clean-cache: ## Remove downloaded source data cache (forces a full re-fetch)
	rm -rf .cache
