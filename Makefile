# =============================================================================
# achetronic@blog — Makefile
# -----------------------------------------------------------------------------
# Recipes to develop, build and deploy the blog.
# Usage: `make help`
# =============================================================================

# ---- config -----------------------------------------------------------------
HUGO            ?= hugo
HUGO_VERSION    ?= 0.155.3
PORT            ?= 1313
BIND            ?= 0.0.0.0
BASEURL         ?= http://localhost:$(PORT)/
ENVIRONMENT     ?= development
PUBLIC_DIR      ?= public
CACHE_DIR       ?= resources

# ANSI colors for messages (because we like them)
GREEN  := \033[1;32m
YELLOW := \033[1;33m
BLUE   := \033[1;34m
RED    := \033[1;31m
DIM    := \033[2m
RESET  := \033[0m

# All recipes are phony (no files match these names)
.PHONY: help \
        check install-hugo \
        serve dev preview \
        build build-prod \
        new new-post \
        clean clean-all \
        lint check-links \
        stats \
        deploy-check \
        docker-build docker-run docker-push \
        open

# Show help by default
.DEFAULT_GOAL := help

# ---- help -------------------------------------------------------------------
help: ## show this help
	@printf "$(GREEN)achetronic@blog$(RESET) — available recipes:\n\n"
	@awk 'BEGIN {FS = ":.*?## "} \
		/^[a-zA-Z_-]+:.*?## / { \
			printf "  $(BLUE)%-18s$(RESET) %s\n", $$1, $$2 \
		} \
		/^## / { \
			printf "\n$(YELLOW)%s$(RESET)\n", substr($$0, 4) \
		}' $(MAKEFILE_LIST)
	@printf "\n$(DIM)variables: HUGO=$(HUGO)  PORT=$(PORT)  BASEURL=$(BASEURL)$(RESET)\n"

## ── setup ──

check: ## verify Hugo is installed (extended)
	@command -v $(HUGO) >/dev/null 2>&1 || { \
		printf "$(RED)error:$(RESET) hugo not found. Run: make install-hugo\n"; exit 1; }
	@printf "$(GREEN)✓$(RESET) "; $(HUGO) version

install-hugo: ## print install instructions for Hugo extended
	@printf "$(YELLOW)how to install hugo extended v$(HUGO_VERSION):$(RESET)\n\n"
	@printf "  $(BLUE)# linux (deb):$(RESET)\n"
	@printf "  wget https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/hugo_extended_$(HUGO_VERSION)_linux-amd64.deb\n"
	@printf "  sudo dpkg -i hugo_extended_$(HUGO_VERSION)_linux-amd64.deb\n\n"
	@printf "  $(BLUE)# macos:$(RESET)\n"
	@printf "  brew install hugo\n\n"
	@printf "  $(BLUE)# arch:$(RESET)\n"
	@printf "  sudo pacman -S hugo\n\n"
	@printf "  $(BLUE)# go (any platform):$(RESET)\n"
	@printf "  go install -tags extended github.com/gohugoio/hugo@v$(HUGO_VERSION)\n"

## ── development ──

serve: check ## dev server with drafts on :$(PORT)
	@printf "$(GREEN)>> serving hugo at$(RESET) http://localhost:$(PORT)/\n"
	@printf "$(DIM)   ctrl-c to stop$(RESET)\n\n"
	@$(HUGO) server \
		--bind $(BIND) \
		--port $(PORT) \
		--baseURL $(BASEURL) \
		--appendPort=true \
		--buildDrafts \
		--buildFuture \
		--navigateToChanged \
		--disableFastRender

dev: serve ## alias for `serve`

preview: check ## production-like server (no drafts, minified)
	@printf "$(GREEN)>> production preview at$(RESET) http://localhost:$(PORT)/\n\n"
	@$(HUGO) server \
		--bind $(BIND) \
		--port $(PORT) \
		--baseURL $(BASEURL) \
		--appendPort=true \
		--environment production \
		--minify

## ── build ──

build: check ## build into public/ (drafts included, dev environment)
	@printf "$(GREEN)>> dev build$(RESET)\n"
	@$(HUGO) --gc --buildDrafts --buildFuture --environment development
	@printf "$(GREEN)✓$(RESET) generated in $(PUBLIC_DIR)/\n"

build-prod: check clean ## production build (minified, no drafts)
	@printf "$(GREEN)>> production build$(RESET)\n"
	@$(HUGO) --gc --minify --environment production
	@printf "$(GREEN)✓$(RESET) build ready in $(PUBLIC_DIR)/\n"
	@du -sh $(PUBLIC_DIR)/ 2>/dev/null || true

## ── content ──

new: ## scaffold a new post: make new SLUG=my-article
	@if [ -z "$(SLUG)" ]; then \
		printf "$(RED)error:$(RESET) SLUG is required. Example: make new SLUG=my-article\n"; \
		exit 1; \
	fi
	@$(HUGO) new content posts/$(SLUG).md
	@printf "$(GREEN)✓$(RESET) created content/posts/$(SLUG).md\n"

new-post: new ## alias for `new`

## ── maintenance ──

clean: ## remove the build directory
	@rm -rf $(PUBLIC_DIR)/ .hugo_build.lock
	@printf "$(GREEN)✓$(RESET) $(PUBLIC_DIR)/ removed\n"

clean-all: clean ## remove build + Hugo caches
	@rm -rf $(CACHE_DIR)/
	@printf "$(GREEN)✓$(RESET) caches removed\n"

stats: ## site stats (posts, words, etc.)
	@printf "$(YELLOW)## blog stats$(RESET)\n"
	@printf "  posts:        %s\n" "$$(find content/posts -name '*.md' ! -name '_index.md' | wc -l)"
	@printf "  drafts:       %s\n" "$$(grep -lR '^draft: true' content/ 2>/dev/null | wc -l)"
	@printf "  words:        %s\n" "$$(find content -name '*.md' -exec cat {} + | wc -w)"
	@printf "  lines:        %s\n" "$$(find content -name '*.md' -exec cat {} + | wc -l)"
	@printf "  theme:        %s\n" "$$(grep '^theme:' hugo.yaml | awk '{print $$2}' | tr -d '\"')"
	@printf "  hugo:         %s\n" "$$($(HUGO) version | head -1)"

## ── ci / qa ──

lint: check ## validate the Hugo config
	@$(HUGO) config --quiet >/dev/null && \
		printf "$(GREEN)✓$(RESET) config valid\n" || \
		{ printf "$(RED)✗$(RESET) invalid config\n"; exit 1; }

check-links: build ## broken-link check (requires lychee)
	@if command -v lychee >/dev/null 2>&1; then \
		lychee --offline --no-progress $(PUBLIC_DIR)/; \
	else \
		printf "$(YELLOW)warning:$(RESET) lychee not installed. Install with: cargo install lychee\n"; \
		printf "  skipping check-links\n"; \
	fi

deploy-check: build-prod ## mirror the build CI runs
	@printf "$(GREEN)✓$(RESET) production build ok — ready to push\n"
	@printf "$(DIM)   reminder: Settings → Pages → Source: GitHub Actions$(RESET)\n"

## ── docker / oci ──

IMAGE ?= achetronic/website
TAG   ?= local

docker-build: ## build the OCI image ($(IMAGE):$(TAG))
	@printf "$(GREEN)>> docker build $(IMAGE):$(TAG)$(RESET)\n"
	@docker build -t $(IMAGE):$(TAG) .
	@printf "$(GREEN)✓$(RESET) image $(IMAGE):$(TAG)\n"

docker-run: docker-build ## build and run the image on :8080
	@printf "$(GREEN)>> running on http://localhost:8080$(RESET)\n"
	@docker run --rm -p 8080:8080 --name achetronic-blog $(IMAGE):$(TAG)

docker-push: ## tag and push to GHCR (requires docker login at ghcr.io)
	@docker tag $(IMAGE):$(TAG) ghcr.io/$(IMAGE):$(TAG)
	@docker push ghcr.io/$(IMAGE):$(TAG)
	@printf "$(GREEN)✓$(RESET) ghcr.io/$(IMAGE):$(TAG) pushed\n"

## ── extras ──

open: ## open the blog in the browser (assumes `serve` is running)
	@command -v xdg-open >/dev/null && xdg-open http://localhost:$(PORT)/ || \
	 command -v open >/dev/null && open http://localhost:$(PORT)/ || \
	 printf "open http://localhost:$(PORT)/ in your browser\n"
