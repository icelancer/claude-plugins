# LangSmith Evaluation Quickstart

> Source: https://docs.langchain.com/langsmith/evaluation-quickstart.md

## Installation

```bash
pip install -U langsmith openevals openai
```

## Environment Variables

```bash
export LANGSMITH_TRACING=true
export LANGSMITH_API_KEY="ls_..."
export OPENAI_API_KEY="sk-..."
```

## Three Required Components

1. **Dataset**: test inputs with optional expected outputs
2. **Target function**: the application being tested
3. **Evaluators**: scoring functions

## Dataset Creation

```python
from langsmith import Client

client = Client()
dataset = client.create_dataset(
    dataset_name="Sample dataset",
    description="A sample dataset in LangSmith."
)
```

## Target Function

```python
from openai import OpenAI
openai_client = OpenAI()

def target(inputs: dict) -> dict:
    response = openai_client.chat.completions.create(
        model="gpt-5-mini",
        messages=[
            {"role": "system", "content": "Answer the following question accurately"},
            {"role": "user", "content": inputs["question"]},
        ],
    )
    return {"answer": response.choices[0].message.content.strip()}
```

## Evaluator Definition

```python
from openevals.llm import create_llm_as_judge
from openevals.prompts import CORRECTNESS_PROMPT

def correctness_evaluator(inputs: dict, outputs: dict, reference_outputs: dict):
    evaluator = create_llm_as_judge(
        prompt=CORRECTNESS_PROMPT,
        model="openai:o3-mini",
        feedback_key="correctness",
    )
    return evaluator(
        inputs=inputs,
        outputs=outputs,
        reference_outputs=reference_outputs
    )
```

## Running Evaluation

```python
experiment_results = client.evaluate(
    target,
    data="Sample dataset",
    evaluators=[correctness_evaluator],
    experiment_prefix="first-eval-in-langsmith",
    max_concurrency=2,
)
```

## Key Imports

- `langsmith.Client` — main SDK client
- `langsmith.wrappers` — provider integration
- `openevals.llm.create_llm_as_judge` — evaluator factory
- `openevals.prompts.CORRECTNESS_PROMPT` — evaluation template

## pytest Integration

```python
# See: https://docs.langchain.com/langsmith/pytest.md
```
