# 24 problems this checker looks for

Each one is a real Windows trap. Most owners never hear the name. The report lists every check, then marks the ones this PC actually has.

## The PC itself

1. **History is off.** Task History is off by default. When a job fails, there is no trail.
2. **Wake timers are off.** The job may say “wake the PC,” but Windows power settings can still refuse the wake.
3. **Connected sleep.** Many laptops use Modern Standby. The alarm clock often never rings.
4. **The scheduler service is sick.** If that service is stopped, every job is theater.
5. **This is a laptop.** Laptop defaults are “protect the battery,” not “do the night work.”

## Each night job

6. **Ready does not mean finished.** A last result of 0 only means the program exited. PowerShell started with `-Command` is a common liar.
7. **Never ran.** On the list. Has not fired.
8. **Turned off.** Disabled. The green library still shows it.
9. **Missed nights.** The clock time passed. Nothing caught up.
10. **Will not wake a sleeping PC.** Wake-to-run is off. Default on most jobs.
11. **Wall power only.** Default is on. Battery start is refused. Looks like Ready.
12. **Dies if you unplug.** A long backup dies mid-run on battery.
13. **Waits for idle.** Touch the mouse, skip the job.
14. **Stops when you come back.** Idle ended, job killed.
15. **Will not catch up.** Missed slot is gone forever.
16. **Saved login is stale.** Password changed, or the job uses a limited login that cannot see the network.
17. **Only while someone is logged in.** Overnight jobs die at sign-out.
18. **Bad path or blank Start-in.** Runs from System32. Quotes in Start-in break the folder.
19. **Mapped drive letter.** `H:` and `Z:` often do not exist at night.
20. **Hidden.** Easy to forget it exists.
21. **Needs a specific network.** VPN or office Wi-Fi gone, job skipped.
22. **Time cap too short.** Windows kills it before the work finishes.
23. **No retry after a fail.** One miss, then silence.
24. **A second copy is ignored.** Still-running job blocks the next night.
25. **Trigger is off or the end date passed.** Task looks enabled. The clock is dead.
26. **Only in Windows maintenance.** It waits for an automatic-maintenance window you never see.
27. **Stuck on Running.** Last start never came back.
28. **Windows refused the run.** Codes that mean a condition box blocked it, not “the script ran.”

The extra numbers past 24 are the same family. The program runs all of them.
