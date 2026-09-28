# When a night job fails — what we do

Two different problems get called “fail.” We treat them differently.

## 1. Windows never really started the work

Common reasons: the laptop was asleep, it was unplugged, someone used the mouse, last night was missed and nothing tried again.

**What we do:** the report marks it red or yellow and names the reason.

**What you can do in the program:** pick that job, turn on the everyday switches (wake the computer, allow it on battery, try again after a missed night), say yes. A spare copy is saved. You can put the old settings back.

That does not run last night’s backup right now. It gives tonight a real chance.

## 2. Windows started it, and the work still did not finish

Common reasons: the saved password is old, the file path is wrong, the job used a drive letter like H: that is not there at night, or the backup program itself stopped.

**What we do:** the report marks it red and says what Windows stored (“saved login is wrong,” “file not found,” and so on).

**What we will not do automatically:** type a new password, invent a new file path, or rewrite the backup program. Those belong to the person who set the job up.

**What you do next:** open the folder where the file should have landed. If it is not there, follow FIXES.md for that red line, or hand the report to whoever looks after the PC.

## Quick map

| The report says | First thing to do |
| --- | --- |
| Failed — asleep / battery / missed | Use the optional fixer, or follow FIXES.md for those boxes. Then look in the folder. |
| Failed — old password or only while signed in | A person must type the current Windows password on the job. We do not store passwords. |
| Failed — file or folder not found | A person must fix the path. We do not guess folders. |
| Failed — Windows finished cleanly but the file is missing | The backup program itself did no work. This tool cannot repair that program. |
| Missed / Never ran | Same as the sleep and battery steps. Check the clock time. |
| Looks OK | Still open the folder. |

## What success looks like

Not a green check. The file you expected is in its folder the next morning.
