# Repository Instructions

## Azure Verified Modules

For Bicep in this repository, prefer Azure Verified Modules when a suitable AVM resource module or pattern module exists.

Use these rules:

- Prefer `br/public:avm/...` modules over authoring raw Azure resource types directly.
- Keep AVM versions pinned explicitly.
- Fall back to raw resources only when no suitable AVM exists or the AVM cannot express a required capability.
- When falling back to a raw resource, keep the implementation narrow and document the reason in the change summary.
- When touching an existing raw Bicep resource that already has a suitable AVM equivalent, consider migrating it to AVM as part of the change if the migration is low risk.
- Preserve existing repository naming conventions, parameter names, and output contracts unless the task requires changing them.

## Bicep Style

- Reuse existing AVM modules already present in the repository where possible.
- Keep module parameters explicit rather than relying on implicit defaults for important behavior.
- Prefer minimal, focused edits over broad refactors.
