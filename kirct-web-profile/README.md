# KIRCT web profile

Purpose:

- keep kali-learning-scripts simple style,
- prepare Kali for repeatable KIRCT web-red-team workflow,
- keep operator-to-brain communication available while KIRCT is running.

Run:

```bash
chmod u+x kirct-web-profile.sh
./kirct-web-profile.sh --profile=core
```

Options:

- `--profile=core` (default)
- `--profile=extended`
- `--with-heavy`
- `--skip-upgrade`
- `--dry-run`

Creates:

- `~/Desktop/targets/kirct/results/recon`
- `~/Desktop/targets/kirct/results/validation`
- `~/Desktop/targets/kirct/results/exploitation`
- `~/Desktop/targets/kirct/results/reporting`
- `~/Desktop/targets/kirct/wordlists`
- `~/Desktop/targets/kirct/loot`
- `~/Desktop/targets/kirct/brain`
- `~/Desktop/targets/kirct/ops`

Operator wrappers:

```bash
~/Desktop/targets/kirct/ops/brain-note.sh "<note text>"
~/Desktop/targets/kirct/ops/brain-ask.sh "<question text>"
```
