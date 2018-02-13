# sssh
SuperSSH

## About
The sssh-script organize your Linux-hosts (ssh!).

## Features
 * organize projects
 * group hosts
 * "ping" hosts (netcat on port 22)
 * colored
 * ssh-user per host
 * parameter supported "sssh 1 1" or "sssh test meinserver"

## Howto
 * copy sssh.sh and projects.txt to a order of your wish
 * edit projects.txt as your wish
 * set alias (see below)

## ToDo
- [ ] code cleanup
- [ ] translate to english

## Known Bugs
- [ ] parameters not working property

## Edit .bashrc
```bash
alias sssh='bash sssh.sh'
```

## Preview
#### main menu
```bash
 == Super SSH Sprungmenu ==

     1	TEST
     2	vagrant

     x  Abbruch

 ====================
Auswahl: 
```

#### project menu
```bash
 == SSH Sprungmenu ==

 Projekt: TEST



ID USER	 Host		[Status]	Gruppe		Beschreibung  
1 root @ 1.1.1.1	[OFFLINE]			SLES12 x64
2 root @ 127.0.0.1	[ONLINE]			SLES12 x64


     x  Abbruch
     z  Zurueck ins Basemenu
 ============================
Auswahl: 
```

