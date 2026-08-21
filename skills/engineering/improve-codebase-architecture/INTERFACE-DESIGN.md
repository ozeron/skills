# Interface Design

Reach for this during the grilling loop, once the user has picked a candidate and wants to explore *alternative interfaces* for the deepened module. The goal isn't one right answer — it's to make the depth trade-offs explicit by sketching a few and judging them against [LANGUAGE.md](LANGUAGE.md).

The interface is everything a caller must know: types, invariants, ordering, error modes, required config. Designing it is choosing how much a caller has to learn to get the behaviour. Deep = they learn a little, get a lot.

## Sketch 2–3 candidates

Don't design one interface and defend it. Sketch two or three, each making a different cut, and put them side by side. Useful axes to vary:

- **Where the seam sits** — push it up (caller orchestrates, module is thin) vs. push it down (module absorbs the orchestration). Deepening usually pushes it down.
- **What's named vs. inferred** — explicit config/arguments vs. invariants the module enforces internally.
- **One entry point vs. several** — a single deep operation vs. a handful of related smaller ones.
- **What's in the type vs. what's a documented invariant** — can an illegal state be made unrepresentable, or must it be a precondition the caller honours?

For each candidate write down the *full* interface — not just the signature. List the invariants it guarantees, the errors it can return, the ordering it requires. That list is the thing you're actually comparing.

## Judge each candidate

Run each sketch through the same three tests:

1. **Depth (leverage).** How much behaviour per unit of interface a caller learns? The candidate where callers learn least and get most wins on depth. If the interface is nearly as complex as the implementation, it's shallow — discard or merge it.
2. **The deletion test.** Imagine deleting the module. If complexity vanishes, this interface is a pass-through — the seam is in the wrong place. If complexity reappears across N callers, the interface is earning its keep.
3. **Adapter count.** Does anything actually vary across this seam? One adapter = hypothetical seam (don't build it). Two adapters (e.g. real in prod, in-memory in tests) = real seam — keep it.

## The test surface is the interface

Callers and tests cross the *same* seam. So for each candidate ask: what does a test have to set up to exercise this module, and can it assert on behaviour through the interface alone? If a test needs to reach *past* the interface to verify the real behaviour, the module is the wrong shape — the interesting behaviour is leaking. Prefer the candidate whose tests are the smallest and hit only the interface.

Watch for the trap the review is built to catch: pure functions extracted *only* for testability, where the real bugs live in how they're composed. A good interface puts the composition behind the seam so the test exercises the composed behaviour, not the fragments.

## Name it from the domain

Once a candidate wins, name the module and its operations from `CONTEXT.md` ([CONTEXT-FORMAT.md](CONTEXT-FORMAT.md)). If the winning shape introduces a concept the domain doesn't yet name, that's a signal to coin the term in `CONTEXT.md` inline — the interface and the vocabulary should land together.

## Record the rejection

If a candidate interface is rejected for a load-bearing reason (a constraint, a measured cost, a domain rule), offer to record it as an ADR ([ADR-FORMAT.md](ADR-FORMAT.md)) so the next review doesn't re-propose it.
