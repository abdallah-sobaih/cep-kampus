"""
evaluate.py — End-to-end RAG evaluation harness.

Usage:
    cd backend
    python -m tests.evaluate --config A

Produces a JSON report in backend/tests/reports/
"""

import argparse
import json
import time
import httpx
from pathlib import Path
from datetime import datetime

# ---------------------------------------------------------------------------
# Configuration grid — mirrors the tuning table above.
# Edit config.py and re-run ingest.py before switching configurations.
# ---------------------------------------------------------------------------
CONFIGS = {
    "A": {"chunk_size": 500, "chunk_overlap": 50,  "top_k": 4},
    "B": {"chunk_size": 350, "chunk_overlap": 40,  "top_k": 5},
    "C": {"chunk_size": 650, "chunk_overlap": 75,  "top_k": 4},
    "D": {"chunk_size": 500, "chunk_overlap": 50,  "top_k": 6},
}

GOLDEN_SET_PATH = Path(__file__).parent / "golden_set.json"
REPORTS_DIR     = Path(__file__).parent / "reports"
API_BASE_URL    = "http://localhost:8000"


def load_golden_set() -> list[dict]:
    with open(GOLDEN_SET_PATH, encoding="utf-8") as f:
        return json.load(f)


def ask(client: httpx.Client, query: str) -> dict:
    response = client.post(
        f"{API_BASE_URL}/ask",
        json={"query": query},
        timeout=90.0,
    )
    response.raise_for_status()
    return response.json()


def evaluate_case(result: dict, case: dict) -> dict:
    """Score a single test case against its expected outcomes."""
    answer  = result.get("answer", "")
    sources = result.get("sources", [])

    # Check 1: Does the answer contain the required phrase?
    phrase_match = case["must_contain_phrase"].lower() in answer.lower()

    # Check 2: For hallucination-sensitive cases, ensure the fallback
    # phrase is present AND no spurious source documents were returned.
    if case["must_not_hallucinate"]:
        hallucination_free = (
            "Bu bilgi yönetmelikte bulunmamaktadır" in answer
            and len(sources) == 0
        )
    else:
        hallucination_free = True  # Not applicable for answerable questions.

    # Check 3: For cases with a known source, verify citation accuracy.
    if case["expected_source"]:
        returned_sources = [s["source"] for s in sources]
        source_correct = case["expected_source"] in returned_sources
    else:
        source_correct = True  # Not applicable for unanswerable questions.

    passed = phrase_match and hallucination_free and source_correct

    return {
        "id":                case["id"],
        "tier":              case["tier"],
        "query":             case["query"],
        "passed":            passed,
        "phrase_match":      phrase_match,
        "hallucination_free": hallucination_free,
        "source_correct":    source_correct,
        "answer_preview":    answer[:200],
    }


def run_evaluation(config_name: str) -> None:
    config   = CONFIGS[config_name]
    cases    = load_golden_set()
    results  = []
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    print(f"\n{'='*60}")
    print(f"  Cep-Kampüs RAG Evaluation — Config {config_name}")
    print(f"  Parameters: {config}")
    print(f"  Test cases: {len(cases)}")
    print(f"{'='*60}\n")

    with httpx.Client() as client:
        for case in cases:
            print(f"  Running [{case['id']}] {case['query'][:55]}...")
            t0 = time.perf_counter()
            try:
                api_result  = ask(client, case["query"])
                scored      = evaluate_case(api_result, case)
                scored["latency_s"] = round(time.perf_counter() - t0, 2)
            except Exception as e:
                scored = {
                    "id": case["id"], "tier": case["tier"],
                    "passed": False, "error": str(e),
                    "latency_s": round(time.perf_counter() - t0, 2),
                }
            results.append(scored)
            status = "✅ PASS" if scored.get("passed") else "❌ FAIL"
            print(f"    {status}  ({scored['latency_s']}s)\n")

    # Aggregate metrics
    total     = len(results)
    passed    = sum(1 for r in results if r.get("passed"))
    by_tier   = {}
    for r in results:
        tier = r.get("tier", "?")
        by_tier.setdefault(tier, {"passed": 0, "total": 0})
        by_tier[tier]["total"] += 1
        if r.get("passed"):
            by_tier[tier]["passed"] += 1

    avg_latency = round(
        sum(r.get("latency_s", 0) for r in results) / total, 2
    )

    report = {
        "config":       config_name,
        "parameters":   config,
        "timestamp":    datetime.utcnow().isoformat(),
        "summary": {
            "total":        total,
            "passed":       passed,
            "accuracy_pct": round(passed / total * 100, 1),
            "avg_latency_s": avg_latency,
            "by_tier":      by_tier,
        },
        "results": results,
    }

    report_path = REPORTS_DIR / f"eval_config_{config_name}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.json"
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    print(f"\n{'='*60}")
    print(f"  RESULT: {passed}/{total} passed ({report['summary']['accuracy_pct']}%)")
    print(f"  Avg latency: {avg_latency}s")
    print(f"  By tier: {by_tier}")
    print(f"  Report saved to: {report_path}")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--config", choices=list(CONFIGS.keys()), default="A",
        help="Which parameter configuration to evaluate."
    )
    run_evaluation(parser.parse_args().config)