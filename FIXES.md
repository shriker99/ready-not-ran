# Everyday fixes

Match the words in the report to the steps below. You can also leave the jobs alone and only use the report.

To open the Windows night-job list: click Start, type **Task Scheduler**, open it.

Find the job name from the report. Double-click that name.

## The computer was asleep

Open **Conditions**.

Turn on **Wake the computer to run this task**.

Then open **Settings** and turn on **Run task as soon as possible after a scheduled start is missed**.

## It only runs when the charger is in

**Conditions** tab. Turn off **Start the task only if the computer is on AC power** unless you really want that.

Turn off **Stop if the computer switches to battery power** if a long backup should keep going.

## It waits until nobody is using the PC

**Conditions** tab. Turn off **Start only if the computer is idle**.

If a backup dies when you touch the mouse, also turn off the option that stops the job when the PC is no longer idle.

## The Windows password changed

**General** tab. Choose **Run whether user is logged on or not**. Type the current password. Save.

Do that again after every password change.

## It only runs while someone is signed in

Same **General** tab. Night jobs usually need **Run whether user is logged on or not**.

## There is no trail when something fails

In the left list, click the top item **Task Scheduler Library**. On the right, click **Enable All Tasks History**.

## The file path looks wrong, or it used a drive letter like H:

Open **Actions**. Use a full path such as `C:\Backups\run.bat`.

Do not use `H:` or `Z:` for night work. Those letters often vanish when nobody is signed in.

## This tool will not flip those switches unless you ask it to

The report only looks. If you use the optional fixer, it asks first and keeps a spare copy. See APPLY.md.
