# Verification records

## V1 — 2026-07-16 — commit d8cccea
- Ran: `bash -n` on all four hooks (clean); functional scenario suite on every hook
  in scratch projects (session-start 3 modes, first-edit deny-once/marker/exemption,
  stop-gate 7 scenarios incl. fingerprint parity with the skill's inline block,
  session-end record + skip); live Phase-0 pass (all 3 harness mechanics,
  transcript-verified); full E-run suite graded (27 headless sessions).
- Verified: hook mechanics end-to-end; E2 continuity claim (3/3 vs 0/3); E3 gate
  contract incl. recorded-skip (3/3); E4 costs.
- Assumed, not verified: drift-outcome delta through real compaction (R1, open);
  behavior on macOS/Linux clones (Windows-only testing so far).
