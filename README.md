# Ready ≠ Ran

Windows will put a green check next to a night job and say it is **Ready**.
That check often only means “I started the program.” It does not mean the backup, export, or report actually finished.

This is a small free checker. It reads your scheduled jobs and writes a report you can open in a browser.

It does **not** change any jobs. It only looks.

## Get the files

1. Open this page on a Windows PC.
2. Click the green **Code** button.
3. Click **Download ZIP**.
4. Unzip it somewhere easy, like your Desktop.

## Run the checker

1. Open the unzipped folder.
2. Right-click `ReadyNotRan.ps1`.
3. Choose **Run with PowerShell**.

If Windows blocks it, open PowerShell in that folder and paste:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\ReadyNotRan.ps1
```

The report lands in an `out` folder next to the script:

- `ReadyNotRan.html` — open this
- `ReadyNotRan.csv` — for Excel

Run it as Administrator if you want to see jobs created by other accounts, not just yours.

## What the report means

| Verdict | Plain meaning |
| --- | --- |
| Disabled | The job is turned off. |
| Never ran | It is on the list but has not run yet. |
| Failed | Windows started something. The work itself failed or was refused. |
| Missed | The clock time passed and the job did not catch up. |
| May skip | The job looks healthy, but a laptop setting can quietly skip it (sleep, battery, “only when idle”). |
| Looks OK | No obvious trap. Still confirm the file you expected actually showed up. |

A result of **0** only means the program said “I exited cleanly.” Your script can still have written nothing.

## What this is not

- Not a monitoring service.
- Not a fix button. See [FIXES.md](FIXES.md) for the usual traps.
- Not connected to the internet. The script stays on your PC.

## License

MIT. Free to use and share. See [LICENSE](LICENSE).
