LOCAL_PB_URL = http://127.0.0.1:8090

.PHONY: help
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# vite bundles vite.config.mjs into node_modules/.vite-temp before loading it,
# but node_modules is a symlink into the read-only Nix store. --configLoader
# runner loads the config directly and never writes that temp file.
VITE_FLAGS ?= --configLoader runner

# ── Vendor / submodules ──────────────────────────────────────────────────────

.PHONY: vendor
vendor: ## Init and update all git submodules to their pinned commits
	@# In CI environments (GitHub Actions) SSH access is unavailable;
	@# rewrite git@github.com: to https://github.com/ so submodules clone via HTTPS.
	@[ -z "$$CI" ] || git config --global url."https://github.com/".insteadOf "git@github.com:"
	@# Fall back to a plain clone when this tree is not a git checkout (source
	@# tarball, vendored copy). The submodule directory itself always exists, so
	@# probe for a file inside it rather than for the directory.
	@if [ -d .git ]; then git submodule update --init; \
	elif [ ! -e vendor/master-builder/AGENTS.md ]; then \
		mkdir -p vendor && git clone https://github.com/Suomen-Palikkaharrastajat-ry/master-builder.git vendor/master-builder; \
	fi

# ── Development environment ──────────────────────────────────────────────────

.PHONY: shell
shell: ## Enter devenv shell
	devenv shell

# ── Elm frontend ──────────────────────────────────────────────────────────────

.PHONY: elm-dev
elm-dev: vendor ## Start Elm + Vite dev server (hot reload)
	cd elm-app && vite $(VITE_FLAGS)

.PHONY: elm-dev-local
elm-dev-local: vendor ## Start Elm + Vite dev server against local PocketBase
	cd elm-app && VITE_POCKETBASE_URL=$(LOCAL_PB_URL) vite $(VITE_FLAGS)

ELM_APP_SOURCES := $(shell find elm-app/src -name '*.elm')
ELM_PACKAGE_SOURCES := $(shell find vendor/master-builder/packages -name '*.elm' -o -name '*.css' 2>/dev/null)

.PHONY: elm-tailwind-gen
elm-tailwind-gen: elm-app/.elm-tailwind/.stamp ## Generate typed Tailwind Elm modules into elm-app/.elm-tailwind/

elm-app/.elm-tailwind/.stamp: elm-app/elm.json elm-app/vite.config.mjs elm-app/main.css $(ELM_APP_SOURCES) $(ELM_PACKAGE_SOURCES)
	cd elm-app && elm-tailwind-classes gen
	mkdir -p elm-app/.elm-tailwind
	touch $@

dist/.elm-stamp: elm-app/.elm-tailwind/.stamp $(ELM_APP_SOURCES) $(ELM_PACKAGE_SOURCES) elm-app/elm.json elm-app/vite.config.mjs elm-app/main.js elm-app/main.css
	cd elm-app && vite build $(VITE_FLAGS)
	touch $@

.PHONY: elm-build
elm-build: dist/.elm-stamp ## Production build of Elm SPA → dist/

.PHONY: elm-build-local
elm-build-local: ## Production build of Elm SPA targeting local PocketBase
	cd elm-app && VITE_POCKETBASE_URL=$(LOCAL_PB_URL) vite build

.PHONY: elm-test
elm-test: elm-tailwind-gen ## Run Elm unit tests
	cd elm-app && elm-test

.PHONY: elm-check
elm-check: ## Check Elm formatting + elm-review (no changes)
	cd elm-app && elm-format --validate src/ tests/
	$(MAKE) elm-review

.PHONY: elm-review
elm-review: elm-tailwind-gen ## Run elm-review with the shared LlmAgent rules from vendor/master-builder
	cd elm-app && elm-review --config ../review

.PHONY: elm-format
elm-format: ## Auto-format Elm source files
	cd elm-app && elm-format --yes src/ tests/

# ── Haskell backend ───────────────────────────────────────────────────────────

HS_SOURCES := $(shell find statics/src statics/app -name '*.hs') statics/statics.cabal $(wildcard cabal.project*)

statics/statics: $(HS_SOURCES)
	cabal build statics
	cp $$(cabal list-bin statics) $@

.PHONY: statics-build
statics-build: statics/statics ## Build Haskell static generator

dist/.statics-stamp: statics/statics
	mkdir -p dist
	./statics/statics
	touch $@

.PHONY: statics
statics: dist/.statics-stamp ## Generate static files (rss, atom, json, geojson, images)

.PHONY: statics-local
statics-local: ## Generate static files against local PocketBase
	POCKETBASE_URL=$(LOCAL_PB_URL) ./statics/statics

.PHONY: statics-test
statics-test: ## Run Haskell tests
	cabal test statics-test

.PHONY: statics-check
statics-check: ## Lint Haskell source (hlint)
	hlint statics/src/ statics/app/

.PHONY: statics-format
statics-format: ## Auto-format Haskell source (fourmolu)
	find statics/src statics/app -name '*.hs' | xargs fourmolu --mode inplace

.PHONY: repl
repl: ## Start the Haskell REPL
	cabal repl statics

.PHONY: cabal-check
cabal-check: ## Check the package for common errors
	cd statics && cabal check

# ── Combined targets ──────────────────────────────────────────────────────────

.PHONY: watch
watch: elm-dev ## Start development server

dist/.statics-stamp-nix:
	mkdir -p dist
	statics
	touch $@

.PHONY: build
build: elm-build ## Production build of Elm SPA

.PHONY: dist-ci
dist-ci: dist/.elm-stamp dist/.statics-stamp-nix ## CI build: Elm SPA + statics via nix-provided binary
	cp -r assets/. dist/

.PHONY: dist
dist: dist/.elm-stamp dist/.statics-stamp ## Full production build: Elm SPA + static files
	cp -r assets/. dist/

.PHONY: dist-local
dist-local: elm-build-local statics-local ## Full local build against local PocketBase
	cp -r assets/. dist/

# ── Test & quality ────────────────────────────────────────────────────────────

.PHONY: check
check: elm-check statics-check ## Run all linting/formatting checks

.PHONY: test
test: elm-test statics-test ## Run all tests (Elm + Haskell)

.PHONY: format
format: elm-format statics-format ## Auto-format all code
	treefmt

# ── Cleanup ───────────────────────────────────────────────────────────────────

.PHONY: clean
clean: ## Clean build artifacts
	rm -rf dist elm-app/.elm-tailwind elm-app/elm-stuff statics/statics dist-newstyle
