# Crawl4AI Core API Reference

## Table of Contents

- [AsyncWebCrawler](#asyncwebcrawler)
- [BrowserConfig](#browserconfig)
- [CrawlerRunConfig](#crawlerrunconfig)
- [CacheMode](#cachemode)
- [LLMConfig](#llmconfig)
- [CrawlResult](#crawlresult)
- [Complete Example](#complete-example)

---

## AsyncWebCrawler

The main class for asynchronous web crawling. Accepts a `BrowserConfig` for global browser settings, then runs crawls via `arun()` with per-crawl `CrawlerRunConfig` objects.

### Constructor and Lifecycle

```python
from crawl4ai import AsyncWebCrawler, BrowserConfig

browser_cfg = BrowserConfig(browser_type="chromium", headless=True)

# Context manager (recommended)
async with AsyncWebCrawler(config=browser_cfg) as crawler:
    result = await crawler.arun("https://example.com")
```

Constructor takes `config` (`BrowserConfig`), optional `base_directory` (for caches/logs), and `thread_safe` (`bool`, default `False`). The `always_bypass_cache` parameter is deprecated; use `CrawlerRunConfig.cache_mode` instead. For manual lifecycle control, call `await crawler.start()` and `await crawler.close()`.

### arun() and arun_many()

```python
async def arun(self, url: str, config: Optional[CrawlerRunConfig] = None) -> CrawlResult
async def arun_many(self, urls: List[str], config: Optional[CrawlerRunConfig] = None) -> List[CrawlResult]
```

`arun()` crawls a single URL. `arun_many()` processes multiple URLs with rate limiting, memory-aware concurrency, and progress monitoring. Control concurrency via `semaphore_count`, `mean_delay`, `max_range` in `CrawlerRunConfig`. Set `stream=True` to process results as they complete.

---

## BrowserConfig

Controls how the browser is launched. Created once and passed to `AsyncWebCrawler(config=...)`.

```python
from crawl4ai import BrowserConfig

browser_cfg = BrowserConfig(
    browser_type="chromium",
    headless=True,
    viewport_width=1280,
    viewport_height=720,
)
```

### Browser Engine

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `browser_type` | `str` | `"chromium"` | Engine: `"chromium"`, `"firefox"`, or `"webkit"` |
| `chrome_channel` | `str` | `"chromium"` | Channel to launch (e.g., `"chrome"`, `"msedge"`). Auto-cleared for Firefox/WebKit |

### Display and Viewport

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `headless` | `bool` | `True` | No visible UI. Set `False` for debugging |
| `viewport_width` | `int` | `1080` | Page width in pixels |
| `viewport_height` | `int` | `600` | Page height in pixels |
| `viewport` | `dict` | `None` | Overrides width/height if set |

### Browser Mode and CDP

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `browser_mode` | `str` | `"dedicated"` | `"dedicated"` (new instance), `"builtin"` (CDP background), `"custom"` (explicit CDP), `"docker"` (container) |
| `use_managed_browser` | `bool` | `False` | Launch via Chrome DevTools Protocol. Auto-set by `browser_mode` |
| `cdp_url` | `str` | `None` | CDP endpoint URL (e.g., `"ws://localhost:9222/devtools/browser/"`) |
| `debugging_port` | `int` | `9222` | Port for browser debugging protocol |
| `host` | `str` | `"localhost"` | Host for browser connection |

### Proxy

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `proxy` | `str` | `None` | Deprecated. Use `proxy_config` |
| `proxy_config` | `ProxyConfig` or `dict` | `None` | `{"server": "...", "username": "...", "password": "..."}` |

### Identity and Stealth

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `user_agent` | `str` | Chrome-based UA | Custom user agent string |
| `user_agent_mode` | `str` | `""` | `"random"` to randomize from a pool |
| `user_agent_generator_config` | `dict` | `{}` | Config for random user agent generation |
| `enable_stealth` | `bool` | `False` | Playwright-stealth mode for bot detection bypass |
| `cookies` | `list` | `[]` | Pre-set cookies: `[{"name": "...", "value": "...", "url": "..."}]` |
| `headers` | `dict` | `{}` | Extra HTTP headers for every request |

### Persistent Context and Storage

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `use_persistent_context` | `bool` | `False` | Keep cookies/sessions across runs. Also sets `use_managed_browser=True` |
| `user_data_dir` | `str` | `None` | Directory for user profiles and cookies |
| `storage_state` | `str` or `dict` | `None` | In-memory storage state to restore |
| `accept_downloads` | `bool` | `False` | Allow file downloads. Requires `downloads_path` |
| `downloads_path` | `str` | `None` | Directory for downloaded files |

### Performance

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `text_mode` | `bool` | `False` | Disable images/heavy content for speed |
| `light_mode` | `bool` | `False` | Disable background features for performance |
| `extra_args` | `list` | `[]` | Browser process flags (e.g., `["--disable-extensions"]`) |
| `java_script_enabled` | `bool` | `True` | `False` to disable JS for static content |

### Other Browser Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ignore_https_errors` | `bool` | `True` | Continue despite invalid SSL certificates |
| `sleep_on_close` | `bool` | `False` | Small delay when closing for cleanup |
| `verbose` | `bool` | `True` | Print extra logs |

---

## CrawlerRunConfig

Controls per-crawl behavior. Passed to `arun(url, config=...)`.

```python
from crawl4ai import CrawlerRunConfig, CacheMode

run_cfg = CrawlerRunConfig(
    cache_mode=CacheMode.BYPASS,
    css_selector="main.content",
    word_count_threshold=15,
    excluded_tags=["nav", "footer"],
)
```

### Content Processing

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `word_count_threshold` | `int` | `200` | Skip text blocks below this word count |
| `css_selector` | `str` | `None` | Retain only the region matching this selector |
| `target_elements` | `list[str]` | `None` | CSS selectors for markdown/extraction focus (full page still processed for links/media) |
| `excluded_tags` | `list` | `None` | Remove entire tags (e.g., `["script", "style"]`) |
| `excluded_selector` | `str` | `None` | CSS selector for exclusion (e.g., `"#ads, .tracker"`) |
| `only_text` | `bool` | `False` | Text-only extraction |
| `prettiify` | `bool` | `False` | Beautify final HTML |
| `keep_data_attributes` | `bool` | `False` | Preserve `data-*` attributes |
| `keep_attrs` | `list` | `[]` | HTML attributes to keep (e.g., `["id", "class"]`) |
| `remove_forms` | `bool` | `False` | Remove all `<form>` elements |
| `parser_type` | `str` | `"lxml"` | HTML parser (`"lxml"`, `"html.parser"`) |
| `markdown_generator` | `MarkdownGenerationStrategy` | `None` | Custom markdown strategy. Supports `content_source` option |
| `chunking_strategy` | `ChunkingStrategy` | `RegexChunking()` | Content chunking before extraction |
| `scraping_strategy` | `ContentScrapingStrategy` | `LXMLWebScrapingStrategy()` | Content scraping strategy |

### Cache and Session

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `cache_mode` | `CacheMode` | `None` | Cache behavior. See [CacheMode](#cachemode) |
| `session_id` | `str` | `None` | Reuse a browser session across `arun()` calls |
| `shared_data` | `dict` | `None` | Data shared between hooks across crawl operations |

Deprecated boolean flags (`bypass_cache`, `disable_cache`, `no_cache_read`, `no_cache_write`) are still accepted but `cache_mode` is preferred.

### Page Navigation and Timing

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `wait_until` | `str` | `"domcontentloaded"` | Navigation condition: `"networkidle"`, `"domcontentloaded"`, `"load"` |
| `page_timeout` | `int` | `60000` | Timeout in ms for navigation and JS |
| `wait_for` | `str` | `None` | Wait before extraction: `"css:selector"` or `"js:() => bool"` |
| `wait_for_timeout` | `int` | `None` | Timeout in ms for `wait_for`. Falls back to `page_timeout` |
| `wait_for_images` | `bool` | `False` | Wait for images to load |
| `delay_before_return_html` | `float` | `0.1` | Pause in seconds before final HTML capture |
| `check_robots_txt` | `bool` | `False` | Respect robots.txt rules |
| `mean_delay` | `float` | `0.1` | Mean delay between `arun_many()` requests |
| `max_range` | `float` | `0.3` | Max random range added to `mean_delay` |
| `semaphore_count` | `int` | `5` | Max concurrency for `arun_many()` |

### Page Interaction

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `js_code` | `str` or `list[str]` | `None` | JavaScript to run after page load |
| `c4a_script` | `str` or `list[str]` | `None` | C4A script (compiles to JS) |
| `js_only` | `bool` | `False` | Apply JS only in existing session, no reload |
| `ignore_body_visibility` | `bool` | `True` | Skip `<body>` visibility check |
| `scan_full_page` | `bool` | `False` | Auto-scroll for infinite-scroll pages (content appended) |
| `scroll_delay` | `float` | `0.2` | Delay between scroll steps |
| `max_scroll_steps` | `int` | `None` | Max scroll steps. `None` = scroll until done |
| `process_iframes` | `bool` | `False` | Inline iframe content |
| `remove_overlay_elements` | `bool` | `False` | Remove modals/popups |
| `simulate_user` | `bool` | `False` | Simulate mouse movements |
| `override_navigator` | `bool` | `False` | Override navigator properties for stealth |
| `magic` | `bool` | `False` | Auto popup/consent handling (experimental) |
| `adjust_viewport_to_content` | `bool` | `False` | Resize viewport to content height |
| `virtual_scroll_config` | `VirtualScrollConfig` | `None` | For sites that replace content on scroll (e.g., Twitter). Takes `container_selector`, `scroll_count` (default 10), `scroll_by` (default `"container_height"`), `wait_after_scroll` (default 0.5s) |

### Media and Screenshots

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `screenshot` | `bool` | `False` | Capture screenshot (base64) |
| `screenshot_wait_for` | `float` | `None` | Wait before screenshot |
| `screenshot_height_threshold` | `int` | `~20000` | Alternate strategy threshold for tall pages |
| `pdf` | `bool` | `False` | Generate PDF |
| `capture_mhtml` | `bool` | `False` | Capture MHTML snapshot |
| `image_description_min_word_threshold` | `int` | `~50` | Min words for valid image alt text |
| `image_score_threshold` | `int` | `~3` | Filter images below this score |
| `exclude_external_images` | `bool` | `False` | Exclude images from other domains |
| `exclude_all_images` | `bool` | `False` | Exclude all images |
| `table_score_threshold` | `int` | `7` | Min score for table processing |

### Links, Extraction, and Domain Handling

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `extraction_strategy` | `ExtractionStrategy` | `None` | Structured extraction (CSS/LLM-based). Output in `result.extracted_content` |
| `exclude_external_links` | `bool` | `False` | Remove links outside current domain |
| `exclude_internal_links` | `bool` | `False` | Remove internal links |
| `exclude_social_media_links` | `bool` | `False` | Remove social media links |
| `exclude_social_media_domains` | `list` | (defaults) | Social media domains to exclude |
| `exclude_domains` | `list` | `[]` | Custom domains to exclude |
| `score_links` | `bool` | `False` | Calculate link quality scores |

### Location, Identity, and Proxy (per-crawl)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `locale` | `str` | `None` | Browser locale (e.g., `"en-US"`) |
| `timezone_id` | `str` | `None` | Browser timezone (e.g., `"America/New_York"`) |
| `geolocation` | `GeolocationConfig` | `None` | GPS: `GeolocationConfig(latitude=..., longitude=..., accuracy=...)` |
| `fetch_ssl_certificate` | `bool` | `False` | Include SSL cert info in result |
| `proxy_config` | `ProxyConfig` or `dict` | `None` | Per-crawl proxy (overrides browser-level) |
| `user_agent` | `str` | `None` | Per-crawl User-Agent override |

### Streaming, URL Matching, and Advanced

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `method` | `str` | `"GET"` | HTTP method (for AsyncHTTPCrawlerStrategy) |
| `stream` | `bool` | `False` | Stream results in `arun_many()` |
| `url_matcher` | `str`, `callable`, or `list` | `None` | URL pattern(s) for per-URL configs in `arun_many()`. `None` matches all |
| `match_mode` | `MatchMode` | `MatchMode.OR` | Combine matchers: `OR` (any) or `AND` (all) |
| `deep_crawl_strategy` | `DeepCrawlStrategy` | `None` | Recursive crawling with link following |
| `verbose` | `bool` | `True` | Detailed crawl step logs |
| `log_console` | `bool` | `False` | Log page JS console output |
| `capture_network_requests` | `bool` | `False` | Capture in `result.network_requests` |
| `capture_console_messages` | `bool` | `False` | Capture in `result.console_messages` |

### clone() Method

Both `BrowserConfig` and `CrawlerRunConfig` support `clone()` to create modified copies.

```python
base = CrawlerRunConfig(cache_mode=CacheMode.ENABLED, word_count_threshold=200)
bypass = base.clone(cache_mode=CacheMode.BYPASS, stream=True)
```

---

## CacheMode

Enum controlling cache behavior. Set via `CrawlerRunConfig(cache_mode=...)`.

```python
from crawl4ai import CacheMode
```

| Value | Description |
|-------|-------------|
| `CacheMode.ENABLED` | Normal caching: read if available, write if missing |
| `CacheMode.DISABLED` | No caching at all |
| `CacheMode.READ_ONLY` | Read from cache, never write |
| `CacheMode.WRITE_ONLY` | Write to cache, never read existing |
| `CacheMode.BYPASS` | Skip reading cache for this operation |

---

## LLMConfig

Configuration for LLM providers used by `LLMExtractionStrategy`, `LLMContentFilter`, and schema generators (`JsonCssExtractionStrategy.generate_schema`, `JsonXPathExtractionStrategy.generate_schema`).

```python
from crawl4ai import LLMConfig
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `provider` | `str` | `"openai/gpt-4o-mini"` | Format: `"provider/model"` (e.g., `"anthropic/claude-3-5-sonnet-20240620"`, `"gemini/gemini-2.0-flash"`, `"ollama/llama3"`, `"groq/llama3-70b-8192"`, `"deepseek/deepseek-chat"`) |
| `api_token` | `str` | `None` | API token. Auto-reads env var if unset (e.g., `OPENAI_API_KEY`). Supports `"env:VAR_NAME"` prefix |
| `base_url` | `str` | `None` | Custom API endpoint URL |
| `backoff_base_delay` | `int` | `2` | Seconds before first retry on rate limit |
| `backoff_max_attempts` | `int` | `3` | Total attempts (initial + retries) |
| `backoff_exponential_factor` | `int` | `2` | Retry delay multiplier: `delay = base_delay * factor^attempt` |

```python
import os
from crawl4ai import LLMConfig

llm_config = LLMConfig(provider="openai/gpt-4o-mini", api_token=os.getenv("OPENAI_API_KEY"))
```

---

## CrawlResult

Returned by `arun()` and `arun_many()`. Contains all crawl output. Defined in `crawl4ai/crawler/models.py`.

### Status Fields

| Field | Type | Description |
|-------|------|-------------|
| `url` | `str` | Final URL after redirects |
| `success` | `bool` | `True` if crawl completed without major errors |
| `status_code` | `Optional[int]` | HTTP status code (200, 404, etc.). `None` if failed before response |
| `error_message` | `Optional[str]` | Error description when `success=False` |
| `session_id` | `Optional[str]` | Session ID if one was used |
| `response_headers` | `Optional[dict]` | HTTP response headers |

### Content Fields

| Field | Type | Description |
|-------|------|-------------|
| `html` | `str` | Original unmodified HTML |
| `cleaned_html` | `Optional[str]` | Sanitized HTML (scripts, styles, excluded tags removed) |
| `fit_html` | `Optional[str]` | Preprocessed HTML optimized for extraction |
| `extracted_content` | `Optional[str]` | JSON string from `extraction_strategy` |

### Markdown Fields

The `markdown` field holds a `MarkdownGenerationResult`:

| Sub-field | Type | Description |
|-----------|------|-------------|
| `raw_markdown` | `str` | Full HTML-to-Markdown conversion |
| `markdown_with_citations` | `str` | Markdown with academic-style citations |
| `references_markdown` | `str` | Reference list / footnotes |
| `fit_markdown` | `Optional[str]` | Filtered markdown (requires `PruningContentFilter` or `BM25ContentFilter`) |
| `fit_html` | `Optional[str]` | HTML that produced `fit_markdown` |

The legacy `markdown_v2` property is deprecated. Use `result.markdown` directly.

### Media and Links

**`media`** (`Dict[str, List[Dict]]`): Keys: `"images"`, `"videos"`, `"audios"`. Each item has `src`, `alt`/`title`, `score`, `desc`.

**`links`** (`Dict[str, List[Dict]]`): Keys: `"internal"`, `"external"`. Each item has `href`, `text`, `title`, `context`, `domain`.

### Capture Fields

| Field | Type | Description |
|-------|------|-------------|
| `screenshot` | `Optional[str]` | Base64-encoded PNG (when `screenshot=True`) |
| `pdf` | `Optional[bytes]` | Raw PDF bytes (when `pdf=True`) |
| `mhtml` | `Optional[str]` | MHTML snapshot (when `capture_mhtml=True`) |
| `downloaded_files` | `Optional[List[str]]` | Paths to downloaded files |
| `ssl_certificate` | `Optional[SSLCertificate]` | SSL cert info: `issuer`, `subject`, `valid_from`, `valid_until` |

### Network, Console, and Metadata

**`network_requests`** (when `capture_network_requests=True`): List of dicts with `event_type` (`"request"`, `"response"`, `"request_failed"`), `url`, `method`, `headers`, `status`, `timestamp`.

**`console_messages`** (when `capture_console_messages=True`): List of dicts with `type` (`"log"`, `"error"`, `"warning"`), `text`, `location`, `timestamp`.

**`metadata`**: Page metadata dict (title, description, OG data, author).

**`dispatch_result`**: From `arun_many()` with dispatchers: `task_id`, `memory_usage`, `peak_memory`, `start_time`, `end_time`.

---

## Complete Example

```python
import asyncio
import json
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig, CacheMode

async def main():
    browser_cfg = BrowserConfig(
        browser_type="chromium",
        headless=True,
        viewport_width=1280,
        viewport_height=720,
    )

    run_cfg = CrawlerRunConfig(
        cache_mode=CacheMode.BYPASS,
        css_selector="main.content",
        excluded_tags=["nav", "footer", "script", "style"],
        exclude_external_links=True,
        wait_for="css:.article-loaded",
        word_count_threshold=10,
        screenshot=True,
        page_timeout=30000,
    )

    async with AsyncWebCrawler(config=browser_cfg) as crawler:
        result = await crawler.arun(url="https://example.com/blog", config=run_cfg)

        if result.success:
            print("URL:", result.url)
            print("Status:", result.status_code)
            print("Cleaned HTML length:", len(result.cleaned_html or ""))
            if result.markdown:
                print("Markdown:", result.markdown.raw_markdown[:300])
            if result.extracted_content:
                print("Extracted:", json.loads(result.extracted_content))
            if result.screenshot:
                print("Screenshot base64 length:", len(result.screenshot))
        else:
            print("Crawl failed:", result.error_message)

asyncio.run(main())
```
