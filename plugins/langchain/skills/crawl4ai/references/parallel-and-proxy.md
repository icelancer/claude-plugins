# Parallel Crawling, Proxies, and Identity Management

## Table of Contents

- [arun_many()](#arun_many)
  - [Function Signature](#function-signature)
  - [Batch Mode](#batch-mode)
  - [Streaming Mode](#streaming-mode)
- [Dispatchers](#dispatchers)
  - [MemoryAdaptiveDispatcher](#memoryadaptivedispatcher)
  - [SemaphoreDispatcher](#semaphoredispatcher)
- [Rate Limiting](#rate-limiting)
- [Crawler Monitor](#crawler-monitor)
- [URL-Specific Configurations](#url-specific-configurations)
  - [url_matcher Patterns](#url_matcher-patterns)
  - [MatchMode](#matchmode)
  - [Config Lists Example](#config-lists-example)
- [Proxy Configuration](#proxy-configuration)
  - [ProxyConfig](#proxyconfig)
  - [Proxy Rotation Strategies](#proxy-rotation-strategies)
- [Identity-Based Crawling](#identity-based-crawling)
  - [Managed Browsers](#managed-browsers)
  - [BrowserProfiler](#browserprofiler)
  - [Magic Mode](#magic-mode)
  - [Locale, Timezone, and Geolocation](#locale-timezone-and-geolocation)
- [Dispatch Results](#dispatch-results)

---

## arun_many()

Crawls multiple URLs concurrently. Returns a list of `CrawlResult` (batch mode) or an async generator (streaming mode).

### Function Signature

```python
async def arun_many(
    urls: Union[List[str], List[Any]],
    config: Optional[Union[CrawlerRunConfig, List[CrawlerRunConfig]]] = None,
    dispatcher: Optional[BaseDispatcher] = None,
) -> Union[List[CrawlResult], AsyncGenerator[CrawlResult, None]]:
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `urls` | `List[str]` | List of URLs to crawl. |
| `config` | `CrawlerRunConfig` or `List[CrawlerRunConfig]` | Single config for all URLs, or list of configs with `url_matcher` patterns. |
| `dispatcher` | `BaseDispatcher` | Concurrency controller. Defaults to `MemoryAdaptiveDispatcher`. |

### Batch Mode

Set `stream=False` (the default). Returns a list after all URLs complete.

```python
import asyncio
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig, CacheMode

async def crawl_batch():
    browser_config = BrowserConfig(headless=True, verbose=False)
    run_config = CrawlerRunConfig(cache_mode=CacheMode.BYPASS, stream=False)

    async with AsyncWebCrawler(config=browser_config) as crawler:
        results = await crawler.arun_many(
            urls=["https://example.com/page1", "https://example.com/page2"],
            config=run_config,
        )
        for result in results:
            if result.success:
                print(f"OK: {result.url} ({len(result.markdown)} chars)")
            else:
                print(f"FAIL: {result.url} - {result.error_message}")

asyncio.run(crawl_batch())
```

### Streaming Mode

Set `stream=True`. Returns an async generator; results yield as they complete.

```python
async def crawl_streaming():
    run_config = CrawlerRunConfig(cache_mode=CacheMode.BYPASS, stream=True)

    async with AsyncWebCrawler(config=BrowserConfig(headless=True)) as crawler:
        async for result in await crawler.arun_many(
            urls=["https://example.com/p1", "https://example.com/p2"],
            config=run_config,
        ):
            if result.success:
                print(f"Completed: {result.url}")
```

---

## Dispatchers

Dispatchers control concurrency for `arun_many()`.

### MemoryAdaptiveDispatcher

Dynamically manages concurrency based on system memory. Default when no dispatcher is specified.

```python
from crawl4ai import RateLimiter, CrawlerMonitor, DisplayMode
from crawl4ai.async_dispatcher import MemoryAdaptiveDispatcher

dispatcher = MemoryAdaptiveDispatcher(
    memory_threshold_percent=90.0,
    check_interval=1.0,
    max_session_permit=10,
    memory_wait_timeout=600.0,
    rate_limiter=RateLimiter(base_delay=(1.0, 2.0), max_delay=30.0, max_retries=2),
    monitor=CrawlerMonitor(max_visible_rows=15, display_mode=DisplayMode.DETAILED),
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `memory_threshold_percent` | `float` | `90.0` | Pause crawling if system memory exceeds this %. |
| `check_interval` | `float` | `1.0` | Seconds between memory checks. |
| `max_session_permit` | `int` | `10` | Maximum concurrent crawling tasks. |
| `memory_wait_timeout` | `float` | `600.0` | Seconds to wait before raising `MemoryError`. |
| `rate_limiter` | `RateLimiter` | `None` | Optional rate limiter. |
| `monitor` | `CrawlerMonitor` | `None` | Optional monitoring display. |

### SemaphoreDispatcher

Fixed concurrency control without memory-based adaptation.

```python
from crawl4ai.async_dispatcher import SemaphoreDispatcher

dispatcher = SemaphoreDispatcher(
    max_session_permit=20,
    rate_limiter=RateLimiter(base_delay=(0.5, 1.0), max_delay=10.0),
    monitor=CrawlerMonitor(display_mode=DisplayMode.DETAILED),
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `max_session_permit` | `int` | `20` | Maximum concurrent crawling tasks. |
| `rate_limiter` | `RateLimiter` | `None` | Optional rate limiter. |
| `monitor` | `CrawlerMonitor` | `None` | Optional monitoring display. |

---

## Rate Limiting

`RateLimiter` manages request pacing with random delays and exponential backoff.

```python
from crawl4ai import RateLimiter

rate_limiter = RateLimiter(
    base_delay=(1.0, 3.0),        # Random delay range (seconds) between requests
    max_delay=60.0,                # Cap on exponential backoff delay
    max_retries=3,                 # Retries before marking request as failed
    rate_limit_codes=[429, 503],   # HTTP codes that trigger backoff
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `base_delay` | `Tuple[float, float]` | `(1.0, 3.0)` | Min/max random delay between requests to the same domain. |
| `max_delay` | `float` | `60.0` | Upper cap on backoff delay. |
| `max_retries` | `int` | `3` | Retries on rate-limit responses before giving up. |
| `rate_limit_codes` | `List[int]` | `[429, 503]` | HTTP status codes that trigger backoff. |

When a response returns a code in `rate_limit_codes`, exponential backoff with jitter is applied, capped at `max_delay`. Pass the limiter to any dispatcher via the `rate_limiter` parameter.

---

## Crawler Monitor

`CrawlerMonitor` provides a real-time dashboard. Pass it to any dispatcher via the `monitor` parameter.

```python
from crawl4ai import CrawlerMonitor, DisplayMode

monitor = CrawlerMonitor(max_visible_rows=15, display_mode=DisplayMode.DETAILED)
```

| Display Mode | Enum Value | Description |
|--------------|------------|-------------|
| Detailed | `DisplayMode.DETAILED` | Individual task status, memory usage, timing per URL. |
| Aggregated | `DisplayMode.AGGREGATED` | Summary statistics and overall progress. |
| Progress Bar | `DisplayMode.PROGRESS_BAR` | Progress bar for the overall crawl. |

---

## URL-Specific Configurations

Assign different `CrawlerRunConfig` objects to different URL patterns using `url_matcher`. First matching config wins.

### url_matcher Patterns

**String patterns (glob-style):**

```python
CrawlerRunConfig(url_matcher="*.pdf")
CrawlerRunConfig(url_matcher="*/api/*")
CrawlerRunConfig(url_matcher="https://*.example.com/*")
```

**Callable (function or lambda):**

```python
CrawlerRunConfig(url_matcher=lambda url: "github.com" in url)
```

**List of mixed patterns:**

```python
CrawlerRunConfig(
    url_matcher=["https://*", lambda url: "internal" in url],
    match_mode=MatchMode.AND,
)
```

A `CrawlerRunConfig` without `url_matcher` matches all URLs (use as fallback).

### MatchMode

```python
from crawl4ai import MatchMode
```

| Mode | Description |
|------|-------------|
| `MatchMode.OR` | Any condition must match (default for lists). |
| `MatchMode.AND` | All conditions must match. |

Additional string match modes: `contains`, `wildcard`, `regex`, `exact`.

### Config Lists Example

```python
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig, MatchMode
from crawl4ai.processors.pdf import PDFContentScrapingStrategy
from crawl4ai.content_filter_strategy import PruningContentFilter
from crawl4ai.markdown_generation_strategy import DefaultMarkdownGenerator

configs = [
    CrawlerRunConfig(
        url_matcher="*.pdf",
        scraping_strategy=PDFContentScrapingStrategy(),
    ),
    CrawlerRunConfig(
        url_matcher=["*/blog/*", "*/article/*"],
        markdown_generator=DefaultMarkdownGenerator(
            content_filter=PruningContentFilter(threshold=0.48)
        ),
    ),
    CrawlerRunConfig(
        url_matcher=lambda url: "github.com" in url,
        js_code="window.scrollTo(0, 500);",
    ),
    CrawlerRunConfig(),  # Default fallback
]

async with AsyncWebCrawler() as crawler:
    results = await crawler.arun_many(urls=urls, config=configs)
```

**Rules:** Configs evaluate in order. Put specific patterns first. Always include a fallback config (no `url_matcher`) as the last item; without one, unmatched URLs fail with "No matching configuration found". Test patterns with `config.is_match(url)`.

---

## Proxy Configuration

Proxies are configured per request via `CrawlerRunConfig.proxy_config`.

### ProxyConfig

Three equivalent forms:

```python
from crawl4ai import ProxyConfig, CrawlerRunConfig

# ProxyConfig object
run_config = CrawlerRunConfig(proxy_config=ProxyConfig(server="http://proxy.example.com:8080"))
# Dictionary
run_config = CrawlerRunConfig(proxy_config={"server": "http://proxy.example.com:8080"})
# Plain string
run_config = CrawlerRunConfig(proxy_config="http://proxy.example.com:8080")
```

| Field | Type | Description |
|-------|------|-------------|
| `server` | `str` | Proxy server URL (e.g., `http://proxy.example.com:8080`). |
| `username` | `str` | Optional authentication username. |
| `password` | `str` | Optional authentication password. |

**Authenticated proxy:**

```python
run_config = CrawlerRunConfig(
    proxy_config=ProxyConfig(
        server="http://proxy.example.com:8080",
        username="your_username",
        password="your_password",
    )
)
```

**Supported formats via `ProxyConfig.from_string()`:**

```python
ProxyConfig.from_string("http://user:pass@192.168.1.1:8080")  # HTTP with auth
ProxyConfig.from_string("https://proxy.example.com:8080")     # HTTPS
ProxyConfig.from_string("socks5://proxy.example.com:1080")    # SOCKS5
ProxyConfig.from_string("192.168.1.1:8080")                   # IP:port (defaults HTTP)
ProxyConfig.from_string("192.168.1.1:8080:user:pass")         # IP:port:user:pass
```

**Environment variable loading:**

```python
import os
from crawl4ai import ProxyConfig

os.environ["PROXIES"] = "ip1:port1:user1:pass1,ip2:port2:user2:pass2,ip3:port3"
proxies = ProxyConfig.from_env()  # Returns List[ProxyConfig]
```

### Proxy Rotation Strategies

Attach a rotation strategy to `CrawlerRunConfig.proxy_rotation_strategy`:

```python
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig, CacheMode, ProxyConfig
from crawl4ai.proxy_strategy import RoundRobinProxyStrategy

proxies = ProxyConfig.from_env()
proxy_strategy = RoundRobinProxyStrategy(proxies)

run_config = CrawlerRunConfig(
    cache_mode=CacheMode.BYPASS,
    proxy_rotation_strategy=proxy_strategy,
)

async with AsyncWebCrawler(config=BrowserConfig(headless=True)) as crawler:
    results = await crawler.arun_many(urls=urls, config=run_config)
```

The `proxy` parameter on `BrowserConfig` is deprecated. Use `CrawlerRunConfig.proxy_config` or `CrawlerRunConfig.proxy_rotation_strategy` instead.

---

## Identity-Based Crawling

Use persistent browser profiles so websites recognize you as a returning human user.

### Managed Browsers

Store cookies, local storage, and session data in a persistent user data directory.

**Setup:** Create a profile by launching Chromium with `--user-data-dir`, log in to sites, then close:

```bash
# macOS
~/Library/Caches/ms-playwright/chromium-<version>/chrome-mac/Chromium.app/Contents/MacOS/Chromium \
    --user-data-dir=/Users/<you>/my_chrome_profile
# Linux
~/.cache/ms-playwright/chromium-<version>/chrome-linux/chrome \
    --user-data-dir=/home/<you>/my_chrome_profile
```

**Use in code:**

```python
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig

browser_config = BrowserConfig(
    headless=True,
    use_managed_browser=True,
    user_data_dir="/path/to/my_chrome_profile",
    browser_type="chromium",
)

async with AsyncWebCrawler(config=browser_config) as crawler:
    result = await crawler.arun(
        url="https://example.com/private",
        config=CrawlerRunConfig(wait_for="css:.logged-in-content"),
    )
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `use_managed_browser` | `bool` | Enable persistent browser profiles. |
| `user_data_dir` | `str` | Path to the persistent profile directory. |
| `browser_type` | `str` | `"chromium"`, `"firefox"`, or `"webkit"`. |

### BrowserProfiler

Programmatic API for managing browser profiles:

```python
from crawl4ai import BrowserProfiler

profiler = BrowserProfiler()
profile_path = await profiler.create_profile(profile_name="my-login-profile")
profiles = profiler.list_profiles()       # Returns list of dicts with name, path, created
path = profiler.get_profile_path("name")  # Get specific profile path
profiler.delete_profile("old-profile")    # Delete a profile
```

CLI alternative: `crwl profiles` launches an interactive profile manager.

### Magic Mode

Simulates human-like browsing without persistent profiles. Randomizes user agent, navigator, interactions, and timings. Masks automation signals and handles pop-ups.

```python
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig

async with AsyncWebCrawler() as crawler:
    result = await crawler.arun(
        url="https://example.com",
        config=CrawlerRunConfig(magic=True, remove_overlay_elements=True, page_timeout=60000),
    )
```

Not a replacement for managed browsers when persistent identity is needed.

### Locale, Timezone, and Geolocation

```python
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig, GeolocationConfig

browser_config = BrowserConfig(
    use_managed_browser=True,
    user_data_dir="/path/to/my-profile",
    browser_type="chromium",
)
crawl_config = CrawlerRunConfig(
    locale="fr-FR",
    timezone_id="Europe/Paris",
    geolocation=GeolocationConfig(latitude=48.8566, longitude=2.3522, accuracy=100),
)

async with AsyncWebCrawler(config=browser_config) as crawler:
    result = await crawler.arun(url="https://example.com", config=crawl_config)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `locale` | `str` | Browser locale (e.g., `"fr-FR"`). Affects language, date, number formats. |
| `timezone_id` | `str` | IANA timezone (e.g., `"Europe/Paris"`). Affects JS `Date` objects. |
| `geolocation` | `GeolocationConfig` | GPS coordinates: `latitude`, `longitude`, `accuracy` (meters). |

When `geolocation` is set, the browser is automatically granted location access.

---

## Dispatch Results

Each `CrawlResult` from `arun_many()` may include `dispatch_result` with concurrency metadata:

```python
@dataclass
class DispatchResult:
    task_id: str
    memory_usage: float      # MB
    peak_memory: float        # MB
    start_time: datetime
    end_time: datetime
    error_message: str = ""
```

Access via `result.dispatch_result`:

```python
for result in results:
    if result.success and result.dispatch_result:
        dr = result.dispatch_result
        print(f"{result.url}: {dr.memory_usage:.1f}MB, {dr.end_time - dr.start_time}")
```
