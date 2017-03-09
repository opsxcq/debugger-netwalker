# NW-Debug

NW-Debug is an oldschool debugger, wrote by Net Walker (lnwalker@hotmail.com), I'm just publishing the sources to keep this excellent code alive.

NW-Debug, is a windows debugger (W95 and W98), written in asm.

```
*****************************************
***           NWDEBUGGER 0.3          ***
***   Net Walker Simple Debug Model   ***
***        Version 0.3 (alpha)        ***
***         May, 14th - 1998          ***
*****************************************
```



## Net Walker

```
Hi all,

I friend of mine had asked me a dynamic patcher for a specific application.  I'm used to build Win32 GUI interfaces using assembly and then, I decided to build one for him.  Just after starting that work, I thought I could do a more generic tool.  After coding for half an hour I remember I have not seen much Win32 assembly source codes in the net...again I changed my plans and decided to turn my patcher to a simple debug application and release its sources. I hope they would be usefull to programmers trying to initiate on Win-GUI assembly programming, and to reverse-enginners trying to learn the basics of Win32 Debug API.  
Have fun!

Net Walker Simple (very simple) Debugger shows :
- How to use resource scripts in order to build Win32 Graphical User Interfaces in assembly language.  You can create all the controls (button, editboxes, and so on) individually - I was used to :(, but it is much easier to use a resource editor to build a Dialog Box, and use it as a Main Window.  There is some Win32 assembly examples on the Net, but as fair as I know, none of then goes beyond Menus, Icons, and Child  dialog boxes.
- How to use the main functions of Win32 Debug API.  Adding some code (and research/study) you can make your own debugger, memory patcher, unpacker, tracer, etc.  I have already done some of these, but I'll try to enhance some cosmetic features :) before releasing them.

- You can "Patch" (Read/Write) or "Dump" any process running on machine provided you know its Process ID.  Dumping/Patching a non-debugged process doesn't work on windows NT.
- You cand "Suspend" any process being debugged at any time.
- Breakpoints can be applied on Parent or Child Process.  You can apply only one breakpoint at each time and the debugger will not verify if the breakpoint is on a valid addres (i.e. at the beggining of an opcode).   After triggering the breakpoint it is removed (I'll fix this later).

The next improvements will be a "tracer", a PE Object Extractor (similar to NW Pextor and NW GetLoader), DLL Injector, API Hooker + bug fixes :)

Please, I need suggestions to a better user interface.  The "Actions" groupbox is becoming very small :).

On \Test directory you will found some simple win32 exe files I'm using to test this application 

Net Walker!

lnwalker@hotmail.com

May, 14th / Brazil
```

## History

* 30/04/98 
  Project Start.
  First functional version.  Support only to Create_Process event.
  Enhanced GUI.  Support for Load DLL event.
* 01/05/98
  Simple patching interface implemented.  Support for exceptions.
  First Public version - (0.1) finished.
* 02/05/98
  Added Support for patching multi-process.
  Added simple Breakpoint interface (only for the main thread).
* 04/05/98
  Release of first public version (0.1).
* 06/05/98
  Small GUI enhancements. Start commenting code for release.
* 07/05/98
  Added "Faults OFF" option.  Released version 0.2.
* 10/05/98
  Added "Suspend" button.  Allows to suspend debugged process.
* 11/05/98
  Read/WriteMemory function modified.  Now, the last parameter is the size for the data block being read/written.
  Created some functions in order to update "Actions" buttons according to debug events (see procedures AdjustFor…). "Patch" button activated for all debug time (not only after debug events).
* 13/05/98
  Added "Dump" function.  Allows dumping any memory's W95 process.
* 14/05/98
  Released public version 0.3.

## Disclaimer

I don't own this source code, **Net Walker** is the original author, I'm only publishing this code to share it with the world, and to let this nostalgic project inspire and be an example.