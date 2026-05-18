"""
health_check.py — Pre-flight system validation.

Usage:
    cd backend
    python -m tests.health_check
"""

import httpx
import sys

BASE = "http://localhost:8000"
SMOKE_QUERY = "Ders kaydı ile ilgili bilgi verir misiniz?"

def check(label: str, passed: bool, detail: str = "") -> None:
    icon = "✅" if passed else "❌"
    print(f"  {icon}  {label}" + (f"\n      → {detail}" if detail else ""))
    return passed

def main():
    print("\n Cep-Kampüs — Pre-Flight Health Check\n" + "─"*42)
    all_passed = True

    with httpx.Client(timeout=15) as client:
        # 1. Server liveness
        try:
            r = client.get(f"{BASE}/health")
            all_passed &= check(
                "Server reachable",
                r.status_code == 200,
                f"HTTP {r.status_code} — model: {r.json().get('model')}"
            )
        except Exception as e:
            check("Server reachable", False, str(e))
            print("\n  Server is unreachable. Start it with: uvicorn app.main:app --reload\n")
            sys.exit(1)

        # 2. Smoke query — verifies chain, embeddings, and ChromaDB together
        try:
            r = client.post(f"{BASE}/ask", json={"query": SMOKE_QUERY}, timeout=60)
            body = r.json()
            has_answer  = bool(body.get("answer"))
            has_sources = isinstance(body.get("sources"), list)
            all_passed &= check("RAG chain responds", has_answer, body.get("answer", "")[:80])
            all_passed &= check("Sources returned",   has_sources, f"{len(body.get('sources', []))} source(s)")
        except Exception as e:
            check("Smoke query", False, str(e))
            all_passed = False

        # 3. Hallucination guard
        try:
            r = client.post(
                f"{BASE}/ask",
                json={"query": "Üniversitenin kafeterya menüsü nedir?"},
                timeout=60,
            )
            answer   = r.json().get("answer", "")
            guarded  = "Bu bilgi yönetmelikte bulunmamaktadır" in answer
            all_passed &= check("Hallucination guard active", guarded, answer[:80])
        except Exception as e:
            check("Hallucination guard", False, str(e))
            all_passed = False

    print("\n" + "─"*42)
    if all_passed:
        print("  All checks passed. System is ready.\n")
    else:
        print("  One or more checks failed. Review output above.\n")
        sys.exit(1)

if __name__ == "__main__":
    main()