# Common traps (plain English)

These are the usual reasons a night job looks fine and still does no work.

## The laptop was asleep

Windows will not wake the PC unless that box is checked.

In Task Scheduler: open the job → **Conditions** → check **Wake the computer to run this task**.

Also turn on **Run task as soon as possible after a scheduled start is missed** on the **Settings** tab.

## It only runs on power, not battery

On a laptop this is on by default. If the lid is closed on battery, the job is refused. The screen can still say Ready.

Uncheck **Start the task only if the computer is on AC power** unless you really want that.

## It only runs when nobody is using the PC

**Start only if the computer is idle** will skip the job the moment you touch the mouse.

Uncheck it for backups and exports.

## The password changed

If the job runs “whether the user is logged on or not,” Windows stored an old password. After you change your Windows password, the job quietly stops.

Open the job → **General** → enter the account again and save.

## “Ready” and a last result of 0

That means the program *started* and *exited without an error code*. It does not prove a file was written.

Check the output folder yourself. Give your script its own log file.

## History is off

Task History is off by default, so there is no trail.

In Task Scheduler, click **Task Scheduler Library** in the left tree, then **Enable All Tasks History** on the right.

## The script works by hand, fails at night

Night jobs often start in a different folder, with no mapped drives and no extra windows.

Set **Start in** to the folder that contains the script. Use full paths inside the script, not `H:` or `Z:`.

## This tool will not flip those switches for you

Version 1 only reports. You change the job in Task Scheduler, or we add a separate opt-in fixer later.
