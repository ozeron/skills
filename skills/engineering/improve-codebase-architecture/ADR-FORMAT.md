# ADR Format

An ADR records an architectural decision the review should not re-litigate. The grilling loop offers one when the user rejects a candidate *with a load-bearing reason* — a reason a future explorer would need in order to avoid re-suggesting the same deepening. Skip ADRs for ephemeral reasons ("not worth it right now") and self-evident ones.

ADRs live in the project repo (e.g. `docs/adr/NNNN-kebab-title.md`), not in this skill. Number them sequentially, zero-padded: `0001`, `0002`, …

## Style — lean

Match the project's existing ADRs: title phrased *as the decision*, then a single tight paragraph carrying the decision, its rationale, and the evidence that settled it. No ceremony, no boilerplate sections unless a decision genuinely needs them.

```markdown
# {The decision, phrased as an imperative or statement}

{One paragraph: what was decided, the alternative it was chosen over, and the
load-bearing reason — ideally concrete evidence (a prototype finding, a
measured constraint, a domain rule) rather than a preference.}
```

### Specimen (from this project)

> # Use Effect RPC over Durable Object fetch for the Link Catalog boundary
>
> The Link Manager Worker talks to the Link Catalog Durable Object using Effect RPC over the Durable Object `fetch` surface rather than Alchemy native Durable Object RPC. The boundary carries rich Effect-domain values such as branded scalars, `Option`, `DateTime.Utc`, and schema-tagged failures; prototypes showed native DO RPC does not transparently preserve those values, while Effect RPC gives schema-owned request, response, and failure serialization without a parallel hand-written codec layer.

Note what makes it load-bearing: it names **the alternative rejected** (native DO RPC), **the constraint** (rich Effect values must survive the seam), and **the evidence** (prototypes showed they don't). That's exactly enough for a future review to not re-suggest native RPC.

## What to capture

- **Decision** — what shape was chosen.
- **Alternative** — the deepening or seam that was *not* taken (this is what stops re-suggestion).
- **Reason** — why, with evidence where possible.

## Optional sections

Add these only when the lean paragraph can't carry the weight:

- **Status** — `Accepted` / `Superseded by NNNN`. Add once an ADR can be overturned.
- **Consequences** — what this decision now constrains, if non-obvious.

## When the review contradicts an ADR

If a candidate contradicts an existing ADR, surface it only when the friction is real enough to warrant reopening the decision. Mark it in the card with an amber callout (`contradicts ADR-NNNN — but worth reopening because …`). Don't enumerate every theoretical refactor an ADR forbids.
