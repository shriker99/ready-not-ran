# Security

`ReadyNotRan.ps1` is read-only.

It does:

- List scheduled tasks Windows already lets this account see
- Write an HTML file and a CSV file into a local `out` folder

It does not:

- Change, disable, or create tasks
- Send data anywhere
- Read your documents, mail, or passwords
- Install software

You can open the `.ps1` file in Notepad and read every line before you run it.

If Windows SmartScreen warns you, that is normal for a script downloaded from the internet. Unblock the file or run it from PowerShell as shown in the README.
