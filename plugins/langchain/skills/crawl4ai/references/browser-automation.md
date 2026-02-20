# Browser Automation & Page Interaction

Reference for browser-level control in Crawl4AI: JS execution, wait conditions, scrolling, virtual scroll, stealth/anti-detection, network capture, screenshots/PDF, and file downloads.

## Table of Contents

- [JS Execution](#js-execution)
- [Wait Conditions](#wait-conditions)
- [Scrolling](#scrolling)
- [Virtual Scrolling](#virtual-scrolling)
- [Stealth and Anti-Detection](#stealth-and-anti-detection)
- [Network and Console Capture](#network-and-console-capture)
- [Screenshots and PDF](#screenshots-and-pdf)
- [File Downloads](#file-downloads)

---

## JS Execution

`js_code` on `CrawlerRunConfig` accepts a single string or a list of strings to run after page load.

```python
import asyncio
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig

async def main():
    # Single command
    config = CrawlerRunConfig(
        js_code="window.scrollTo(0, document.body.scrollHeight);"
    )
    # Multiple commands (executed in sequence)
    config = CrawlerRunConfig(
        js_code=[
            "window.scrollTo(0, document.body.scrollHeight);",
            "document.querySelector('a.morelink')?.click();",
        ]
    )
    async with AsyncWebCrawler() as crawler:
        result = await crawler.arun(url="https://example.com", config=config)

asyncio.run(main())
```

### Session Reuse with js_only

For multi-step interactions (pagination, "Load More"), combine `session_id` with `js_only=True` to run JS in an already-open tab without re-navigating.

```python
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig, CacheMode

async def main():
    async with AsyncWebCrawler() as crawler:
        # Step 1: Initial load
        await crawler.arun(url="https://news.ycombinator.com", config=CrawlerRunConfig(
            wait_for="css:.athing:nth-child(30)", session_id="hn", cache_mode=CacheMode.BYPASS
        ))
        # Step 2: Click "More" in existing session (no re-navigation)
        result = await crawler.arun(url="https://news.ycombinator.com", config=CrawlerRunConfig(
            js_code="document.querySelector('a.morelink')?.click();",
            wait_for="js:() => document.querySelectorAll('.athing').length > 30",
            js_only=True, session_id="hn", cache_mode=CacheMode.BYPASS
        ))
        await crawler.crawler_strategy.kill_session("hn")
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `js_code` | `str \| list[str]` | JavaScript to execute after page load |
| `js_only` | `bool` | Skip navigation; run JS in existing session. Requires `session_id` |
| `session_id` | `str` | Reuse the same browser tab across `arun()` calls |

---

## Wait Conditions

### CSS Selector Waiting

Prefix with `css:` to poll until the selector matches:

```python
config = CrawlerRunConfig(wait_for="css:.athing:nth-child(30)")
```

### JavaScript Function Waiting

Prefix with `js:` and supply a function returning `true` when ready:

```python
config = CrawlerRunConfig(
    wait_for="js:() => document.querySelectorAll('.item').length > 50"
)
```

### Page Load Events (wait_until)

Controls when initial navigation is considered complete:

| Value | Behavior |
|-------|----------|
| `"load"` | Wait for the `load` event |
| `"domcontentloaded"` | HTML parsed; subresources may still load (default) |
| `"networkidle"` | No network connections for 500ms |
| `"commit"` | First network response received (fastest) |

### Timing Controls

```python
config = CrawlerRunConfig(
    page_timeout=60000,           # ms -- overall time limit
    delay_before_return_html=2.0  # seconds -- pause before capturing final HTML
)
```

---

## Scrolling

### Full Page Scanning

`scan_full_page=True` scrolls top to bottom, triggering lazy-loaded content. `scroll_delay` pauses between steps.

```python
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig

async def main():
    config = CrawlerRunConfig(
        scan_full_page=True,
        scroll_delay=0.5,
        wait_for_images=True
    )
    async with AsyncWebCrawler(config=BrowserConfig(headless=True)) as crawler:
        result = await crawler.arun(url="https://example.com/gallery", config=config)
        images = result.media.get("images", [])
        print(f"Images found: {len(images)}")
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `scan_full_page` | `bool` | `False` | Scroll entire page top to bottom |
| `scroll_delay` | `float` | `0.2` | Seconds between scroll steps |
| `wait_for_images` | `bool` | `False` | Wait for images to finish loading |
| `process_iframes` | `bool` | `False` | Include content from `<iframe>` elements |

For lazy-loaded images with placeholder transitions, add a CSS wait:

```python
config = CrawlerRunConfig(
    scan_full_page=True, scroll_delay=0.5,
    wait_for="css:img.loaded"
)
```

---

## Virtual Scrolling

Virtual scrolling (Twitter, Instagram, data tables) **replaces** DOM content on scroll instead of appending. `VirtualScrollConfig` scrolls the container, captures HTML at each position, and merges unique content.

```python
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig, VirtualScrollConfig

async def main():
    config = CrawlerRunConfig(
        virtual_scroll_config=VirtualScrollConfig(
            container_selector="#feed",
            scroll_count=20,
            scroll_by="container_height",
            wait_after_scroll=0.5
        )
    )
    async with AsyncWebCrawler() as crawler:
        result = await crawler.arun(url="https://example.com/feed", config=config)
        # result.html contains ALL items merged from every scroll position
```

### VirtualScrollConfig Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `container_selector` | `str` | **Required** | CSS selector for the scrollable container |
| `scroll_count` | `int` | `10` | Number of scrolls to perform |
| `scroll_by` | `str \| int` | `"container_height"` | `"container_height"`, `"page_height"`, or pixel int |
| `wait_after_scroll` | `float` | `0.5` | Seconds to wait after each scroll |

### When to Use Which

| Aspect | VirtualScrollConfig | scan_full_page |
|--------|-------------------|----------------|
| DOM behavior | Content replaced on scroll | Content appended on scroll |
| Use case | Twitter, Instagram, virtual tables | Infinite scroll, lazy images |
| Merging | Auto-deduplicates across positions | Captures final accumulated state |
| Selector needed | Yes | No |

---

## Stealth and Anti-Detection

### Stealth Mode

`enable_stealth=True` on `BrowserConfig` applies playwright-stealth patches: removes `navigator.webdriver`, fixes fingerprints, emulates plugins.

```python
from crawl4ai import AsyncWebCrawler, BrowserConfig

browser_config = BrowserConfig(enable_stealth=True, headless=False)
async with AsyncWebCrawler(config=browser_config) as crawler:
    result = await crawler.arun("https://example.com")
```

### Undetected Browser Mode

For sophisticated detection (Cloudflare, DataDome), use `UndetectedAdapter` with deep browser patches. Combine with stealth for maximum evasion.

```python
from crawl4ai import (
    AsyncWebCrawler, BrowserConfig, CrawlerRunConfig, UndetectedAdapter
)
from crawl4ai.async_crawler_strategy import AsyncPlaywrightCrawlerStrategy

# Undetected only
browser_config = BrowserConfig(headless=False)
strategy = AsyncPlaywrightCrawlerStrategy(
    browser_config=browser_config, browser_adapter=UndetectedAdapter()
)

# Combined: stealth + undetected (maximum evasion)
browser_config = BrowserConfig(enable_stealth=True, headless=False)
strategy = AsyncPlaywrightCrawlerStrategy(
    browser_config=browser_config, browser_adapter=UndetectedAdapter()
)

async with AsyncWebCrawler(crawler_strategy=strategy, config=browser_config) as crawler:
    result = await crawler.arun("https://protected-site.com", config=CrawlerRunConfig())
```

| Feature | Regular | Stealth | Undetected |
|---------|---------|---------|------------|
| WebDriver bypass | No | Yes | Yes |
| Navigator fixes | No | Yes | Yes |
| Plugin emulation | No | Yes | Yes |
| CDP detection bypass | No | Partial | Yes |
| Deep patches | No | No | Yes |

### Additional Anti-Bot CrawlerRunConfig Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `simulate_user` | `bool` | Simulate human-like interaction patterns |
| `override_navigator` | `bool` | Override navigator properties to mask automation |
| `magic` | `bool` | Combine multiple evasion techniques automatically |

Progressive approach: (1) `enable_stealth=True`, (2) add `UndetectedAdapter`, (3) add `simulate_user=True` and `magic=True`.

---

## Network and Console Capture

Enable `capture_network_requests` and `capture_console_messages` on `CrawlerRunConfig`. Access captured data from `result.network_requests` and `result.console_messages`.

```python
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig

async def main():
    config = CrawlerRunConfig(
        capture_network_requests=True,
        capture_console_messages=True
    )
    async with AsyncWebCrawler() as crawler:
        result = await crawler.arun(url="https://example.com", config=config)
        if result.network_requests:
            reqs = [r for r in result.network_requests if r["event_type"] == "request"]
            print(f"Captured {len(reqs)} requests")
        if result.console_messages:
            errors = [m for m in result.console_messages if m["type"] == "error"]
            print(f"Console errors: {len(errors)}")
```

### Network Request Data Structure

Each dict in `result.network_requests` has an `event_type` field:

- **`"request"`** -- fields: `url`, `method`, `headers`, `post_data`, `resource_type`, `is_navigation_request`, `timestamp`
- **`"response"`** -- fields: `url`, `status`, `status_text`, `headers`, `from_service_worker`, `request_timing`, `timestamp`
- **`"request_failed"`** -- fields: `url`, `method`, `resource_type`, `failure_text`, `timestamp`

### Console Message Data Structure

Each dict in `result.console_messages` has fields: `type` (`"log"`, `"error"`, `"warning"`, `"info"`), `text`, `location`, `timestamp`.

---

## Screenshots and PDF

| Parameter | Type | Description |
|-----------|------|-------------|
| `screenshot` | `bool` | Capture screenshot; base64 in `result.screenshot` |
| `pdf` | `bool` | Capture PDF; raw bytes in `result.pdf` |
| `screenshot_wait_for` | `float` | Seconds to wait before taking screenshot |

```python
import base64
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig

async def main():
    config = CrawlerRunConfig(screenshot=True, pdf=True, screenshot_wait_for=2.0)
    async with AsyncWebCrawler() as crawler:
        result = await crawler.arun(url="https://example.com", config=config)
        if result.screenshot:
            with open("page.png", "wb") as f:
                f.write(base64.b64decode(result.screenshot))
        if result.pdf:
            with open("page.pdf", "wb") as f:
                f.write(result.pdf)
```

---

## File Downloads

Configure downloads on `BrowserConfig` with `accept_downloads=True` and optional `downloads_path` (defaults to `~/.crawl4ai/downloads/`). Trigger downloads via `js_code` and use `wait_for` (numeric seconds) to allow time for completion. Results appear in `result.downloaded_files`.

```python
import os
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig

async def main():
    dl_path = os.path.join(os.getcwd(), "my_downloads")
    os.makedirs(dl_path, exist_ok=True)

    browser_config = BrowserConfig(accept_downloads=True, downloads_path=dl_path)
    run_config = CrawlerRunConfig(
        js_code="""
            const link = document.querySelector('a[href$=".pdf"]');
            if (link) link.click();
        """,
        wait_for=5
    )
    async with AsyncWebCrawler(config=browser_config) as crawler:
        result = await crawler.arun(url="https://example.com/downloads", config=run_config)
        if result.downloaded_files:
            for path in result.downloaded_files:
                print(f"Downloaded: {path} ({os.path.getsize(path)} bytes)")
```

For multiple files, iterate with delays between clicks:

```python
run_config = CrawlerRunConfig(
    js_code="""
        const links = document.querySelectorAll('a[download]');
        for (const link of links) {
            link.click();
            await new Promise(r => setTimeout(r, 2000));
        }
    """,
    wait_for=10
)
```

| BrowserConfig Param | Type | Description |
|---------------------|------|-------------|
| `accept_downloads` | `bool` | Enable file downloads |
| `downloads_path` | `str` | Directory to save downloaded files |
