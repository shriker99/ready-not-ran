# What to tell the person who owns the PC

Hand them this page with the HTML report.

1. Yellow and red rows first. Ignore the green ones until those are clear.
2. If a row says **May skip**, the job looks healthy but a laptop setting can quietly skip it. Common ones: only on power, only when idle, will not wake from sleep.
3. If a row says **Failed**, Windows started something and the work did not finish. Open that job in Task Scheduler and look at the last result.
4. If a row says **Never ran**, it is on the list but has not fired. Check the clock time and whether the PC is off at that hour.
5. A last result of 0 only means the program said it exited cleanly. Confirm the file you expected actually showed up.
6. This tool does not flip the switches. Change the job in Task Scheduler, or ask IT to. The usual fixes are in FIXES.md.
