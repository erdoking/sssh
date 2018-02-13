#!/bin/bash

# ##########################################################
# 
#       Super SSH Script 
#
#       Version  8 [06.2016]
#
#       V8.     Added group function again [08.2017]
#       V7.     Rewrite script - now with functions [06.2016]
#       V6.     Added function to pass parameters to server menu [05.2012]
#       V5.     Added function to choose by hostname [05.2012]
#       V4.     Added group function [11.2011]
#       V3.     Added avaibility function
#       V2.     color output
#       V1.     Create script



#### config  ####
## Wenn true wird jeder Host 1x angepingt und der Status ausgegeben
PINGHOST="true" # gueltige Werte [true,false]



#### do not change ####
## used to kill from subshell
MAINPID=$$


#===  FUNCTION  ================================================================
#          NAME:  get_projects
#   DESCRIPTION:  find all projects
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function get_projects() {
        for project in $(cat projects.txt | grep -ve "^#" -e "^$" | cut -d ":" -f "1" | awk '!a[$0]++'); do
                projects=$projects:$(echo $project)
                project_count=$[project_count+1]
        done
        ## remove first :
        projects=$(echo $projects | /bin/sed 's/://')
}

#===  FUNCTION  ================================================================
#          NAME:  get_groups
#   DESCRIPTION:  find all groups of given project
#    PARAMETERS:  project_name
#       RETURNS:  
#===============================================================================
function get_groups() {

        ## reset groups/groupscount (neccessary for project reload)
        groups=""
        groups_count=0

        ## be carfully: $GROUPS is an BASH internal variable
        for group in  $(cat projects.txt | grep -ve "^#" -e "^$" | grep "$1" | cut -d ":" -f "5" | awk '!a[$0]++'); do
                groups=$groups:$(echo $group)
                groups_count=$[groups_count+1]
        done
        ## remove first :
        groups=$(echo $groups | /bin/sed 's/://')

        # x y z sind mit sonderfunktionen belegt!
        arr_character=( a b c d e f g h i j k l m n o p q r s t u v w )

        for (( i=0;i<$groups_count;i++)); do
                # zur späteren Kontrolle schreiben wir alle BENUTZTEN Buchstaben in ein Array
                arr_character["$i"]="${arr_character[${i}]}"

                # Ausgabe der Gruppen in einer Zeile
                echo -en "[\033[1;33m"${arr_character[${i}]}"\033[0m]\033[1;32m"$( echo $groups | cut -d ":" -f "$(($i+1))" )"\033[0m " 
        done
}


#===  FUNCTION  ================================================================
#          NAME:  print_projectmenu
#   DESCRIPTION:  print out projectmenu for given project
#    PARAMETERS:  project,group
#       RETURNS:  
#===============================================================================
function print_projectmenu() {

        ## reset variables
        GROUP_FILTER=

        ## check if given projectname or projectnumber
        if [[ $1 == ?(-)+([0-9]) ]]; then
          ## projectnumber, read projectname from "projects" string
          project=$( echo $projects | cut -d ":" -f "$1" )
        else
          ## projectname ...
          project=$1
        fi

        ## group filter given
        if [ -n "$2" ]; then

                for i in "${!arr_character[@]}"; do
                        if [ "${arr_character[$i]}" == "$2" ]; then
                                echo iii=$i
                                GROUP_FILTER=$( echo $groups | cut -d ":" -f $(($i+1)) )
                        fi
                done
        fi

        echo GROUP_FILTER=$GROUP_FILTER

        clear
        echo -e " == SSH Sprungmenu ==\n\n Projekt: $project\n"

        ## just read out all groups
        get_groups $project

        # Ausgabe des Headers
        if [ "$PINGHOST" == "true" ]; then
                echo -e "\n\n\033[1;33mID USER\t Host\t\t[Status]\tGruppe\t\tBeschreibung \033[0m "
        else
                echo -e "\033[1;33mID USER\t Host\tGruppe\t\t\tBeschreibung \033[0m "
        fi


        cat projects.txt | grep -ve "^#" -e "^$" | grep -E "^$project.*$GROUP_FILTER"  | while read host ; do 

                LINENUMBER=$[LINENUMBER+1]

                SSHHOST=`echo $host |cut -f 2 -d ':' `
                DESCRIBTION=`echo $host |cut -f 3 -d ':' `
                USERNAME=`echo $host |cut -f 4 -d ':' `
                GROUP=`echo $host |cut -f 5 -d ':' `
                SSHPORT=`echo $host |cut -f 6 -d ':' `

                ## check some variables
                [[ -z $USERNAME ]]              && USERNAME=" \t " || USERNAME=" "$USERNAME" @"
                [[ -z $SSHPORT ]]               && SSHPORT="22"
                [[ "$PINGHOST" == "true" ]]     && ping_host $SSHHOST $SSHPORT || STATUS="\t"

                echo -e "$LINENUMBER$USERNAME $SSHHOST\t$STATUS\t$GROUP\t\t$DESCRIBTION"
        done

        # Ausgabe der Standarteintraege
        echo -en "\n\n     x  Abbruch\n     z  Zurueck ins Basemenu\n ============================\nAuswahl: "
}


#===  FUNCTION  ================================================================
#          NAME:  ping_host
#   DESCRIPTION:  check if given ssh port is open
#    PARAMETERS:  host, portnumber
#       RETURNS:  
#===============================================================================
function ping_host() {

        ## returncode doesn't work in subshell ...
        PING=$(netcat -w 1 -z $1 $2 >> /dev/null 2>&1 ; echo $? )

        [ "$PING" -eq 0 ] \
        && STATUS="[\033[1;32mONLINE\033[0m]" \
        || STATUS="[\033[1;31mOFFLINE\033[0m]"
}


#===  FUNCTION  ================================================================
#          NAME:  check_input
#   DESCRIPTION:  check if given input is correct and digit is in list range
#    PARAMETERS:  input, INPUT2 (optional)
#       RETURNS:  true/false
#===============================================================================
function check_input() {

        ## User cancel
        [ "$1" == "x" ] && ( echo "Du weißt auch nicht was du willst ..." ; kill $MAINPID )

        ## project menu
        if  [ "$2" == "INPUT2" ]; then
                ## back to mainmenu
                if [ "$1" == "z" ]; then 
                        bash $0
        #       ## project was choosen ...
        #       elif [ ! `echo "$1" | grep -E ^[[:lower:]]$` ]; then
        #               ## normally 0 but we need the project loop once again
        #               return 1 
                elif [ `echo $1 | grep -E ^[[:digit:]]+$` ]; then
                        return 0
                else
                        ## happen when projectname is directly given
                        [[ `grep "$project:$1" projects.txt` ]] && return 0 || return 1
                fi
        elif [ `echo "$1" | grep -E ^[[:digit:]]+$` ] && [ "$1" -le "$project_count"  ]; then
                return 0
        else 
                return 1
        fi

}


#===  FUNCTION  ================================================================
#          NAME:  ssh_to_host
#   DESCRIPTION:  connect to host
#    PARAMETERS:  hostname (INPUT2)
#       RETURNS:  true/false
#===============================================================================
function ssh_to_host() {

        ## check if number or hostname given
        if [ `echo $1 | grep -E ^[[:digit:]]+$` ]; then
                ## linenumber
                HOSTSTRING=$(grep "^$project" projects.txt | head -n $1 | tail -n 1 )
        else
                ## hostnme
                HOSTSTRING==$(grep "^$project:$1" projects.txt  )
        fi

        SSHHOST=`echo $HOSTSTRING |cut -f 2 -d ':' `
        USERNAME=`echo $HOSTSTRING |cut -f 4 -d ':' `
        SSHPORT=`echo $HOSTSTRING |cut -f 6 -d ':' `

        [[ -z $USERNAME ]]              || USERNAME="$USERNAME@"
        [[ -z $SSHPORT ]]               && SSHPORT="22"

        echo "Executing: ssh -p $SSHPORT $USERNAME$SSHHOST"
        ssh -p $SSHPORT $USERNAME$SSHHOST 
}


#===  Main Script  =============================================================
#
#
#===============================================================================
while ! check_input $INPUT ; do
        if [ -z $1 ]; then
        clear
        echo " == Super SSH Sprungmenu =="
        echo
        cat projects.txt | grep -ve "^#" -e "^$" | cut -d ":" -f "1" | awk '!a[$0]++' | cat -n
        echo
        echo "     x  Abbruch"
        echo
        echo " ===================="
        echo -ne "Auswahl: "
           read INPUT
        else
           INPUT="$1"
        fi

        get_projects
done

## check if group OR host given
while ! check_input $INPUT2 INPUT2 ; do
        ## nothing was given
        if [ -z $INPUT2 ]; then
                print_projectmenu $INPUT
                read INPUT2
        ## group was given
        elif ( [[ `echo $2 | grep -E ^[[:lower:]]$` ]] || [ `echo $INPUT2 | grep -E ^[[:lower:]]$` ] ); then
                print_projectmenu $INPUT $INPUT2
                read INPUT2
        ## hostnumber or hostname was given
        else 
                INPUT2="$2"
        fi
done

ssh_to_host $INPUT2

