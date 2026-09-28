# Common traps (plain English)

Match the row in the report to the fix. The checker does not flip these switches.

## History is off

Task Scheduler → click **Task Scheduler Library** → **Enable All Tasks History** on the right.

## Wake timers are off

Power Options → Change plan settings → Change advanced power settings → Sleep → Allow wake timers → Enable for plugged in (and battery if you mean it).

## Connected sleep

On many laptops the PC is never fully asleep and never fully awake. If night jobs must run, set the job to wake the PC **and** enable wake timers. If they still miss, run them at logon as a backup.

## Wall power / unplug

Conditions tab: uncheck **Start only if on AC power** and **Stop if the computer switches to battery** unless you really want that.

## Idle

Uncheck **Start only if the computer is idle**. Uncheck stop-if-no-longer-idle for backups.

## No catch-up

Settings tab: check **Run task as soon as possible after a scheduled start is missed**.

## Will not wake

Conditions tab: check **Wake the computer to run this task**.

## Saved login / only while logged on

General tab: pick **Run whether user is logged on or not**, enter the current password, save. After any Windows password change, do that again.

## Blank Start-in or quotes

Set **Start in** to the script folder. No quotation marks. Inside the script use full paths.

## Mapped drives

Replace `H:\folder\file` with `\\server\share\file`.

## PowerShell -Command

Use:

`powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:\Jobs\Backup.ps1`

## Time cap / no retry / second copy ignored

Settings tab: raise the time limit, set restart-on-failure, and pick Queue or run in parallel if two nights can overlap.

## Trigger end date / trigger off

Open Triggers. Turn the trigger on. Clear an old end date.

## Maintenance only

If the job is tied to Automatic Maintenance, it waits for Windows. Give it its own daily clock time instead.

## Stuck Running

End the task, then fix the script so it can exit. Check it is not waiting for a window.
