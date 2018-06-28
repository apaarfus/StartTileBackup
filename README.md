# StartTileBackup
This project is a fork of [this one](https://github.com/TurboLabIt/StartTileBackup). I made a different fork because I couldn't create a branch on the original project.

I merged the solution of two sources: here:  
https://www.tenforums.com/tutorials/67665-backup-restore-taskbar-toolbars-windows-10-a.html

and here:
https://winaero.com/blog/how-to-backup-and-restore-taskbar-pinned-apps-in-windows-10/

And added them to the original scripts from the forked project.

This way, when backing up / restoring the start menu, the taskbar is also copied over. In my short test it seems to remember the order of the taskbar items just fine as well.

The lines I've added to add this functionality are 
- Backup.bat: 45, 50
- Restore.bat: 49-50, 55

Aside from adding those lines, I have not edited the original scripts.



