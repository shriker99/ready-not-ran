# Apply and Undo

Scan is the default. Nothing is written until you press **Apply selected** and confirm.

## What Apply may change

Only these settings on a job you selected:

- Start on battery
- Do not stop if unplugged
- Wake the PC
- Catch up after a missed start
- Do not wait for idle
- Do not stop when idle ends
- Do not require a specific network
- Un-hide the job
- Restart up to 3 times after a fail
- Queue a second copy instead of ignoring it

## What Apply will not change

- The program or script the job runs
- The account the job runs as
- The password
- Jobs under `\Microsoft\` unless you turned on **Include Microsoft jobs** and selected that row

## Backup

Before a write, the current job is saved as XML in:

`%LOCALAPPDATA%\ReadyNotRan\backups\<date-time>\`

**Undo last apply** puts those XML files back.
