# Advanced Crawling Reference

## Table of Contents

- [Session Management](#session-management)
- [Hooks](#hooks)
- [Authentication](#authentication)
- [Deep Crawling](#deep-crawling)
- [Adaptive Crawling](#adaptive-crawling)

---

## Session Management

Sessions maintain browser state across multiple `arun()` calls by reusing the same browser tab. Assign a `session_id` in `CrawlerRunConfig`. Sessions are sequential only -- not suitable for parallel operations.

### Basic Session Usage

```python
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig

async with AsyncWebCrawler() as crawler:
    session_id = "my_session"

    config = CrawlerRunConfig(session_id=session_id)

    result1 = await crawler.arun(url="https://example.com/page1", config=config)
    result2 = await crawler.arun(url="https://example.com/page2", config=config)

    await crawler.crawler_strategy.kill_session(session_id)
```

### The js_only Flag

When `js_only=True`, the crawler skips `page.goto()` and only executes `js_code` on the current page. Essential for pagination where you click a button without reloading.

```python
for page_num in range(3):
    config = CrawlerRunConfig(
        session_id=session_id,
        js_code=js_click_next if page_num > 0 else None,
        js_only=page_num > 0,
        cache_mode=CacheMode.BYPASS
    )
    result = await crawler.arun(url=url, config=config)
```

### Killing Sessions

Always kill sessions when finished to free the browser tab and memory:

```python
await crawler.crawler_strategy.kill_session(session_id)
```

### Pagination: Click-Based

```python
import json
from crawl4ai import AsyncWebCrawler, JsonCssExtractionStrategy, CrawlerRunConfig, CacheMode

async def crawl_paginated():
    url = "https://github.com/microsoft/TypeScript/commits/main"
    session_id = "pagination_session"

    js_next_page = """
    const commits = document.querySelectorAll('li[data-testid="commit-row-item"] h4');
    if (commits.length > 0) { window.lastCommit = commits[0].textContent.trim(); }
    const btn = document.querySelector('a[data-testid="pagination-next-button"]');
    if (btn) { btn.click(); }
    """

    wait_for = """() => {
        const commits = document.querySelectorAll('li[data-testid="commit-row-item"] h4');
        if (commits.length === 0) return false;
        return commits[0].textContent.trim() !== window.lastCommit;
    }"""

    schema = {
        "name": "Commit Extractor",
        "baseSelector": "li[data-testid='commit-row-item']",
        "fields": [{"name": "title", "selector": "h4 a", "type": "text", "transform": "strip"}],
    }

    async with AsyncWebCrawler() as crawler:
        for page in range(3):
            config = CrawlerRunConfig(
                session_id=session_id,
                css_selector="li[data-testid='commit-row-item']",
                extraction_strategy=JsonCssExtractionStrategy(schema),
                js_code=js_next_page if page > 0 else None,
                wait_for=wait_for if page > 0 else None,
                js_only=page > 0,
                cache_mode=CacheMode.BYPASS,
            )
            result = await crawler.arun(url=url, config=config)

        await crawler.crawler_strategy.kill_session(session_id)
```

### Pagination: Infinite Scroll / Load-More

```python
async with AsyncWebCrawler() as crawler:
    session_id = "scroll_session"
    for page in range(5):
        config = CrawlerRunConfig(
            session_id=session_id,
            js_code="document.querySelector('.load-more').click();" if page > 0 else None,
            js_only=page > 0,
            cache_mode=CacheMode.BYPASS
        )
        result = await crawler.arun(url="https://example.com/feed", config=config)
    await crawler.crawler_strategy.kill_session(session_id)
```

---

## Hooks

Hooks customize the crawler at specific pipeline points. All hooks are async and registered via `crawler.crawler_strategy.set_hook()`.

### Hook Points and Signatures

| Hook | Signature | Purpose |
|---|---|---|
| `on_browser_created` | `(browser, **kwargs) -> browser` | After browser creation. No pages exist yet. Light setup only. |
| `on_page_context_created` | `(page: Page, context: BrowserContext, **kwargs) -> page` | After context+page created. Ideal for auth, route blocking, viewport. |
| `on_user_agent_updated` | `(page: Page, context: BrowserContext, user_agent: str, **kwargs) -> page` | When user agent changes. |
| `before_goto` | `(page: Page, context: BrowserContext, url: str, **kwargs) -> page` | Before `page.goto()`. Set custom headers, log URLs. |
| `after_goto` | `(page: Page, context: BrowserContext, url: str, response, **kwargs) -> page` | After navigation. Verify content, wait for elements. |
| `on_execution_started` | `(page: Page, context: BrowserContext, **kwargs) -> page` | When `js_code` execution begins. |
| `before_retrieve_html` | `(page: Page, context: BrowserContext, **kwargs) -> page` | Before final HTML snapshot. Final scroll or lazy-load trigger. |
| `before_return_html` | `(page: Page, context: BrowserContext, html: str, **kwargs) -> page` | Before HTML is returned in `CrawlResult`. |

### Registering Hooks

```python
from crawl4ai import AsyncWebCrawler, BrowserConfig
from playwright.async_api import Page, BrowserContext

crawler = AsyncWebCrawler(config=BrowserConfig(headless=True))

async def on_page_context_created(page: Page, context: BrowserContext, **kwargs):
    async def route_filter(route):
        if route.request.resource_type == "image":
            await route.abort()
        else:
            await route.continue_()
    await context.route("**", route_filter)
    return page

async def before_goto(page: Page, context: BrowserContext, url: str, **kwargs):
    await page.set_extra_http_headers({"Custom-Header": "value"})
    return page

crawler.crawler_strategy.set_hook("on_page_context_created", on_page_context_created)
crawler.crawler_strategy.set_hook("before_goto", before_goto)
```

### Hook Lifecycle Order

1. `on_browser_created` -- once at launch
2. `on_page_context_created` -- when context/page is created
3. `on_user_agent_updated` -- if UA changes
4. `before_goto` -- before navigation
5. `after_goto` -- after navigation
6. `on_execution_started` -- before `js_code` runs
7. `before_retrieve_html` -- before HTML snapshot
8. `before_return_html` -- before returning result

**Guidelines:**
- Never do heavy work in `on_browser_created` (no page/context available).
- Use `on_page_context_created` for auth, route blocking, viewport changes.
- Keep hooks concise; slow hooks degrade performance.
- Wrap risky operations in try/except -- a hook failure can abort the crawl.
- With `arun_many()`, hooks fire in parallel per URL. Ensure async safety.

---

## Authentication

### Hook-Based Login Flow

Use `on_page_context_created` to log in before the crawler navigates to the target URL.

```python
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig
from playwright.async_api import Page, BrowserContext

async def on_page_context_created(page: Page, context: BrowserContext, **kwargs):
    await page.goto("https://example.com/login")
    await page.fill("input[name='username']", "myuser")
    await page.fill("input[name='password']", "mypassword")
    await page.click("button[type='submit']")
    await page.wait_for_selector("#welcome")
    return page

crawler = AsyncWebCrawler(config=BrowserConfig(headless=True))
crawler.crawler_strategy.set_hook("on_page_context_created", on_page_context_created)

await crawler.start()
result = await crawler.arun("https://example.com/protected", config=CrawlerRunConfig())
await crawler.close()
```

### Persistent Browser Context (user_data_dir)

Store cookies, localStorage, and session data in a persistent browser profile directory. Once you log in (manually or via hook), subsequent crawls reuse it.

**Create the profile** by launching Playwright's Chromium with `--user-data-dir`:

```bash
# macOS
~/Library/Caches/ms-playwright/chromium-*/chrome-mac/Chromium.app/Contents/MacOS/Chromium \
    --user-data-dir=/Users/you/my_chrome_profile

# Or use the Crawl4AI CLI
crwl profiles
```

**Use the profile in code:**

```python
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig

browser_config = BrowserConfig(
    headless=True,
    use_managed_browser=True,
    user_data_dir="/Users/you/my_chrome_profile",
    browser_type="chromium"
)

async with AsyncWebCrawler(config=browser_config) as crawler:
    result = await crawler.arun(
        url="https://example.com/private",
        config=CrawlerRunConfig(wait_for="css:.logged-in-content")
    )
```

### Storage State Save and Load

`storage_state` captures cookies and localStorage as a portable JSON file.

**Save state after login (first run):**

```python
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig, CacheMode
from playwright.async_api import Page, BrowserContext

async def on_page_context_created(page: Page, context: BrowserContext, **kwargs):
    await page.goto("https://example.com/login", wait_until="domcontentloaded")
    await page.fill("input[name='username']", "myuser")
    await page.fill("input[name='password']", "mypassword")
    await page.click("button[type='submit']")
    await page.wait_for_load_state("networkidle")
    await context.storage_state(path="my_storage_state.json")
    return page

browser_config = BrowserConfig(
    headless=True,
    use_persistent_context=True,
    user_data_dir="./my_user_data"
)

async with AsyncWebCrawler(config=browser_config) as crawler:
    crawler.crawler_strategy.set_hook("on_page_context_created", on_page_context_created)
    result = await crawler.arun(
        url="https://example.com/protected",
        config=CrawlerRunConfig(cache_mode=CacheMode.BYPASS)
    )
```

**Load state on subsequent runs:**

```python
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig, CacheMode

browser_config = BrowserConfig(
    headless=True,
    use_persistent_context=True,
    user_data_dir="./my_user_data",
    storage_state="my_storage_state.json"
)

async with AsyncWebCrawler(config=browser_config) as crawler:
    result = await crawler.arun(
        url="https://example.com/protected",
        config=CrawlerRunConfig(cache_mode=CacheMode.BYPASS)
    )
```

**Storage state JSON structure:**

```json
{
  "cookies": [
    {"name": "session", "value": "abcd1234", "domain": "example.com", "path": "/"}
  ],
  "origins": [
    {
      "origin": "https://example.com",
      "localStorage": [
        {"name": "token", "value": "my_auth_token"}
      ]
    }
  ]
}
```

`storage_state` accepts either a file path string or a dict with this structure.

---

## Deep Crawling

Deep crawling explores websites beyond a single page by following links across depth levels.

### BFSDeepCrawlStrategy

Breadth-first: explores all links at one depth before going deeper.

```python
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig
from crawl4ai.deep_crawling import BFSDeepCrawlStrategy

config = CrawlerRunConfig(
    deep_crawl_strategy=BFSDeepCrawlStrategy(
        max_depth=2, include_external=False, max_pages=50, score_threshold=0.3
    ),
    verbose=True
)

async with AsyncWebCrawler() as crawler:
    results = await crawler.arun("https://example.com", config=config)
```

### DFSDeepCrawlStrategy

Depth-first: explores as far down a branch as possible before backtracking.

```python
from crawl4ai.deep_crawling import DFSDeepCrawlStrategy

strategy = DFSDeepCrawlStrategy(max_depth=2, include_external=False, max_pages=30)
```

### BestFirstCrawlingStrategy

Recommended for targeted crawling. Uses a scorer to visit higher-priority URLs first.

```python
from crawl4ai.deep_crawling import BestFirstCrawlingStrategy
from crawl4ai.deep_crawling.scorers import KeywordRelevanceScorer

config = CrawlerRunConfig(
    deep_crawl_strategy=BestFirstCrawlingStrategy(
        max_depth=2,
        include_external=False,
        url_scorer=KeywordRelevanceScorer(keywords=["api", "guide"], weight=0.7),
        max_pages=25,
    ),
    stream=True
)

async with AsyncWebCrawler() as crawler:
    async for result in await crawler.arun("https://example.com", config=config):
        print(f"Score: {result.metadata.get('score', 0):.2f} | {result.url}")
```

**Shared parameters (all strategies):**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `max_depth` | `int` | required | Levels beyond the starting page |
| `include_external` | `bool` | `False` | Follow links to other domains |
| `max_pages` | `int` | unlimited | Hard limit on total pages |
| `score_threshold` | `float` | `-inf` | Minimum score (BFS/DFS only) |
| `filter_chain` | `FilterChain` | `None` | URL filter chain |
| `url_scorer` | scorer | `None` | URL scorer instance |

### FilterChain and Filters

Combine filters with `FilterChain` -- all must pass for a URL to be followed.

```python
from crawl4ai.deep_crawling.filters import (
    FilterChain, URLPatternFilter, DomainFilter, ContentTypeFilter
)

filter_chain = FilterChain([
    URLPatternFilter(patterns=["*guide*", "*tutorial*"]),
    DomainFilter(allowed_domains=["docs.example.com"], blocked_domains=["old.docs.example.com"]),
    ContentTypeFilter(allowed_types=["text/html"])
])
```

**All filter types:**

| Filter | Import | Description |
|---|---|---|
| `URLPatternFilter` | `crawl4ai.deep_crawling.filters` | Wildcard URL matching (`*blog*`) |
| `DomainFilter` | `crawl4ai.deep_crawling.filters` | Allow/block specific domains |
| `ContentTypeFilter` | `crawl4ai.deep_crawling.filters` | Filter by HTTP Content-Type |
| `ContentRelevanceFilter` | `crawl4ai.deep_crawling.filters` | BM25 relevance against a query string |
| `SEOFilter` | `crawl4ai.deep_crawling.filters` | SEO quality (meta tags, headers, keywords) |

```python
from crawl4ai.deep_crawling.filters import ContentRelevanceFilter, SEOFilter

relevance = ContentRelevanceFilter(query="Python web crawling", threshold=0.7)
seo = SEOFilter(threshold=0.5, keywords=["tutorial", "guide"])
```

### Scorers

```python
from crawl4ai.deep_crawling.scorers import KeywordRelevanceScorer

scorer = KeywordRelevanceScorer(keywords=["crawl", "async"], weight=0.7)
```

### Streaming vs Non-Streaming

**Non-streaming (default):** returns a list after all pages are crawled.

```python
results = await crawler.arun("https://example.com", config=config)  # list
```

**Streaming:** returns an async iterator for real-time processing.

```python
config = CrawlerRunConfig(deep_crawl_strategy=strategy, stream=True)

async for result in await crawler.arun("https://example.com", config=config):
    process(result)
```

### Crash Recovery

All strategies support `resume_state` and `on_state_change` for production crash recovery.

```python
import json
from crawl4ai.deep_crawling import BFSDeepCrawlStrategy

async def save_state(state: dict):
    with open("checkpoint.json", "w") as f:
        json.dump(state, f)

# Initial crawl with state persistence
strategy = BFSDeepCrawlStrategy(max_depth=3, on_state_change=save_state)

# Resume from checkpoint
with open("checkpoint.json") as f:
    saved = json.load(f)

strategy = BFSDeepCrawlStrategy(max_depth=3, resume_state=saved, on_state_change=save_state)
```

**State structure:**

```json
{
    "strategy_type": "bfs",
    "visited": ["url1", "url2"],
    "pending": [{"url": "url3", "parent_url": "url1"}],
    "depths": {"url1": 0, "url2": 1},
    "pages_crawled": 42
}
```

Manual export: `strategy.export_state()` returns the last captured state (requires `on_state_change` to be set). When both parameters are `None`, there is zero overhead.

---

## Adaptive Crawling

Adaptive crawling automatically decides when enough information has been gathered to answer a query, using a three-layer scoring system: coverage, consistency, and saturation.

### AdaptiveCrawler Overview

```python
from crawl4ai import AsyncWebCrawler, AdaptiveCrawler

async with AsyncWebCrawler() as crawler:
    adaptive = AdaptiveCrawler(crawler)
    state = await adaptive.digest(start_url="https://docs.python.org/3/", query="async context managers")
    adaptive.print_stats()

    for page in adaptive.get_relevant_content(top_k=5):
        print(f"- {page['url']} (score: {page['score']:.2f})")
```

### AdaptiveConfig

```python
from crawl4ai import AdaptiveConfig

config = AdaptiveConfig(
    confidence_threshold=0.8,   # Stop at this confidence (default: 0.7)
    max_pages=30,               # Hard page limit (default: 20)
    top_k_links=5,              # Links per page (default: 3)
    min_gain_threshold=0.05,    # Minimum gain to continue (default: 0.1)
    save_state=True,            # Auto-save state
    state_path="crawl.json",    # State file path
    strategy="statistical",     # "statistical" or "embedding"
)
```

### Strategies: Statistical vs Embedding

**Statistical (default):** Term-based analysis. Fast, free, no dependencies.

```python
config = AdaptiveConfig(strategy="statistical", confidence_threshold=0.8)
```

**Embedding:** Semantic understanding with query expansion.

```python
from crawl4ai import AdaptiveConfig, LLMConfig

config = AdaptiveConfig(
    strategy="embedding",
    embedding_model="sentence-transformers/all-MiniLM-L6-v2",
    n_query_variations=10,
    embedding_min_confidence_threshold=0.1,
    embedding_llm_config=LLMConfig(provider="openai/text-embedding-3-small", api_token="key")
)
```

| Feature | Statistical | Embedding |
|---|---|---|
| Speed | Very fast | Moderate |
| Cost | Free | API-dependent |
| Accuracy | Good for exact terms | Excellent for concepts |
| Best for | Technical docs | Research, broad topics |

### Persistence and Resumption

```python
# Save
config = AdaptiveConfig(save_state=True, state_path="state.json")
await adaptive.digest(start_url, query)

# Resume
await adaptive.digest(start_url, query, resume_from="state.json")

# Export/import knowledge base
adaptive.export_knowledge_base("kb.jsonl")
new_adaptive.import_knowledge_base("kb.jsonl")
```

### AdaptiveCrawler API

**Constructor:** `AdaptiveCrawler(crawler: AsyncWebCrawler, config: Optional[AdaptiveConfig] = None)`

**`digest()` method:**

```python
async def digest(start_url: str, query: str, resume_from: Optional[Union[str, Path]] = None) -> CrawlState
```

**Properties:**

| Property | Type | Description |
|---|---|---|
| `confidence` | `float` | Current confidence (0-1) |
| `coverage_stats` | `dict` | coverage, consistency, saturation, confidence |
| `is_sufficient` | `bool` | Whether enough info has been gathered |
| `state` | `CrawlState` | Current crawl state |

**Methods:**

| Method | Description |
|---|---|
| `get_relevant_content(top_k=5)` | List of dicts: `url`, `content`, `score`, `metadata` |
| `print_stats(detailed=False)` | Summary table; `detailed=True` for full metrics |
| `export_knowledge_base(path)` | Export to JSONL |
| `import_knowledge_base(path)` | Import from JSONL |

**Confidence interpretation:** 0.0-0.3 insufficient, 0.3-0.6 partial, 0.6-0.7 good, 0.7-1.0 excellent.
