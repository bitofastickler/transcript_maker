# Security

Do not attach student records, downloaded transcript files, API keys, or credentials
to public issues. Use a minimal fictional example.

Before publishing, enable GitHub private vulnerability reporting. Then use the repository's
Security tab > Report a vulnerability for sensitive reports. Until enabled, do not disclose
sensitive exploit details in public; ask the maintainer for a private reporting channel.

The app treats imported files as untrusted, checks format/version/size and record ownership,
and validates grades and numbers before replacing in-memory records. No application-level
file encryption or multi-user isolation is provided. Use a trusted device and protected folders.

Only the current release candidate is under active review. No security support SLA is promised.
A pattern-based history scan is evidence, not proof of absence of secrets. Recheck history,
GitHub assets, branches, workflow logs, and any attachments before a public release.
