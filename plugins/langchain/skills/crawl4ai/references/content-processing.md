# Content Processing Reference

## Table of Contents

- [DefaultMarkdownGenerator](#defaultmarkdowngenerator)
  - [Options](#options)
  - [Content Source Selection](#content-source-selection)
  - [Link Citations](#link-citations)
- [MarkdownGenerationResult](#markdowngenerationresult)
- [Content Filters](#content-filters)
  - [PruningContentFilter](#pruningcontentfilter)
  - [BM25ContentFilter](#bm25contentfilter)
  - [LLMContentFilter](#llmcontentfilter)
  - [Combining Filters](#combining-filters)
  - [Custom Filters](#custom-filters)
- [Content Selection via CrawlerRunConfig](#content-selection-via-crawlerrunconfig)
  - [css_selector](#css_selector)
  - [target_elements](#target_elements)
  - [excluded_tags](#excluded_tags)
  - [Other Selection Parameters](#other-selection-parameters)
- [Link and Media Analysis](#link-and-media-analysis)
  - [result.links](#resultlinks)
  - [Domain Filtering](#domain-filtering)
  - [result.media](#resultmedia)
  - [Image Filtering](#image-filtering)
- [Table Extraction](#table-extraction)
  - [DefaultTableExtraction](#defaulttableextraction)
  - [NoTableExtraction](#notableextraction)
  - [LLMTableExtraction](#llmtableextraction)
  - [Extracted Table Structure](#extracted-table-structure)

---

## DefaultMarkdownGenerator

Converts final HTML into clean, structured markdown. Passed to `CrawlerRunConfig` via `markdown_generator`.

```python
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig
from crawl4ai.markdown_generation_strategy import DefaultMarkdownGenerator

md_generator = DefaultMarkdownGenerator(
    options={"ignore_links": True, "escape_html": False, "body_width": 80}
)
config = CrawlerRunConfig(markdown_generator=md_generator)

async with AsyncWebCrawler() as crawler:
    result = await crawler.arun("https://example.com", config=config)
    print(result.markdown.raw_markdown[:500])
```

### Options

The `options` dict controls the HTML-to-text conversion:

| Option | Type | Description |
|--------|------|-------------|
| `ignore_links` | `bool` | Remove all hyperlinks from final markdown. |
| `ignore_images` | `bool` | Remove all `![image]()` references. |
| `escape_html` | `bool` | Convert HTML entities into text. Typically defaults to `True`. |
| `body_width` | `int` | Wrap text at N characters. `0` or `None` disables wrapping. |
| `skip_internal_links` | `bool` | Omit `#anchor` links and same-page references. |
| `include_sup_sub` | `bool` | Render `<sup>` / `<sub>` in a more readable way. |
| `mark_code` | `bool` | Affect code block rendering. |

### Content Source Selection

The `content_source` parameter controls which HTML feeds the markdown converter.

| Value | Description | When to Use |
|-------|-------------|-------------|
| `"cleaned_html"` | HTML after scraping strategy processing. Default. | Most cases. |
| `"raw_html"` | Original HTML before any cleaning. | When cleaning removes content you need. |
| `"fit_html"` | HTML preprocessed for schema extraction. | Structured-data workflows. |

```python
DefaultMarkdownGenerator(content_source="raw_html")
```

### Link Citations

The generator converts `<a href="...">` into `[text][1]` citations with URLs at the bottom. Output available via `markdown_with_citations` and `references_markdown` on the result object.

---

## MarkdownGenerationResult

`result.markdown` returns a `MarkdownGenerationResult` with these fields:

| Field | Description |
|-------|-------------|
| `raw_markdown` | Direct HTML-to-markdown output, no filtering. |
| `markdown_with_citations` | Links converted to reference-style footnotes (`[text][1]`). |
| `references_markdown` | Gathered link references as a separate string. |
| `fit_markdown` | Filtered markdown when a content filter is active. Empty if no filter. |
| `fit_html` | HTML snippet used to produce `fit_markdown`. Useful for debugging. |

Access: `result.markdown.raw_markdown`, `result.markdown.fit_markdown`, etc.

---

## Content Filters

Content filters remove or rank text sections during the HTML-to-markdown step. Attach them to `DefaultMarkdownGenerator` via `content_filter`. Filtered output lands in `fit_markdown`.

### PruningContentFilter

Heuristic filter that scores nodes by text density, link density, tag importance, and structural context. Nodes below the threshold are discarded. Best for general noise removal without a query.

```python
from crawl4ai.content_filter_strategy import PruningContentFilter
from crawl4ai.markdown_generation_strategy import DefaultMarkdownGenerator
from crawl4ai import CrawlerRunConfig

prune_filter = PruningContentFilter(
    threshold=0.48,
    threshold_type="fixed",
    min_word_threshold=50
)
config = CrawlerRunConfig(
    markdown_generator=DefaultMarkdownGenerator(content_filter=prune_filter)
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `threshold` | `float` | ~0.48 | Score cutoff. Blocks below this are removed. |
| `threshold_type` | `str` | `"fixed"` | `"fixed"` for straight cutoff; `"dynamic"` adjusts by tag type and density. |
| `min_word_threshold` | `int` | -- | Discard blocks with fewer than N words. |

Scoring factors: text density (higher is better), link density (penalized), tag importance (`<article>`, `<p>` rank above `<div>`), structural context (sidebar-like nodes deprioritized).

### BM25ContentFilter

BM25 ranking algorithm keeps text blocks most relevant to a query. Best when you have a specific search term.

```python
from crawl4ai.content_filter_strategy import BM25ContentFilter
from crawl4ai.markdown_generation_strategy import DefaultMarkdownGenerator
from crawl4ai import CrawlerRunConfig

bm25_filter = BM25ContentFilter(
    user_query="machine learning",
    bm25_threshold=1.2,
    language="english"
)
config = CrawlerRunConfig(
    markdown_generator=DefaultMarkdownGenerator(
        content_filter=bm25_filter, options={"ignore_links": True}
    )
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `user_query` | `str` | `None` | Query to rank against. If blank, derives context from page metadata. |
| `bm25_threshold` | `float` | 1.0 | Higher = fewer, more relevant blocks; lower = more inclusive. |
| `use_stemming` | `bool` | `True` | Apply stemming to query and content tokens. |
| `language` | `str` | `"english"` | Language for stemming. |

### LLMContentFilter

Uses an LLM to intelligently filter content. Produces high-quality `fit_markdown` at the cost of API calls.

```python
from crawl4ai import CrawlerRunConfig, LLMConfig
from crawl4ai.markdown_generation_strategy import DefaultMarkdownGenerator
from crawl4ai.content_filter_strategy import LLMContentFilter

llm_filter = LLMContentFilter(
    llm_config=LLMConfig(provider="openai/gpt-4o", api_token="your-token"),
    instruction="Extract core content. Exclude nav, sidebars, footers.",
    chunk_token_threshold=4096,
    verbose=True
)
config = CrawlerRunConfig(
    markdown_generator=DefaultMarkdownGenerator(content_filter=llm_filter)
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `llm_config` | `LLMConfig` | -- | LLM provider configuration. |
| `instruction` | `str` | -- | Natural-language instructions for what to keep or remove. |
| `chunk_token_threshold` | `int` | infinity | Max tokens per chunk. Smaller values (2048-4096) enable parallel processing. |
| `verbose` | `bool` | `False` | Enable detailed logging. |

### Combining Filters

Chain filters in two passes without re-crawling. Use `result.html` from the first crawl, apply `PruningContentFilter.filter_content()` to get pruned chunks, then feed the joined result into `BM25ContentFilter.filter_content()`.

```python
from crawl4ai.content_filter_strategy import PruningContentFilter, BM25ContentFilter

# After crawling once:
pruned = PruningContentFilter(threshold=0.5, min_word_threshold=50)
chunks = pruned.filter_content(result.html)
bm25 = BM25ContentFilter(user_query="machine learning", bm25_threshold=1.2)
final = bm25.filter_content("\n".join(chunks))
```

### Custom Filters

Subclass `RelevantContentFilter` from `crawl4ai.content_filter_strategy` and implement `filter_content(html, min_word_threshold=None)`. Pass the instance to `DefaultMarkdownGenerator(content_filter=...)`.

---

## Content Selection via CrawlerRunConfig

Parameters for selecting and filtering HTML before markdown generation or extraction.

### css_selector

Limits all extraction to elements matching a CSS selector. Content outside the match is discarded.

```python
config = CrawlerRunConfig(css_selector="main.content")
```

### target_elements

A list of CSS selectors. Markdown and data extraction focus on these elements, but links and media are still extracted from the full page.

```python
config = CrawlerRunConfig(
    target_elements=["article.main-content", "aside.sidebar"]
)
```

Key difference from `css_selector`: full page context (all links, all media) remains in `result.links` and `result.media`.

### excluded_tags

Removes entire HTML tags before processing. Also use `excluded_selector` for CSS-based exclusions.

```python
config = CrawlerRunConfig(excluded_tags=["form", "header", "footer", "nav"])
```

### Other Selection Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `word_count_threshold` | `int` | Discard text blocks with fewer than N words. |
| `remove_overlay_elements` | `bool` | Strip overlay/popup elements before extraction. |
| `process_iframes` | `bool` | Merge iframe content into the final output. |

### Combined Example

```python
config = CrawlerRunConfig(
    css_selector="main.content",
    word_count_threshold=10,
    excluded_tags=["nav", "footer", "header"],
    exclude_external_links=True,
    exclude_external_images=True,
    markdown_generator=DefaultMarkdownGenerator(
        content_filter=PruningContentFilter(threshold=0.5)
    )
)
```

Filtering order: `excluded_tags` removed first, then `css_selector`/`target_elements` scopes content, then the content filter prunes/ranks, then `fit_markdown` is generated.

---

## Link and Media Analysis

### result.links

`result.links` is a dict with `"internal"` and `"external"` keys, each a list of link objects.

| Field | Description |
|-------|-------------|
| `href` | The hyperlink URL. |
| `text` | Visible link text. |
| `title` | The `title` attribute, if present. |
| `base_domain` | Domain extracted from `href`. |

```python
internal = result.links.get("internal", [])
external = result.links.get("external", [])
```

### Domain Filtering

| Parameter | Type | Description |
|-----------|------|-------------|
| `exclude_external_links` | `bool` | Discard links outside the root domain. |
| `exclude_social_media_links` | `bool` | Remove known social media links (facebook.com, twitter.com, x.com, linkedin.com, instagram.com, pinterest.com, tiktok.com, snapchat.com, reddit.com). |
| `exclude_social_media_domains` | `list[str]` | Override/extend the social media domain list. |
| `exclude_domains` | `list[str]` | Custom domains to block. |

### result.media

`result.media` is a dict with keys `"images"`, `"videos"`, `"audio"`. Each item has fields: `src` (URL), `alt` (alt text), `desc` (nearby text), `score` (heuristic relevance), `type`, `group_id`, `format`, `width`, `height`.

### Image Filtering

| Parameter | Description |
|-----------|-------------|
| `exclude_external_images` | Discard images not on the crawled domain. |
| `exclude_all_images` | Remove all images early in pipeline. Best for text-only crawls. |
| `wait_for_images` | Wait for images to fully load before extraction. |

---

## Table Extraction

Tables are extracted into `result.tables`. Configure via `table_extraction` on `CrawlerRunConfig`.

### DefaultTableExtraction

Default strategy. Scores tables by semantic structure, column consistency, text density, captions, and data attributes. Layout tables are penalized.

```python
from crawl4ai import DefaultTableExtraction, CrawlerRunConfig

strategy = DefaultTableExtraction(
    table_score_threshold=7, min_rows=2, min_cols=2, verbose=True
)
config = CrawlerRunConfig(table_extraction=strategy)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `table_score_threshold` | `int` | 7 | Minimum score to extract. Lower = more permissive. |
| `min_rows` | `int` | -- | Minimum rows required. |
| `min_cols` | `int` | -- | Minimum columns required. |
| `verbose` | `bool` | `False` | Detailed scoring logs. |

Backward-compatible shorthand: `CrawlerRunConfig(table_score_threshold=7)`.

Scoring: `<thead>` +2, `<tbody>` +1, `<th>` +2, correct header position +1, consistent columns +2, caption +2, summary +1, high text density +2/+3, data attributes +0.5 each, nested tables -3, `role="presentation"` -3, too few rows -2.

### NoTableExtraction

Disables table extraction. Import from `crawl4ai` and pass `NoTableExtraction()` to `table_extraction`.

### LLMTableExtraction

AI-powered extraction for complex tables with merged cells or irregular structures. Costs money per API call. Use only when `DefaultTableExtraction` fails. Supports automatic chunking for large tables.

```python
from crawl4ai import LLMTableExtraction, LLMConfig, CrawlerRunConfig

strategy = LLMTableExtraction(
    llm_config=LLMConfig(provider="groq/llama-3.3-70b-versatile", api_token="key"),
    max_tries=3, enable_chunking=True,
    chunk_token_threshold=3000, min_rows_per_chunk=10, max_parallel_chunks=5
)
config = CrawlerRunConfig(table_extraction=strategy)
```

Chunking params: `enable_chunking` (default `True`), `chunk_token_threshold` (default 3000), `min_rows_per_chunk` (default 10), `max_parallel_chunks` (default 5). For large tables (50+ rows), prefer Groq or Cerebras.

### Extracted Table Structure

Each entry in `result.tables` contains `headers` (list of strings), `rows` (list of lists), `caption`, `summary`, and `metadata` (with `row_count`, `column_count`, `has_headers`, `has_caption`, `has_summary`, `id`, `class`).

```python
import pandas as pd
for t in result.tables:
    df = pd.DataFrame(t["rows"], columns=t["headers"] or None)
```
