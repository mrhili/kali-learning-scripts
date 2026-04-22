# Kali base configure

Run:

```bash
chmod u+x configure.sh
./configure.sh
```

Optional flags:

- `--dry-run`
- `--skip-upgrade`
- `--skip-passwords`
- `--skip-gvm`

This script is now idempotent:

- skips apt packages already installed,
- skips tools already present in `PATH`,
- avoids duplicate alias lines.

---

For KIRCT web workflow profile, use:

- `../kirct-web-profile/kirct-web-profile.sh`
