ISOLATED BUILD-ONLY AL HTTP PROBE

Purpose: compare synthetic SecretText JSON transmission to HTTP echo endpoint.
No dependency on Foundation or Proktek. No real passwords.

1. Open folder as a separate VS Code AL workspace.
2. Set tenant in .vscode/launch.json to your actual Sandbox tenant, if required.
3. Download symbols; AL: Package (BUILD ONLY).
4. STOP. Do not publish this extension without explicit review/approval.

Note: This probe does NOT prove Foundation EDS transport works; it isolates BC's
HttpContent.WriteFrom(SecretText) and HTTP Content-Type behavior.
The public echo endpoint will receive synthetic values only.
If later approved for deployment, Allow HttpClient Requests may need enabling.
