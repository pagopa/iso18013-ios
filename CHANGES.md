# CHANGES

This document summarizes what changed between:

- Old documentation: [README_OLD.md](README_OLD.md)
- New documentation (to be used going forward): [README.md](README.md)

## Summary

`README.md` is a major documentation refresh. It moves from a **Proximity-centric API guide** to a broader **ISO18013 lifecycle/integration guide** with stronger architecture, event-flow, NFC, and integration details.

## High-level changes

### 1) Main API focus changed

- **README_OLD.md (old):** focuses on `Proximity.shared` APIs and `ProximityEvents`.
- **README.md (new):** focuses on `ISO18013.shared` APIs and `ISO18013Event`.

This is the most important conceptual change in the docs.

### 2) Architecture and flow documentation expanded

`README.md` adds clear sections for:

- Core architecture and components
- Event-driven lifecycle
- Engagement modes vs data transfer modes
- Request/response flow semantics
- Integration checklist and best practices

These were either missing or only briefly covered in the old README.

### 3) NFC coverage significantly expanded

`README.md` introduces detailed NFC topics not covered in depth previously:

- NFC Host Card Emulation session timing
- Cool-down behavior
- Late NFC initialization (`lateNfcInitialization()`)
- Custom NFC HCE message support (`setNfcHceMessage`) for iOS 17.4+

### 4) Event model and callback style updated

- Old doc uses a closure handler pattern with `Proximity.shared.proximityHandler`.
- New doc emphasizes delegate pattern with `ISO18013Delegate` and `onEvent(event:)`.

### 5) Startup API shape changed in docs

`README.md` describes startup via:

- `trustedCertificates`
- `engagementModes`
- `retrivalMethods`
- `delegate`
- `isNfcLateEngagement`

This is broader than the simple `start()` shown in `README_OLD.md` and reflects a more configurable setup model.

### 6) Practical integration guidance improved

`README.md` adds:

- Multi-scenario configuration examples (QR+BLE, QR+NFC, NFC late init)
- Error handling guidance by scenario
- Data structure explanation for requests/responses
- Concrete integration checklist for implementers

## Feature-level comparison

## Unchanged/continued capabilities (documented in both)

- Device response generation (`generateDeviceResponse`, JSON variant)
- Error response presentation
- OID4VP session transcript generation
- `stop()` cleanup behavior

## New or more explicit in README

- Full `ISO18013Event` set (including NFC lifecycle events)
- `ISO18013DataTransferArgs` request container
- BLE status check (`isBleEnabled()`)
- Late NFC initialization flow and constraints
- NFC timing constants and behavior
- Operational best practices

## De-emphasized/legacy presentation from README_OLD.md

- `ProximityEvents`-only framing
- Minimal lifecycle explanation around BLE-only proximity flow
- Limited guidance around deployment/integration strategy

## Terminology updates

- Documentation emphasis shifted from **"Proximity"** naming toward **"ISO18013"** lifecycle naming.
- New README frames the library as a complete holder-side orchestration layer rather than only a proximity transport entrypoint.

## Testing & operations notes

- `README_OLD.md` explicitly includes command-line test commands (`xcodebuild test`).
- `README.md` focuses more on integration patterns and architecture, with less operational command detail.

## Recommended forward usage

Per your instruction, **`README.md` is the source of truth going forward**.

Suggested policy:

1. Treat `README.md` as canonical for API usage and integration flow.
2. Keep `README_OLD.md` only for historical context until deprecated/removed.
3. Align future docs/examples with `ISO18013.shared` + delegate/event model terminology.

## Migration implications for readers

If developers were following `README_OLD.md`, they should:

- Move from `Proximity.shared` examples to `ISO18013.shared` examples.
- Implement `ISO18013Delegate` event handling.
- Adopt engagement/retrieval mode configuration at startup.
- Add NFC lifecycle handling if NFC modes are enabled.
- Keep using existing device response generation concepts, now in the broader ISO18013 flow.
