# CONTEXT.md Format

`CONTEXT.md` is the project's domain glossary — the authoritative names for the concepts the codebase is *about*. The architecture review reads it before exploring, and the grilling loop edits it inline as terms get coined or sharpened. One `CONTEXT.md` per context (subsystem); create it lazily the first time a term needs recording.

`CONTEXT.md` names the **domain**. [LANGUAGE.md](LANGUAGE.md) names the **architecture**. Keep them separate: a deepened module gets its architectural shape from LANGUAGE.md and its *name* from CONTEXT.md.

## Structure

A `CONTEXT.md` has a title, a one-line ownership statement, then four sections in this order.

```markdown
# {Context name}

The {context name} context owns {what it is authoritative for} and {its management semantics}.

## Language

**Term**:
One-sentence definition. Bold the term; bold other defined terms when they appear inside a definition.
_Avoid_: {rejected synonym} when {the condition under which it's wrong}

## Relationships

- A **Term** has one **OtherTerm**.
- A **SubType** is a kind of **Term**.
- An **Operator** creates and **Retargets** **Links** in the **Catalog**.

## Example dialogue

> **Dev:** "{a question that hinges on getting a term right}"
> **Domain expert:** "{the answer, using the canonical terms}"

## Flagged ambiguities

- "{fuzzy word}" can mean {A} or {B}; resolved here: use **CanonicalTerm** when {condition}.
```

## Section rules

**Language.** Each entry is a bolded term, a definition, and an `_Avoid_:` line naming the synonym to reject *and the condition under which it's wrong* (not just the word). Cross-reference other defined terms in **bold** so the glossary reads as a connected vocabulary, not a flat list.

**Relationships.** Short declarative bullets stating how terms relate — cardinality (`has one`), subtyping (`is a kind of`), derivation (`contains entries derived from`), and who acts on what. These are the seams the domain already names; the review uses them to spot where the code disagrees with the domain.

**Example dialogue.** One short Dev / Domain-expert exchange that turns on choosing the right term. This is the test of whether a term is load-bearing — if no realistic question hinges on it, the term may not belong.

**Flagged ambiguities.** Each line records a word that *was* ambiguous, the readings it had, and the resolution (`resolved here: use **X** when …`). This is the audit trail — it stops a future reviewer from re-litigating a naming decision that's already settled.

## Editing discipline (during the grilling loop)

- Coining a name for a deepened module after a concept not yet in `CONTEXT.md`? Add it to `## Language` with an `_Avoid_:` line, right then.
- Sharpening a fuzzy term mid-conversation? Move it to `## Flagged ambiguities` with the resolution.
- Don't rename existing terms silently — if a term changes, record the old reading under `## Flagged ambiguities` so the change is auditable.
- Keep definitions to one sentence. If a term needs a paragraph, it's probably two terms.
