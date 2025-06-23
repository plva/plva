## Workflow automation
This repository includes an automated workflow that updates the overview table every day at 03:21 UTC.

### Triggering manually
Use the **Actions** tab and choose *Run workflow*, or run:

```bash
gh workflow run update-overview.yml
```

### Local testing
With [act](https://github.com/nektos/act) you can run the job locally:

```bash
act -j update-overview
```
