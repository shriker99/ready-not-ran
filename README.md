# Ready ≠ Ran

Windows will put a green check next to a night job and say it is **Ready**.
That check often only means “I started the program.” It does not mean the backup, export, or report actually finished.

This checker looks for **28 real traps** most owners never hear about. It writes a report you can open in a browser.

It does **not** change any jobs. It only looks.

It has no built-in owner name, no home address, and no specific PC model. It reads the Windows PC you install it on.

The list of traps is in [PROBLEMS.md](PROBLEMS.md).

## Install (any Windows 10 or 11 PC)

1. Download the ZIP from this page: green **Code** → **Download ZIP**.
2. Unzip it.
3. Double-click **Install.cmd**.
4. If Windows warns you, choose **More info** → **Run anyway**, or right-click **Install.ps1** → **Run with PowerShell**.

That copies the checker into this user’s AppData folder and puts **Ready Not Ran** on the Start Menu and Desktop.

No administrator account is required. Nothing is sent off the PC.

## Run it

Double-click **Ready Not Ran**.

Or, from the unzipped folder without installing:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\ReadyNotRan.ps1
```

The report lands in an `out` folder next to the script:

- `ReadyNotRan.html` — open this
- `ReadyNotRan.csv` — for Excel

Run it as Administrator only if you want to see jobs created by other accounts, not just yours.

## Remove it

Right-click `Uninstall.ps1` in the install folder → **Run with PowerShell**, or run `Uninstall.ps1` from the original ZIP.

## What the report means

| Verdict | Plain meaning |
| --- | --- |
| Disabled | The job is turned off. |
| Never ran | It is on the list but has not run yet. |
| Failed | Windows started something. The work itself failed or was refused. |
| Missed | The clock time passed and the job did not catch up. |
| May skip | The job looks healthy, but a setting can quietly skip it. |
| Looks OK | No obvious trap. Still confirm the file you expected actually showed up. |

A result of **0** only means the program said “I exited cleanly.” Your script can still have written nothing.

## What this is not

- Not a monitoring service.
- Not a fix button. See [FIXES.md](FIXES.md).
- Not connected to the internet. The script stays on the PC that runs it.
- Not tied to one brand of computer.

## License

MIT. Free to use and share. See [LICENSE](LICENSE).
