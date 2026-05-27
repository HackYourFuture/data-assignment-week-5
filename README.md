# Week 5 Assignment: Containerize and Ship

You have a Python pipeline. Your job is to make it reproducible, containerized, and shippable through CI.

## Project structure

```text
week5-container-assignment/
├── .github/
│   └── workflows/
│       └── ci.yml          ← Task 5: CI workflow (fill in the TODO steps)
├── src/
│   └── pipeline.py         ← Task 1 & 4: pipeline logic and env-var config
├── tests/
│   └── test_pipeline.py    ← tests that must pass before you touch the Dockerfile
├── Dockerfile              ← Task 3: write a cache-friendly Dockerfile
├── requirements.txt        ← Task 2: pin all dependencies
└── AI_ASSIST.md            ← Task 7: document your LLM usage
```

## Open in Codespaces

> 💻 [Open in GitHub Codespaces](https://github.com/codespaces/new/HackYourFuture/data-assignment-week-5)

Docker and the Azure CLI are pre-installed. Run `az login --use-device-code` before Task 6.

## Tasks at a glance

| Task | What you do |
|---|---|
| 1: Choose a Pipeline | The starter `src/pipeline.py` has three functions with `raise NotImplementedError`. Implement them so the tests pass. |
| 2: Pin Dependencies | Fill in `requirements.txt` with pinned versions (`package==version`). |
| 3: Dockerfile | Complete the `Dockerfile` following the TODO comments. |
| 4: Configuration | `get_config()` must read `API_KEY` from the environment and raise a clear error if it is missing. |
| 5: CI Workflow | Replace the `echo "TODO"` steps in `ci.yml` with real commands. |
| 6: Push to ACR | Add Azure login + ACR push steps to your workflow; screenshot the result. |
| 7: AI Report | Fill in `AI_ASSIST.md` with your LLM prompt, the suggestion, and what you changed. |

## How to run locally

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
API_KEY=test pytest -q
```

## How to run in Docker (after completing Task 3)

```bash
docker build -t my-pipeline:1.0 .
docker run --rm -e API_KEY=test my-pipeline:1.0
```

## Submitting

1. Create a branch: `git switch -c week5/your-name`
2. Commit your work.
3. Push and open a Pull Request against `main`.
4. Share the PR URL with your teacher.

See the [full assignment instructions](https://hackyourfuture.github.io/datatrack/week-5/assignment) for Task 6 (ACR push) and the grading rubric.
