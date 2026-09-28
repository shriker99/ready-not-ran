# Ready ≠ Ran

Windows will put a green check next to a night job and say it is **Ready**.
That often only means “I started.” It does not mean the backup, export, or report actually finished.

This tool looks for the usual quiet reasons that happens. Then it writes a page you can open in any browser.

You do not need to be technical. Read [START-HERE.md](START-HERE.md) first.

It does **not** change anything until you later choose to. It does not send anything off the PC. It does not store your name or what kind of computer you own.

## Install on any Windows 10 or 11 PC

1. Download the ZIP (green **Code** button → **Download ZIP**).
2. Unzip it.
3. Double-click **Install.cmd**.
4. If Windows warns you, click **More info** → **Run anyway**.

That puts **Ready Not Ran** on the Desktop and the Start menu for this Windows user only. No administrator password.

## Run it

Double-click **Ready Not Ran**.

A report appears in a folder called `out`:

- **ReadyNotRan.html** — open this
- **ReadyNotRan.csv** — only if you use Excel

## What the report means

| The report says | In plain English |
| --- | --- |
| Disabled | Someone turned this job off. |
| Never ran | It is on the list but has not run yet. |
| Failed | Windows started something. The work did not finish. |
| Missed | The clock time came and went. Nothing caught up. |
| May skip | It looks healthy. A setting can still skip it. |
| Looks OK | No obvious trap. Still check that the file you wanted actually showed up. |

## Take it off the PC

Right-click **Uninstall.ps1** → **Run with PowerShell**.

## License

Free to use and share. See [LICENSE](LICENSE).
