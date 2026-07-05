# Dotfiles Setup

This context defines the language for composing a Mac setup from reusable pieces while keeping the existing setup path understandable during the transition.

## Language

**Profile**:
A named setup target for a kind of Mac or person. A profile is selected explicitly and is composed from components.
_Avoid_: Machine identity, inheritance layer, wrapper

**Component**:
A reusable slice of setup intent that can be included by one or more profiles. Components describe capabilities the setup should include without being runnable profiles themselves.
_Avoid_: Capability, mixin, role

**Profile Composition**:
The pattern where a profile is assembled by selecting components instead of copying another profile's setup intent. Profile composition should reduce duplication across profiles and keep shared setup intent in one place.
_Avoid_: Inheritance, wrapping, copy-paste profile

**Legacy Setup**:
The existing setup experience that uses the current root inventories as its source of truth. It remains distinct from profile-based setup while profiles are being introduced.
_Avoid_: Old setup, fallback setup, default profile

**Setup Plan Files**:
The concrete files prepared from a selected profile that show what the setup will install, link, check, or skip. They are inspection and execution inputs, not a second source of truth.
_Avoid_: Rendered artifacts, generated truth, materialized files

**Prepare Profile**:
The act of turning a selected profile into setup plan files. Preparing a profile does not itself mean running the machine setup.
_Avoid_: Materialize, generate profile, compile profile

**Worker Script**:
A focused setup script that performs one part of the setup using already-prepared inputs. Worker scripts do not decide which profile or components apply.
_Avoid_: Adapter, resolver, orchestrator

**Setup Flags**:
Simple prepared values that describe profile decisions needed during setup. Setup flags are derived from the selected profile rather than from private machine identity.
_Avoid_: Facts, environment truth, machine detection

**Sensitive Identity**:
Private user or machine details that must not define a profile or appear in tracked setup intent. Examples include account identifiers, private emails, hard-coded home paths, tokens, serials, and cloud-backup account paths.
_Avoid_: Local defaults, machine facts, personal config
