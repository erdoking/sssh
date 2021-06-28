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
- [ ] host list number not correct when filter with groups

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

 Projekt: myproject1

[a]Debian_10 [b]Debian_9 [c]CentOS_8

 ID    <USER> @ Host:<port>               [Status]   Gruppe        Beschreibung
 1              repository                [DOWN]     Debian_10     Debian Repository
 2              mySQL                     [UP]       Debian_9      DB - mySQL
 3         pi @ ldap:1022                 [UP]       Debian_9      LDAP Server
 4              webserver                 [DOWN]     CentOS_8      Apache Server


     x  Abbruch
     z  Zurueck ins Basemenu
 ============================
Auswahl: 

```

