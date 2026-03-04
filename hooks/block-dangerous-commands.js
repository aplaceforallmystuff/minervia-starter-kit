#!/usr/bin/env node
/**
 * Block Dangerous Commands - Minervia Safety Hook
 * Blocks catastrophic and high-risk shell patterns before execution.
 *
 * Safety level: high (critical + high tiers)
 * Installed by Minervia to ~/.claude/hooks/
 */

const PATTERNS = [
  // CRITICAL — catastrophic, unrecoverable
  { level: 'critical', regex: /\brm\s+(-.+\s+)*["']?~\/?["']?(\s|$|[;&|])/, reason: 'rm targeting home directory' },
  { level: 'critical', regex: /\brm\s+(-.+\s+)*["']?\$HOME["']?(\s|$|[;&|])/, reason: 'rm targeting $HOME' },
  { level: 'critical', regex: /\brm\s+(-.+\s+)*\/(\*|\s|$|[;&|])/, reason: 'rm targeting root filesystem' },
  { level: 'critical', regex: /\brm\s+(-.+\s+)*\/(etc|usr|var|bin|sbin|lib|boot|dev|proc|sys)(\/|\s|$)/, reason: 'rm targeting system directory' },
  { level: 'critical', regex: /\brm\s+(-.+\s+)*(\.\/?|\*|\.\/\*)(\s|$|[;&|])/, reason: 'rm deleting current directory contents' },
  { level: 'critical', regex: /\brm\s+(-.+\s+)*["']?(~\/)?\.claude["']?(\s|$|[;&|])/, reason: 'rm targeting ~/.claude directory' },
  { level: 'critical', regex: /\bdd\b.+of=\/dev\/(sd[a-z]|nvme|hd[a-z]|vd[a-z])/, reason: 'dd writing to disk device' },
  { level: 'critical', regex: /\bmkfs(\.\w+)?\s+\/dev\/(sd[a-z]|nvme|hd[a-z]|vd[a-z])/, reason: 'mkfs formatting disk' },
  { level: 'critical', regex: /:\(\)\s*\{.*:\s*\|\s*:.*&/, reason: 'fork bomb detected' },

  // HIGH — significant risk, data loss, security
  { level: 'high', regex: /\b(curl|wget)\b.+\|\s*(ba)?sh\b/, reason: 'piping URL to shell (remote code execution risk)' },
  { level: 'high', regex: /\bgit\s+push\b(?!.+--force-with-lease).+(--force|-f)\b.+\b(main|master)\b/, reason: 'force push to main/master — use --force-with-lease instead' },
  { level: 'high', regex: /\bgit\s+reset\s+--hard/, reason: 'git reset --hard loses uncommitted work' },
  { level: 'high', regex: /\bgit\s+clean\s+(-\w*f|-f)/, reason: 'git clean -f deletes untracked files permanently' },
  { level: 'high', regex: /\bchmod\b.+\b777\b/, reason: 'chmod 777 is a security risk — use specific permissions instead' },
  { level: 'high', regex: /\b(cat|less|head|tail|more)\s+\.env\b/, reason: 'reading .env file may expose secrets in tool output' },
  { level: 'high', regex: /\becho\b.+\$\w*(SECRET|KEY|TOKEN|PASSWORD|API_|PRIVATE)/i, reason: 'echoing secret variable exposes it in output' },
  { level: 'high', regex: /\bdocker\s+volume\s+(rm|prune)/, reason: 'docker volume deletion loses data permanently' },

  // HIGH — inline credentials (saved to ~/.claude/settings.json permissions array)
  { level: 'high', regex: /\b[A-Z_]*(?:API_KEY|SECRET|TOKEN|PASSWORD)=["']?[a-zA-Z0-9_\-!@#$.]{12,}["']?\s/i, reason: 'inline credential will be permanently saved to settings.json — export it as an env var first' },
  { level: 'high', regex: /Authorization:\s*Bearer\s+[a-zA-Z0-9_\-\.]{20,}/, reason: 'inline bearer token — use $TOKEN variable instead' },
  { level: 'high', regex: /\bsk-[a-zA-Z0-9]{20,}/, reason: 'API secret key in command — use env var instead' },
];

async function main() {
  let input = '';
  for await (const chunk of process.stdin) input += chunk;

  const event = JSON.parse(input);
  const toolName = event.tool_name;

  if (toolName !== 'Bash') {
    console.log(JSON.stringify({ decision: 'allow' }));
    return;
  }

  const command = event.tool_input?.command || '';

  for (const pattern of PATTERNS) {
    if (pattern.regex.test(command)) {
      console.log(JSON.stringify({
        decision: 'deny',
        message: `🛡️ Blocked: ${pattern.reason}\n\nCommand: ${command.substring(0, 120)}${command.length > 120 ? '...' : ''}`
      }));
      return;
    }
  }

  console.log(JSON.stringify({ decision: 'allow' }));
}

main().catch(() => console.log(JSON.stringify({ decision: 'allow' })));
