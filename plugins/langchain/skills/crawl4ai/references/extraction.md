# Crawl4AI Extraction Strategies Reference

## Table of Contents

- [JsonCssExtractionStrategy](#jsoncssextractionstrategy)
- [JsonXPathExtractionStrategy](#jsonxpathextractionstrategy)
- [RegexExtractionStrategy](#regexextractionstrategy)
- [LLMExtractionStrategy](#llmextractionstrategy)
- [CosineStrategy](#cosinestrategy)
- [Chunking Strategies](#chunking-strategies)
- [Strategy Selection Guide](#strategy-selection-guide)

All strategies are set via `CrawlerRunConfig(extraction_strategy=...)`. Extracted data is on `result.extracted_content` as a JSON string.

---

## JsonCssExtractionStrategy

CSS selector-based structured JSON extraction. Best for pages with consistent, repeating HTML structures.

```python
from crawl4ai import JsonCssExtractionStrategy
```

### Schema Structure

```python
schema = {
    "name": "Schema Name",           # Descriptive name
    "baseSelector": "div.item",       # CSS selector for each repeating container
    "baseFields": [                   # Optional: extract attributes from the container itself
        {"name": "item_id", "type": "attribute", "attribute": "data-id"}
    ],
    "fields": [                       # Fields to extract from each container
        {"name": "field_name", "selector": "h2.title", "type": "text", "default": None}
    ]
}
strategy = JsonCssExtractionStrategy(schema, verbose=True)
```

### Field Types

| Type | Description | Extra Keys |
|------|-------------|------------|
| `text` | Text content of the element | -- |
| `attribute` | HTML attribute value | `"attribute": "href"` |
| `html` | Raw inner HTML | -- |
| `regex` | Regex applied to element text | `"pattern": r"\d+"` |
| `nested` | Single child object | `"fields": [...]` |
| `list` | Multiple simple child items | `"fields": [...]` |
| `nested_list` | List of complex child objects | `"fields": [...]` |

Fields also accept `"transform"` (`"lowercase"`, `"uppercase"`, `"strip"`) and `"default"` (fallback value).

```python
{"name": "title", "selector": "h2.title", "type": "text"}
{"name": "link", "selector": "a", "type": "attribute", "attribute": "href"}
{"name": "desc", "selector": "div.desc", "type": "html"}
{"name": "year", "selector": "span.date", "type": "regex", "pattern": r"\b(20\d{2})\b"}
```

### Nested and List Structures

- **`nested`** -- single child object (e.g., product details)
- **`list`** -- repeated simple items (e.g., feature bullets)
- **`nested_list`** -- repeated complex objects (e.g., reviews)

```python
{"name": "products", "selector": "div.product", "type": "nested_list", "fields": [
    {"name": "name", "selector": "h3", "type": "text"},
    {"name": "price", "selector": ".price", "type": "text"},
    {"name": "details", "selector": "div.details", "type": "nested", "fields": [
        {"name": "brand", "selector": "span.brand", "type": "text"},
        {"name": "model", "selector": "span.model", "type": "text"}
    ]},
    {"name": "features", "selector": "ul.features li", "type": "list", "fields": [
        {"name": "feature", "type": "text"}
    ]},
    {"name": "reviews", "selector": "div.review", "type": "nested_list", "fields": [
        {"name": "reviewer", "selector": "span.reviewer", "type": "text"},
        {"name": "rating", "selector": "span.rating", "type": "text"},
        {"name": "comment", "selector": "p.text", "type": "text"}
    ]}
]}
```

### Complete Example

```python
import json, asyncio
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig, CacheMode, JsonCssExtractionStrategy

schema = {
    "name": "Products",
    "baseSelector": "div.product-card",
    "fields": [
        {"name": "title", "selector": "h2.title", "type": "text"},
        {"name": "price", "selector": ".price", "type": "text", "transform": "strip"},
        {"name": "image", "selector": "img", "type": "attribute", "attribute": "src"}
    ]
}

async def main():
    config = CrawlerRunConfig(
        extraction_strategy=JsonCssExtractionStrategy(schema, verbose=True),
        cache_mode=CacheMode.BYPASS
    )
    async with AsyncWebCrawler() as crawler:
        result = await crawler.arun(url="https://example.com/products", config=config)
        if result.success:
            data = json.loads(result.extracted_content)
            print(f"Extracted {len(data)} products")

asyncio.run(main())
```

### generate_schema() Helper

Uses an LLM once to auto-generate a schema from sample HTML. The schema is then reused without further LLM calls.

```python
from crawl4ai import JsonCssExtractionStrategy, LLMConfig

html = '<div class="product"><h2>Laptop</h2><span class="price">$999</span></div>'

schema = JsonCssExtractionStrategy.generate_schema(
    html,
    schema_type="css",
    llm_config=LLMConfig(provider="openai/gpt-4o", api_token="your-token")
)
strategy = JsonCssExtractionStrategy(schema)  # No more LLM calls
```

For varying DOM structures, pass multiple HTML samples with a `query` requesting stable selectors (class names, `data-*` attributes) over fragile `nth-child()`. Provider options: `"openai/gpt-4o"` or `"ollama/llama3.3"` (self-hosted, `api_token=None`).

---

## JsonXPathExtractionStrategy

Same concept as `JsonCssExtractionStrategy` but uses XPath expressions. Prefer when you need text-content matching, parent/ancestor axis traversal, or complex conditional logic.

```python
from crawl4ai import JsonXPathExtractionStrategy
```

### XPath Schema Structure

```python
schema = {
    "name": "Crypto Prices",
    "baseSelector": "//div[@class='crypto-row']",
    "fields": [
        {"name": "coin", "selector": ".//h2[@class='coin-name']", "type": "text"},
        {"name": "price", "selector": ".//span[@class='coin-price']", "type": "text"}
    ]
}
config = CrawlerRunConfig(
    extraction_strategy=JsonXPathExtractionStrategy(schema, verbose=True)
)
```

All field types (`text`, `attribute`, `html`, `nested`, `list`, `nested_list`, `regex`) work identically. Schema generation is available via `generate_schema(..., schema_type="xpath")`.

### CSS vs XPath Comparison

| Feature | CSS | XPath |
|---------|-----|-------|
| Base selector | `"div.product"` | `"//div[@class='product']"` |
| Child element | `"h2.title"` | `".//h2[@class='title']"` |
| Nth child | `"li:nth-child(2)"` | `".//li[2]"` |
| Text content match | Not supported | `".//td[contains(text(),'Price')]"` |
| Parent axis | Not supported | `".//span/parent::div"` |

Use `raw://` for local HTML testing: `await crawler.arun(url=f"raw://{html}", config=config)`

---

## RegexExtractionStrategy

Fast pattern-based extraction using pre-compiled regular expressions. No LLM calls.

```python
from crawl4ai import RegexExtractionStrategy
```

### Built-in Patterns

Exposed as `IntFlag` attributes, combinable with `|`:

```python
strategy = RegexExtractionStrategy(pattern=RegexExtractionStrategy.Email)

strategy = RegexExtractionStrategy(
    pattern=RegexExtractionStrategy.Email | RegexExtractionStrategy.PhoneUS | RegexExtractionStrategy.Url
)

strategy = RegexExtractionStrategy(pattern=RegexExtractionStrategy.All)
```

Available: `Email`, `PhoneIntl`, `PhoneUS`, `Url`, `IPv4`, `IPv6`, `Uuid`, `Currency`, `Percentage`, `Number`, `DateIso`, `DateUS`, `Time24h`, `PostalUS`, `PostalUK`, `HexColor`, `TwitterHandle`, `Hashtag`, `MacAddr`, `Iban`, `CreditCard`, `All`.

### Custom Patterns

Pass a dictionary mapping label names to regex strings. Can combine with built-in patterns:

```python
strategy = RegexExtractionStrategy(
    pattern=RegexExtractionStrategy.Email | RegexExtractionStrategy.PhoneUS,
    custom={"usd_price": r"\$\s?\d{1,3}(?:,\d{3})*(?:\.\d{2})?"}
)
config = CrawlerRunConfig(extraction_strategy=strategy)
```

### LLM-Assisted Pattern Generation

Generate an optimized regex with an LLM once, then cache and reuse it:

```python
pattern = RegexExtractionStrategy.generate_pattern(
    label="price", html=sample_html, query="Product prices in USD format",
    llm_config=LLMConfig(provider="openai/gpt-4o-mini", api_token="env:OPENAI_API_KEY")
)
strategy = RegexExtractionStrategy(custom=pattern)  # No further LLM calls
```

### Results Format

Each match: `{"url": "...", "label": "email", "value": "a@b.com", "span": [145, 152]}` -- `label` is the pattern name, `span` is character positions in source.

---

## LLMExtractionStrategy

Uses any LiteLLM-supported model for extraction. Best for unstructured content, semantic extraction, summarization, or knowledge graphs.

```python
from crawl4ai import LLMExtractionStrategy, LLMConfig
```

### Parameters

```python
LLMExtractionStrategy(
    llm_config=LLMConfig(...),            # Required: LLM provider config
    schema: dict = None,                  # Pydantic model JSON schema
    extraction_type: str = "block",       # "schema" or "block"
    instruction: str = None,              # Prompt for the LLM
    input_format: str = "markdown",       # "markdown", "html", or "fit_markdown"
    chunk_token_threshold: int = 4000,    # Max tokens per chunk
    overlap_rate: float = 0.1,            # Overlap ratio between chunks
    word_token_rate: float = 0.75,        # Word-to-token conversion rate
    apply_chunking: bool = True,          # Enable chunking
    extra_args: dict = {},                # temperature, max_tokens, top_p, etc.
    verbose: bool = False
)
```

### Using Pydantic Schemas

Define output structure as a Pydantic model, pass its JSON schema:

```python
import os, json, asyncio
from pydantic import BaseModel
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig, CacheMode, LLMConfig, LLMExtractionStrategy

class Product(BaseModel):
    name: str
    price: str

llm_strategy = LLMExtractionStrategy(
    llm_config=LLMConfig(provider="openai/gpt-4o-mini", api_token=os.getenv("OPENAI_API_KEY")),
    schema=Product.model_json_schema(),
    extraction_type="schema",
    instruction="Extract all products with 'name' and 'price' from the content.",
    chunk_token_threshold=1000,
    apply_chunking=True,
    input_format="markdown",
    extra_args={"temperature": 0.0, "max_tokens": 800}
)
config = CrawlerRunConfig(extraction_strategy=llm_strategy, cache_mode=CacheMode.BYPASS)
# Use: result = await crawler.arun(url="...", config=config)
# Then: data = json.loads(result.extracted_content)
```

### extraction_type: schema vs block

| Mode | Description | Use case |
|------|-------------|----------|
| `"schema"` | Returns JSON conforming to the Pydantic schema | Structured data with known fields |
| `"block"` | Returns freeform text or ad-hoc JSON | Summaries, classifications, open-ended |

For `"schema"`, always provide `schema=YourModel.model_json_schema()`.

### input_format Options

| Value | Content sent to LLM | When to use |
|-------|---------------------|-------------|
| `"markdown"` | Standard markdown output | Default; text-focused extraction |
| `"html"` | Cleaned HTML | When instructions reference HTML tags |
| `"fit_markdown"` | Filtered markdown (e.g., via `PruningContentFilter`) | Reduces token usage |

### Chunking Configuration

- **`chunk_token_threshold`** -- max tokens per chunk (default: 4000)
- **`overlap_rate`** -- fraction repeated in next chunk for context continuity (default: 0.1)
- **`apply_chunking`** -- `True` to enable, `False` for single-pass
- **`word_token_rate`** -- word-to-token ratio (default: 0.75)

Each chunk becomes a separate LLM call. Results are merged into the final JSON.

### LLMConfig Usage

```python
from crawl4ai import LLMConfig

llm_config = LLMConfig(
    provider="openai/gpt-4o-mini",          # <provider>/<model> per LiteLLM format
    api_token=os.getenv("OPENAI_API_KEY"),  # Or None for local models
    base_url=None                           # Optional custom endpoint
)
```

Common providers: `"openai/gpt-4o"`, `"openai/gpt-4o-mini"`, `"anthropic/claude-3-5-sonnet-20241022"`, `"ollama/llama3.3"`. The `api_token` supports `"env:VAR_NAME"` syntax.

### Knowledge Graph Example

```python
from pydantic import BaseModel
from typing import List

class Entity(BaseModel):
    name: str
    description: str

class Relationship(BaseModel):
    entity1: Entity
    entity2: Entity
    description: str
    relation_type: str

class KnowledgeGraph(BaseModel):
    entities: List[Entity]
    relationships: List[Relationship]

strategy = LLMExtractionStrategy(
    llm_config=LLMConfig(provider="openai/gpt-4", api_token=os.getenv("OPENAI_API_KEY")),
    schema=KnowledgeGraph.model_json_schema(),
    extraction_type="schema",
    instruction="Extract entities and relationships from the content.",
    chunk_token_threshold=1400,
    apply_chunking=True,
    input_format="html",
    extra_args={"temperature": 0.1, "max_tokens": 1500}
)
config = CrawlerRunConfig(extraction_strategy=strategy, cache_mode=CacheMode.BYPASS)
```

### Token Usage Tracking

```python
llm_strategy.show_usage()       # Prints summary
llm_strategy.usages             # List of per-chunk token usage
llm_strategy.total_usage        # Total tokens across all chunks
```

---

## CosineStrategy

Embedding-based similarity clustering for semantic content extraction. Useful when page structure is inconsistent or you need topic-based filtering.

```python
from crawl4ai import CosineStrategy

strategy = CosineStrategy(
    semantic_filter="product reviews",    # Target topic/keywords
    word_count_threshold=10,              # Min words per cluster
    sim_threshold=0.3,                    # Similarity threshold (0.0-1.0)
    max_dist=0.2,                         # Max cluster distance
    linkage_method="ward",                # Clustering method
    top_k=3,                              # Top clusters to return
    model_name="sentence-transformers/all-MiniLM-L6-v2"
)
config = CrawlerRunConfig(extraction_strategy=strategy)
```

Works by: chunking content, computing embeddings, clustering similar chunks, filtering by `semantic_filter` relevance, returning top-k clusters. Effective as a pre-processing step before LLM extraction.

---

## Chunking Strategies

Split large texts into segments. Used internally by `LLMExtractionStrategy` and `CosineStrategy`, or directly for RAG pipelines.

```python
from crawl4ai.chunking_strategy import (
    RegexChunking, SlidingWindowChunking, OverlappingWindowChunking, FixedLengthWordChunking
)
```

### RegexChunking

Splits on regex patterns. Default: double newlines (paragraphs).

```python
chunker = RegexChunking(patterns=[r'\n\n'])
chunks = chunker.chunk(text)
```

### SlidingWindowChunking

Overlapping chunks via sliding window.

```python
chunker = SlidingWindowChunking(window_size=100, step=50)  # words
chunks = chunker.chunk(text)
```

### OverlappingWindowChunking

Fixed-size chunks with specified word overlap.

```python
chunker = OverlappingWindowChunking(window_size=1000, overlap=100)  # words
chunks = chunker.chunk(text)
```

### FixedLengthWordChunking

Fixed word count per chunk, no overlap.

```python
chunker = FixedLengthWordChunking(chunk_size=100)  # words
chunks = chunker.chunk(text)
```

**Passing a chunker to LLMExtractionStrategy:**

```python
from crawl4ai.chunking_strategy import OverlappingWindowChunking
from crawl4ai import LLMExtractionStrategy, LLMConfig

strategy = LLMExtractionStrategy(
    llm_config=LLMConfig(provider="openai/gpt-4o-mini", api_token="..."),
    chunking_strategy=OverlappingWindowChunking(window_size=500, overlap=50),
    instruction="Extract key facts from each section."
)
```

---

## Strategy Selection Guide

| Strategy | Speed | Cost | Deterministic | Best for |
|----------|-------|------|---------------|----------|
| `RegexExtractionStrategy` | Fastest | Free | Yes | Emails, URLs, phones, dates, custom patterns |
| `JsonCssExtractionStrategy` | Fast | Free | Yes | Structured HTML with CSS-selectable elements |
| `JsonXPathExtractionStrategy` | Fast | Free | Yes | Same, when XPath is more precise |
| `LLMExtractionStrategy` | Slow | API cost | No | Unstructured content, summaries, knowledge graphs |
| `CosineStrategy` | Medium | Free | Yes | Topic-based content filtering and clustering |
