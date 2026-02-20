---
name: crawl4ai
description: >
  crawl4ai 라이브러리를 사용한 웹 크롤링/스크래핑 코드 작성 시 최신 API 문서를 참조하여 정확한 코드를 생성하는 스킬.
  Trigger keywords: crawl4ai, AsyncWebCrawler, BrowserConfig, CrawlerRunConfig,
  web crawler, web scraper, crawling, scraping, extract data from website,
  JsonCssExtractionStrategy, LLMExtractionStrategy, CrawlResult,
  headless browser, playwright crawl, markdown extraction,
  deep crawl, adaptive crawl, session management, arun, arun_many,
  PruningContentFilter, BM25ContentFilter, DefaultMarkdownGenerator
---

# crawl4ai Documentation-Aware Coding Skill

## Purpose

crawl4ai는 빈번하게 API가 변경되는 라이브러리입니다. 레거시 파라미터 전달 방식(kwargs)은 더 이상 지원되지 않으며, 반드시 config 객체(BrowserConfig, CrawlerRunConfig)를 사용해야 합니다.

**절대로 기억에 의존하여 crawl4ai 코드를 작성하지 마세요. 반드시 아래 레퍼런스를 참조하세요.**

### Rules

1. 모든 코드는 **config 객체 API**를 사용 (BrowserConfig, CrawlerRunConfig)
2. 레거시 kwargs 방식 절대 금지 (예: `crawler.arun(url, headless=True)` ❌)
3. 코드 작성 전 반드시 해당 레퍼런스 파일을 Read로 확인
4. import 경로는 레퍼런스에 명시된 것만 사용
5. 불확실한 API는 추측하지 말고 레퍼런스 확인

---

## Quick Start

### 기본 크롤링

```python
import asyncio
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig, CacheMode

async def main():
    browser_config = BrowserConfig(headless=True)
    run_config = CrawlerRunConfig(cache_mode=CacheMode.BYPASS)

    async with AsyncWebCrawler(config=browser_config) as crawler:
        result = await crawler.arun(url="https://example.com", config=run_config)
        if result.success:
            print(result.markdown.raw_markdown[:500])

if __name__ == "__main__":
    asyncio.run(main())
```

### CSS 기반 구조화 추출

```python
import json
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig, CacheMode
from crawl4ai import JsonCssExtractionStrategy

schema = {
    "name": "Products",
    "baseSelector": "div.product",
    "fields": [
        {"name": "title", "selector": "h2", "type": "text"},
        {"name": "price", "selector": ".price", "type": "text"},
        {"name": "link", "selector": "a", "type": "attribute", "attribute": "href"}
    ]
}

run_config = CrawlerRunConfig(
    cache_mode=CacheMode.BYPASS,
    extraction_strategy=JsonCssExtractionStrategy(schema)
)

async with AsyncWebCrawler() as crawler:
    result = await crawler.arun(url="https://example.com/products", config=run_config)
    data = json.loads(result.extracted_content)
```

### LLM 기반 추출

```python
from pydantic import BaseModel, Field
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig, CacheMode, LLMConfig
from crawl4ai import LLMExtractionStrategy

class Product(BaseModel):
    name: str = Field(description="Product name")
    price: float = Field(description="Price in USD")

run_config = CrawlerRunConfig(
    cache_mode=CacheMode.BYPASS,
    extraction_strategy=LLMExtractionStrategy(
        llm_config=LLMConfig(provider="openai/gpt-4o", api_token="..."),
        schema=Product.model_json_schema(),
        extraction_type="schema",
        instruction="Extract all products with their prices."
    )
)

async with AsyncWebCrawler() as crawler:
    result = await crawler.arun(url="https://example.com/products", config=run_config)
```

---

## Core Architecture

```
AsyncWebCrawler(config=BrowserConfig)
    ├── .arun(url, config=CrawlerRunConfig) → CrawlResult
    └── .arun_many(urls, config=CrawlerRunConfig) → List[CrawlResult] | AsyncGenerator

BrowserConfig   → 브라우저 설정 (browser_type, headless, proxy, stealth, viewport...)
CrawlerRunConfig → 크롤 실행 설정 (cache, extraction, js_code, wait_for, session...)
CrawlResult     → 결과 (html, markdown, extracted_content, media, links, screenshot...)
LLMConfig       → LLM 설정 (provider, api_token, base_url)
```

**핵심 패턴:** 항상 `async with AsyncWebCrawler(config=...) as crawler:` 컨텍스트 매니저 사용.

---

## Extraction Strategy 선택 가이드

| 상황 | 전략 | LLM 필요 | 비용 |
|------|------|----------|------|
| 반복적인 HTML 구조 (목록, 테이블) | `JsonCssExtractionStrategy` | No | Free |
| XPath가 더 편한 복잡한 DOM | `JsonXPathExtractionStrategy` | No | Free |
| 이메일/전화번호 등 패턴 추출 | `RegexExtractionStrategy` | No | Free |
| 비정형 콘텐츠에서 구조화 데이터 | `LLMExtractionStrategy` | Yes | Per token |
| 유사 콘텐츠 클러스터링 | `CosineStrategy` | No | Free |
| 깔끔한 마크다운만 필요 | `DefaultMarkdownGenerator` + Filter | No | Free |

→ 상세: `references/extraction.md`

---

## Common Patterns

### 1. 기본 마크다운 크롤링

```python
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig, CacheMode
from crawl4ai.markdown_generation_strategy import DefaultMarkdownGenerator
from crawl4ai.content_filter_strategy import PruningContentFilter

run_config = CrawlerRunConfig(
    cache_mode=CacheMode.BYPASS,
    markdown_generator=DefaultMarkdownGenerator(
        content_filter=PruningContentFilter(threshold=0.4, threshold_type="fixed"),
        options={"ignore_links": True}
    )
)
```

### 2. CSS 추출 (스키마 자동 생성)

```python
from crawl4ai import JsonCssExtractionStrategy, LLMConfig

schema = JsonCssExtractionStrategy.generate_schema(
    html_content,
    llm_config=LLMConfig(provider="openai/gpt-4o", api_token="...")
)
strategy = JsonCssExtractionStrategy(schema)
```

### 3. 세션 기반 페이지네이션

```python
run_config = CrawlerRunConfig(
    session_id="my_session",
    js_code="document.querySelector('.next-btn').click();",
    wait_for="css:.item",
    js_only=True,  # 이미 열린 페이지에서 JS만 실행
    cache_mode=CacheMode.BYPASS
)
```

### 4. 딥 크롤링

```python
from crawl4ai.deep_crawling import BFSDeepCrawlStrategy
from crawl4ai.deep_crawling.filters import FilterChain, URLPatternFilter, DomainFilter

run_config = CrawlerRunConfig(
    deep_crawl_strategy=BFSDeepCrawlStrategy(
        max_depth=3,
        max_pages=50,
        filter_chain=FilterChain([
            DomainFilter(allowed_domains=["example.com"]),
            URLPatternFilter(patterns=["*/blog/*"])
        ])
    )
)
```

### 5. 병렬 크롤링 (스트리밍)

```python
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig, CacheMode

run_config = CrawlerRunConfig(cache_mode=CacheMode.BYPASS, stream=True)

async with AsyncWebCrawler() as crawler:
    async for result in await crawler.arun_many(urls, config=run_config):
        if result.success:
            print(f"[OK] {result.url}")
```

### 6. JS 실행 + 대기

```python
run_config = CrawlerRunConfig(
    js_code=["""
    (async () => {
        const btn = document.querySelector('button.load-more');
        if (btn) btn.click();
        await new Promise(r => setTimeout(r, 2000));
    })();
    """],
    wait_for="css:.loaded-content",
    delay_before_return_html=1.0,
    cache_mode=CacheMode.BYPASS
)
```

---

## Import Cheat Sheet

| Class / Function | Import Path |
|-----------------|-------------|
| `AsyncWebCrawler` | `from crawl4ai import AsyncWebCrawler` |
| `BrowserConfig` | `from crawl4ai import BrowserConfig` |
| `CrawlerRunConfig` | `from crawl4ai import CrawlerRunConfig` |
| `CacheMode` | `from crawl4ai import CacheMode` |
| `LLMConfig` | `from crawl4ai import LLMConfig` |
| `AdaptiveConfig` | `from crawl4ai import AdaptiveConfig` |
| `ProxyConfig` | `from crawl4ai import ProxyConfig` |
| `RoundRobinProxyStrategy` | `from crawl4ai.proxy_strategy import RoundRobinProxyStrategy` |
| `VirtualScrollConfig` | `from crawl4ai import VirtualScrollConfig` |
| `GeolocationConfig` | `from crawl4ai import GeolocationConfig` |
| `JsonCssExtractionStrategy` | `from crawl4ai import JsonCssExtractionStrategy` |
| `JsonXPathExtractionStrategy` | `from crawl4ai import JsonXPathExtractionStrategy` |
| `LLMExtractionStrategy` | `from crawl4ai import LLMExtractionStrategy` |
| `RegexExtractionStrategy` | `from crawl4ai import RegexExtractionStrategy` |
| `CosineStrategy` | `from crawl4ai import CosineStrategy` |
| `RegexChunking` | `from crawl4ai.chunking_strategy import RegexChunking` |
| `SlidingWindowChunking` | `from crawl4ai.chunking_strategy import SlidingWindowChunking` |
| `OverlappingWindowChunking` | `from crawl4ai.chunking_strategy import OverlappingWindowChunking` |
| `FixedLengthWordChunking` | `from crawl4ai.chunking_strategy import FixedLengthWordChunking` |
| `DefaultMarkdownGenerator` | `from crawl4ai.markdown_generation_strategy import DefaultMarkdownGenerator` |
| `PruningContentFilter` | `from crawl4ai.content_filter_strategy import PruningContentFilter` |
| `BM25ContentFilter` | `from crawl4ai.content_filter_strategy import BM25ContentFilter` |
| `LLMContentFilter` | `from crawl4ai.content_filter_strategy import LLMContentFilter` |
| `RelevantContentFilter` | `from crawl4ai.content_filter_strategy import RelevantContentFilter` |
| `DefaultTableExtraction` | `from crawl4ai import DefaultTableExtraction` |
| `LLMTableExtraction` | `from crawl4ai import LLMTableExtraction` |
| `NoTableExtraction` | `from crawl4ai import NoTableExtraction` |
| `BFSDeepCrawlStrategy` | `from crawl4ai.deep_crawling import BFSDeepCrawlStrategy` |
| `DFSDeepCrawlStrategy` | `from crawl4ai.deep_crawling import DFSDeepCrawlStrategy` |
| `BestFirstCrawlingStrategy` | `from crawl4ai.deep_crawling import BestFirstCrawlingStrategy` |
| `FilterChain` | `from crawl4ai.deep_crawling.filters import FilterChain` |
| `URLPatternFilter` | `from crawl4ai.deep_crawling.filters import URLPatternFilter` |
| `DomainFilter` | `from crawl4ai.deep_crawling.filters import DomainFilter` |
| `ContentTypeFilter` | `from crawl4ai.deep_crawling.filters import ContentTypeFilter` |
| `ContentRelevanceFilter` | `from crawl4ai.deep_crawling.filters import ContentRelevanceFilter` |
| `SEOFilter` | `from crawl4ai.deep_crawling.filters import SEOFilter` |
| `KeywordRelevanceScorer` | `from crawl4ai.deep_crawling.scorers import KeywordRelevanceScorer` |
| `AdaptiveCrawler` | `from crawl4ai import AdaptiveCrawler` |
| `BrowserProfiler` | `from crawl4ai import BrowserProfiler` |
| `UndetectedAdapter` | `from crawl4ai import UndetectedAdapter` |
| `PlaywrightAdapter` | `from crawl4ai import PlaywrightAdapter` |
| `AsyncPlaywrightCrawlerStrategy` | `from crawl4ai.async_crawler_strategy import AsyncPlaywrightCrawlerStrategy` |
| `AsyncHTTPCrawlerStrategy` | `from crawl4ai.async_crawler_strategy import AsyncHTTPCrawlerStrategy` |
| `LXMLWebScrapingStrategy` | `from crawl4ai import LXMLWebScrapingStrategy` |
| `MemoryAdaptiveDispatcher` | `from crawl4ai.async_dispatcher import MemoryAdaptiveDispatcher` |
| `SemaphoreDispatcher` | `from crawl4ai.async_dispatcher import SemaphoreDispatcher` |
| `CrawlerMonitor` | `from crawl4ai import CrawlerMonitor` |
| `DisplayMode` | `from crawl4ai import DisplayMode` |
| `RateLimiter` | `from crawl4ai import RateLimiter` |
| `MatchMode` | `from crawl4ai import MatchMode` |
| `PDFContentScrapingStrategy` | `from crawl4ai.processors.pdf import PDFContentScrapingStrategy` |
| `PDFCrawlerStrategy` | `from crawl4ai.processors.pdf import PDFCrawlerStrategy` |

### 설치

```bash
pip install crawl4ai
crawl4ai-setup          # Playwright 브라우저 설치
```

---

## Workflow

### Step 1: 요청 분류

사용자의 요청을 아래 카테고리로 분류하고 해당 레퍼런스를 Read합니다.

### Step 2: 레퍼런스 확인

**반드시** 해당 레퍼런스 파일을 Read한 후 코드를 작성합니다.

### Step 3: 코드 작성

레퍼런스의 코드 예제와 API 시그니처를 기반으로 코드를 작성합니다.

**규칙:**
- 레퍼런스의 import 경로를 그대로 사용
- config 객체 API만 사용 (레거시 kwargs 금지)
- result.markdown은 MarkdownGenerationResult 객체 (`.raw_markdown`, `.fit_markdown` 등)
- 불확실한 파라미터는 레퍼런스에서 확인

---

## Reference Navigation

| Topic | Reference File | 주요 내용 |
|-------|---------------|-----------|
| AsyncWebCrawler, BrowserConfig, CrawlerRunConfig, CrawlResult, CacheMode, LLMConfig | `references/core-api.md` | 생성자, arun(), 전체 파라미터, 결과 필드 |
| CSS/XPath/Regex/LLM 추출 전략 | `references/extraction.md` | 스키마 구조, 필드 타입, generate_schema(), Pydantic 연동 |
| 마크다운 생성, 콘텐츠 필터, 콘텐츠 선택 | `references/content-processing.md` | DefaultMarkdownGenerator, PruningContentFilter, BM25ContentFilter, css_selector |
| JS 실행, 대기 조건, 스크롤, 스텔스, 네트워크 캡처 | `references/browser-automation.md` | js_code, wait_for, scan_full_page, VirtualScrollConfig, 스크린샷/PDF |
| 세션, 훅, 인증, 딥크롤, 어댑티브 크롤 | `references/advanced-crawling.md` | session_id, hooks, 로그인, BFS/DFS, AdaptiveCrawler |
| arun_many, 디스패처, 프록시, URL별 설정 | `references/parallel-and-proxy.md` | 배치/스트리밍, MemoryAdaptiveDispatcher, ProxyConfig |
