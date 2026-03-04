#!/usr/bin/env node
/**
 * Protect Secrets - Minervia Safety Hook
 * Prevents reading, modifying, or exfiltrating sensitive files.
 *
 * Safety level: high
 * Installed by Minervia to ~/.claude/hooks/
 */

const ALLOWLIST = [
  /\.env\.example$/i, /\.env\.sample$/i, /\.env\.template$/i,
  /\.env\.schema$/i, /\.env\.defaults$/i, /example\.env$/i,
];

const SENSITIVE_FILES = [
  // Critical
  { regex: /(?:^|\/)\.env(?:\.[^/]*)?$/, reason: '.env file contains secrets' },
  { regex: /(?:^|\/)\.envrc$/, reason: '.envrc (direnv) contains secrets' },
  { regex: /(?:^|\/)\.ssh\/id_[^/]+$/, reason: 'SSH private key' },
  { regex: /(?:^|\/)(id_rsa|id_ed25519|id_ecdsa|id_dsa)$/, reason: 'SSH private key' },
  { regex: /(?:^|\/)\.aws\/credentials$/, reason: 'AWS credentials file' },
  { regex: /(?:^|\/)\.kube\/config$/, reason: 'Kubernetes config contains credentials' },
  { regex: /\.pem$/i, reason: 'PEM key file' },
  { regex: /\.key$/i, reason: 'Key file' },
  // High
  { regex: /(?:^|\/)credentials\.json$/i, reason: 'Credentials file' },
  { regex: /(?:^|\/)(secrets?|credentials?)\.(json|ya?ml|toml)$/i, reason: 'Secrets configuration file' },
  { regex: /service[_-]?account.*\.json$/i, reason: 'GCP service account key' },
  { regex: /(?:^|\/)\.docker\/config\.json$/, reason: 'Docker config may contain registry auth' },
  { regex: /(?:^|\/)\.netrc$/, reason: '.netrc contains credentials' },
  { regex: /(?:^|\/)\.npmrc$/, reason: '.npmrc may contain auth tokens' },
  { regex: /(?:^|\/)\.pypirc$/, reason: '.pypirc contains PyPI credentials' },
];

const DANGEROUS_COMMANDS = [
  { regex: /\b(cat|less|head|tail|more)\s+\.env\b/, reason: 'reading .env exposes secrets' },
  { regex: /\bsource\s+\.env/, reason: 'sourcing .env in this context exposes secrets' },
  { regex: /\b(printenv|^env)\s*([;&|]|$)/, reason: 'env dump may expose secrets' },
  { regex: /\b(curl|wget)\b.+-d\s*@\.env/, reason: 'exfiltrating .env file contents' },
  { regex: /\bscp\b.+(\.pem|\.key|id_rsa|id_ed25519|\.env)/, reason: 'copying secret files over network' },
];

async function main() {
  let input = '';
  for await (const chunk of process.stdin) input += chunk;

  const event = JSON.parse(input);
  const toolName = event.tool_name;

  // File-based tools: check file path
  if (['Read', 'Edit', 'Write'].includes(toolName)) {
    const filePath = event.tool_input?.file_path || '';

    // Check allowlist first
    if (ALLOWLIST.some(p => p.test(filePath))) {
      console.log(JSON.stringify({ decision: 'allow' }));
      return;
    }

    for (const pattern of SENSITIVE_FILES) {
      if (pattern.regex.test(filePath)) {
        console.log(JSON.stringify({
          decision: 'deny',
          message: `🔒 Blocked: ${pattern.reason}\n\nFile: ${filePath}`
        }));
        return;
      }
    }
  }

  // Bash: check command patterns
  if (toolName === 'Bash') {
    const command = event.tool_input?.command || '';

    for (const pattern of DANGEROUS_COMMANDS) {
      if (pattern.regex.test(command)) {
        console.log(JSON.stringify({
          decision: 'deny',
          message: `🔒 Blocked: ${pattern.reason}\n\nCommand: ${command.substring(0, 120)}${command.length > 120 ? '...' : ''}`
        }));
        return;
      }
    }
  }

  console.log(JSON.stringify({ decision: 'allow' }));
}

main().catch(() => console.log(JSON.stringify({ decision: 'allow' })));
