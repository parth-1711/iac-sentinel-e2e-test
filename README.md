# IaC Sentinel — End-to-End Test Repo

A throwaway sandbox for validating the full IaC Sentinel pipeline in a real
GitHub repo: PR trigger → `terraform plan` → OPA policy evaluation → Gemini
explanations/patches → PR comment → (optional) MongoDB audit log → dashboard.

This repo contains **only Terraform + a workflow file** — no copy of
`policies/`, `scanner/`, `agent/`, or `main.py`. The workflow references the
pipeline directly from the public [`parth-1711/IaC-Sentinel`](https://github.com/parth-1711/IaC-Sentinel)
repo via `uses: parth-1711/IaC-Sentinel/github-action@main`, so there's a
single source of truth: change a policy or the agent in `IaC-Sentinel`, and
every consumer repo (including this one) picks it up on its next run.

`@main` tracks the source repo's default branch, since it has no tagged
releases yet — fine for a test sandbox, but for anything longer-lived you'd
want to tag a release (`git tag v1 && git push origin v1` in `IaC-Sentinel`)
and pin to `@v1` instead, so this repo doesn't silently pick up breaking
changes.

## What's in here

- `provider.tf`, `network.tf`, `storage.tf`, `compute.tf` — hand-written
  Terraform resources that intentionally trip **all 7 policies** (see table
  below). They use dummy AWS credentials (`skip_credentials_validation`)
  so `terraform plan` runs for real without needing an actual AWS account.
- `.github/workflows/iac-sentinel.yml` — references the action from
  `IaC-Sentinel` and leaves `policies_dir` unset, since this repo has no
  local `policies/` folder. The action falls back to its own bundled
  policies from the `IaC-Sentinel` source repo whenever `policies_dir` is
  empty. Pass a `policies_dir` value here instead if you want this repo to
  define its own custom policies rather than use the shared defaults.

## Expected violations

The original commit intentionally tripped all 7 policies (12 violations) to
prove the pipeline end-to-end. A follow-up commit remediated one violation
per category — security, cost, and governance — to demonstrate a visible
before/after (compliance score, HIGH count, and the dashboard's trend line
should all move) without fixing everything at once, the way a real
remediation would land incrementally across PRs.

**Remediated:**

| Resource | Rule | Fix |
| :--- | :--- | :--- |
| `aws_security_group_rule.ssh_from_anywhere` | `open_security_groups` (HIGH) | CIDR restricted to `10.0.0.0/16` instead of `0.0.0.0/0` |
| `aws_instance.worker` | `oversized_instances` (MEDIUM) | Downsized from `m5.4xlarge` to `t3.large` |
| `aws_s3_bucket.app_logs` | `required_tags` (MEDIUM) | Added the missing `Owner` and `Project` tags |

**Still present (9 violations: 3 HIGH, 4 MEDIUM, 2 LOW):**

| Resource | Rule | Severity |
| :--- | :--- | :--- |
| `aws_security_group.mgmt_sg` (inline ingress) | `open_security_groups` | HIGH |
| `aws_security_group.mgmt_sg` (name "Public SG") | `naming_conventions` | LOW |
| `aws_s3_bucket.app_logs` (public-read ACL) | `public_s3_buckets` | HIGH |
| `aws_s3_bucket_public_access_block.app_logs_pab` | `public_s3_buckets` | HIGH |
| `aws_ebs_volume.app_data` | `unencrypted_volumes` | MEDIUM |
| `aws_instance.worker` (root + attached volumes) | `unencrypted_volumes` | MEDIUM x2 |
| `aws_instance.dev_sandbox` (no shutdown tag) | `missing_auto_shutdown_tags` | LOW |
| `aws_instance.dev_sandbox` (missing Owner/Project) | `required_tags` | MEDIUM |

With the default fail-closed setting, the check is still expected to fail
(red X) on this PR too — 3 violations remain HIGH. To see the fail-open
override path instead, add the `skip-iac-sentinel` or
`compliance-approved` label to the PR before (or after) it runs.

## Setup

### 1. Create the GitHub repo and push

```bash
git init
git add .
git commit -m "Initial IaC Sentinel end-to-end test"
git branch -M main
git remote add origin https://github.com/<your-username>/<new-repo-name>.git
git push -u origin main
```

### 2. Repo settings

- **Settings → Actions → General → Workflow permissions**: set to
  **"Read and write permissions"**. Without this, the PR-comment step will
  fail with a 403 — GitHub defaults new repos to read-only workflow tokens.

### 3. Repo secrets (Settings → Secrets and variables → Actions)

| Secret | Required? | Value |
| :--- | :--- | :--- |
| `GEMINI_API_KEY` | Optional | From [Google AI Studio](https://aistudio.google.com/app/apikey). Without it, the agent runs in its built-in deterministic fallback mode (still produces explanations/patches, just not LLM-generated). |
| `MONGO_URI` | Optional, but needed to test the dashboard end-to-end | A **cloud-reachable** MongoDB connection string — see note below. Leave unset to skip DB logging entirely; the PR comment still works. |

`GITHUB_TOKEN` is **not** something you add — GitHub Actions provides it
automatically for every run, already wired into the workflow.

> **Important:** `mongodb://localhost:27017` (what you used for local
> dashboard testing) is not reachable from GitHub's runners or from Vercel.
> To actually see a real CI-originated scan show up in the deployed
> dashboard, use a shared, internet-reachable database — e.g. a free
> [MongoDB Atlas](https://www.mongodb.com/cloud/atlas/register) M0 cluster —
> and point **both** this repo's `MONGO_URI` secret and the dashboard's
> Vercel `MONGO_URI` environment variable at that same connection string.

### 4. Open a test PR

Make any small change (e.g. edit a comment in `compute.tf`) on a branch and
open a PR. The workflow triggers on any `.tf` change. You can also trigger it
manually from the Actions tab (`workflow_dispatch`) without a PR.

### 5. What to check

- [ ] Actions tab shows the workflow ran, `terraform plan`/`show` succeeded
- [ ] A PR comment appears listing all 12 violations with AI explanations and suggested HCL patches
- [ ] The check fails (red X) — expected, since 4 violations are HIGH severity
- [ ] Adding the `skip-iac-sentinel` label and re-running flips it to fail-open (audit-only)
- [ ] If `MONGO_URI` is set: the scan is logged with `repo` = `<your-username>/<new-repo-name>` (verify via `mongosh` or Atlas's web UI)
- [ ] If the dashboard is deployed and pointed at the same MongoDB: sign in with the GitHub account that owns this repo and confirm the scan shows up, filtered correctly to only repos you can access
