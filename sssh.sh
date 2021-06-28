#!/usr/bin/env bash

# ##########################################################
# 
#        Super SSH Script 
#
#        Version  2 [06/2021]
#
#        v2    start new version, complete rewrite of code
#        ---
#        V1.9.2   Rewrite project menu output, change from echo to printf
#        V1.9.1   Project overview now accept project names as input [08.11.2017]
#        V1.9     [06.10.2017]
#        V1.8     Added group function again [08.2017]
#        V1.7     Rewrite script - now with functions [06.2016]
#        V1.6     Added function to pass parameters to server menu [05.2012]
#        V1.5     Added function to choose by hostname [05.2012]
#        V1.4     Added group function [11.2011]
#        V1.3     Added avaibility function
#        V1.2     color output
#        V1.0     Create script


## some infos 
##
## There are 3 types of arrays:
##
## - array_projects, contain the projectnames
## - array_${project_name}, dynamic generates from file name
## - array_${host_name}, dynamic generates from project-configuration
##


#### config  ####
## Wenn true wird jeder Host 1x angepingt und der Status ausgegeben
PINGHOST="true" # gueltige Werte [true,false]
DEBUG="false"

## print full fqdn in project menu [default: false]
## fqdn is always used to connect even is deactivated!!
FQDN="false"

#### do not change ####
## used to kill from subshell
MAINPID=$$

## locationOfScript
locationOfScript=$(dirname "$(readlink -e "$0")")

## declare project-array
declare -a array_projects


#===  FUNCTION  ================================================================
#    NAME:  get_projects
#   DESCRIPTION:  read project-files (*.lst) to arrays
#   PARAMETERS:  
#    RETURNS:  
#===============================================================================
function get_projects() {

    ## empty array
    array_projects=()

    array_projects+=('defaults')

    while read file
    do
        projectname=`basename "${file}" .lst`

         ## write projectname to project array
         array_projects+=("${projectname}")
         declare -ga ${projectname}
         eval "${projectname}+=('defaults')"        

         ## parse project file
         while read VARNAME VALUE
         do
             if [ "${VARNAME}" == "HOST" ]
             then
                  HOSTNAME=`echo ${VALUE} | sed 's/-/_/g'`

                  [[ ${HOSTNAME} =~ '.' ]] && { VAR_HOSTNAME=${HOSTNAME}; HOSTNAME=`echo ${HOSTNAME} | cut -d'.' -f1` ; }

                  declare -Ag "${HOSTNAME}"

                  [[ ${VAR_HOSTNAME} ]] && { eval "${HOSTNAME}+=(['fqdn']=\"${VAR_HOSTNAME}\")"; }


                  eval "${projectname}+=(\"${HOSTNAME}\")"
                  continue
             else
                  ## add configuration to host-array
                  ## varnames getting lower case (https://stackoverflow.com/questions/2264428/how-to-convert-a-string-to-lower-case-in-bash/2265268#2265268)
                  ## eval "nas+=([port]="22")"
                  eval "${HOSTNAME}+=([\"${VARNAME,,}\"]=\"${VALUE}\")"
             fi
                                 

         done <<<$( egrep -v "(^\s*$|^#)" "${file}" )

    done <<<$( find ${locationOfScript} -iname *.lst | sort )

}

#===  FUNCTION  ================================================================
#           NAME:  get_groups
#   DESCRIPTION:  find all groups of given project
#    PARAMETERS:  project_name
#        RETURNS:  
#===============================================================================
function get_groups() {

         ## reset groups/groupscount (neccessary for project reload)
         groups=""
         groups_count=0
         counter=0

         ## be carfully: $GROUPS is an BASH internal variable
         declare -n array_project="$project"
         declare -Ag array_groups

         # x y z sind mit sonderfunktionen belegt!
         arr_character=( a b c d e f g h i j k l m n o p q r s t u v w )

         for host in "${array_project[@]}"; do

                  [ "${host}" == "defaults" ] && continue
                  declare -n vars="$host"

                  if [ -n "${vars['group']}" ];
                  then
                      if [[ ! " ${array_groups[@]} " =~ " ${vars['group']} " ]]
                      then
                           eval array_groups+=([\"${arr_character[${groups_count}]}\"]=\"${vars['group']}\")

                           groups_count=$[groups_count+1]
                      fi
                  fi
         done

         ## print groups
         for i in "${!array_groups[@]}"; do
                printf   "[\033[1;33m%s\033[0m]\033[1;32m%s\033[0m " "${i}" "${array_groups[$i]}" 
         done

}


#===  FUNCTION  ================================================================
#           NAME:  get_projectname
#   DESCRIPTION:  detect the project name
#    PARAMETERS:  project nr or name
#        RETURNS:  
#===============================================================================
function get_projectname() {

         declare -g project

         ## check if given projectname or projectnumber
         if [[ $1 =~ ^[0-9]+$ ]] ; then
           ## projectnumber, read projectname from "projects" string
           project="${array_projects["$1"]}"
         else
           ## projectname ...
           project=$1
         fi

}



#===  FUNCTION  ================================================================
#           NAME:  print_mainmenu
#   DESCRIPTION:  print out main menu of all projects
#    PARAMETERS:  
#        RETURNS:  
#===============================================================================
function print_mainmenu() {

    declare -g INPUT_PROJECT

    while ! check_input "${INPUT_PROJECT}"; do
    #         clear
             echo " == Super SSH Sprungmenu =="
             echo
             for i in "${!array_projects[@]}"; do
                 [ $i -ne 0 ] && printf "%6s  %s\n" "$i" "${array_projects[$i]}"
             done
             echo
             echo "     x  Abbruch"
             echo
             echo " ===================="
             echo -ne "Auswahl: "
             read INPUT_PROJECT

    done
}



#===  FUNCTION  ================================================================
#           NAME:  print_projectmenu
#   DESCRIPTION:  print out projectmenu for given project
#    PARAMETERS:  project,group
#        RETURNS:  
#===============================================================================
function print_projectmenu() {

         ## reset variables
         GROUP_FILTER=
         LINENUMBER=

#         clear
         echo -e " == SSH Sprungmenu ==\n\n Projekt: $project\n"

         ## just read out all groups
         get_groups ${project}

         ## group filter given
         if [ -n "$2" ]; then

                  for i in "${!arr_character[@]}"; do
                           if [ "${arr_character[$i]}" == "$2" ]; then
                                    #GROUP_FILTER=$( echo $groups | cut -d ":" -f $(($i+1)) )
                                    GROUP_FILTER=${array_groups["$2"]}
                           fi
                  done
         fi



         # Ausgabe des Headers
         if [ "$PINGHOST" == "true" ]; then
                printf "\n\n\033[1;33m%3s %11s %-25s %-12s %-13s %s\033[0m\n" "ID" "<USER> @" "Host:<port>" "[Status]" "Gruppe" "Beschreibung"
         else
                  echo -e "\033[1;33mID USER\t Host\tGruppe\t\t\tBeschreibung \033[0m "
         fi

         declare -n array_project="$project"

         for host in "${array_project[@]}"; do

#                  GROUP=""


                  [ "${host}" == "defaults" ] && continue

                  declare -n vars="$host"

                  LINENUMBER=$[LINENUMBER+1]

                  SSHHOST=${host}
                  DESCRIBTION="${vars['desc']}"
                  USERNAME="${vars['user']}"
                  GROUP="${vars['group']}"
                  SSHPORT="${vars['port']}"
                  ALIAS="${vars['alias']}"

                  if ( [ -n "${GROUP_FILTER}" ] && [ "${GROUP}" != "${GROUP_FILTER}" ]); then continue; fi

                  [[ -z ${GROUP} ]]                 && SSHPORT="22"

                  ## print full fqdn if defined and not deactivated by conf
                  if ( ${FQDN} && [ ${vars['fqdn']} ] ); then SSHHOST=${vars['fqdn']}; fi
                  ## FQDN allways used to ping host
                  if ( [ ${vars['fqdn']} ] ); then SSHPINGHOST="${vars['fqdn']}"; fi


                  ## check some variables
                  [[ -z ${USERNAME} ]]                && USERNAME="" || USERNAME="$USERNAME @"
                  [[ -z ${SSHPORT} ]]                 && SSHPORT="22"

                [[ "${PINGHOST}" == "true" ]]     && ping_host ${SSHPINGHOST} ${SSHPORT} || STATUS="\t"

                  [[ ! -z ${ALIAS} ]]                 && SSHHOST="${ALIAS}"
                  [[ "${SSHPORT}" != "22" ]]         && SSHPORT_PRINT=":${SSHPORT}"

                printf "%2s %12s %-25s ${STATUSCOLOR}%-12s\033[0m %-13s %s\n" "${LINENUMBER}" "${USERNAME}" "${SSHHOST}${SSHPORT_PRINT}" "${STATUS}" "${GROUP}" "${DESCRIBTION}"
         done

         # Ausgabe der Standarteintraege
         echo -en "\n\n     x  Abbruch\n     z  Zurueck ins Basemenu\n ============================\nAuswahl: "
}


#===  FUNCTION  ================================================================
#           NAME:  ping_host
#   DESCRIPTION:  check if given ssh port is open
#    PARAMETERS:  host, portnumber
#        RETURNS:  
#===============================================================================
function ping_host() {

         ## returncode doesn't work in subshell ...
         PING=$(netcat -w 1 -z $1 $2 >> /dev/null 2>&1 ; echo $? )

         if [ "$PING" -eq 0 ]; then
             STATUS="[UP]"  
            STATUSCOLOR="\033[1;32m"
        else
            STATUS="[DOWN]" 
            STATUSCOLOR="\033[1;31m"
        fi
}


#===  FUNCTION  ================================================================
#           NAME:  check_input
#   DESCRIPTION:  check if given input is correct and digit is in list range
#    PARAMETERS:  PROJECT, HOST (optional)
#        RETURNS:  true/false
#===============================================================================
function check_input() {

         ## if host is given project must known!
         [ -z $2 ] && SEARCHSTRING=$1 || SEARCHSTRING=$2

         case "${SEARCHSTRING}" in

            dummy)
                  return 1
                  ;;

            [[:digit:]]*)
                  ## projectnumber is given
                  ## 0-9
                  if [ -z "$2" ]; then
                      [[ "${!array_projects[@]}" =~ "${1}" ]] && return 0 || return 1
                  else
                      ## array_hosts => dynamic array "{projectname}"
                      declare -n array_hosts="${array_projects[${1}]}"

                      ## check if given digit is an host (index number of array)
                      [[ "${!array_hosts[@]}" =~ "${1}" ]] && return 0 || return 1
                  fi
                  ;;
             z)
                  ## back to mainmenu
                  bash $0
                  ;;
             x)
                  ## exit
                  echo "Du weißt auch nicht was du willst ..."
                  kill $MAINPID
                  ;;
             [[:alpha:]])
                  ## group filter
                  return 1
                  ;;

             [[:alpha:]]*)
                  ## check for project-names
                  ## a-z or A-Z
                  if [ -z "$2" ]; then
                      [[ "${array_projects[@]}" =~ "${1}" ]] && return 0 || return 1
                  else
                      ## array_hosts => dynamic array "{projectname}"
                      declare -n array_hosts="${array_projects[${1}]}"

                      ## check if given project name is in dynamic project array
                      [[ "${array_hosts[@]}" =~ "${1}" ]] && return 0 || return 1
                  fi
                  ;;
             *)
                  return 1
                  ;;
         esac
         
             


}


#===  FUNCTION  ================================================================
#           NAME:  ssh_to_host
#   DESCRIPTION:  connect to host
#    PARAMETERS:  project, host
#        RETURNS:  true/false
#===============================================================================
function ssh_to_host() {

         PROJECT=$1
         HOST=$2

         ## check if number or hostname given
         if [ `echo ${HOST} | grep -E ^[[:digit:]]+$` ]; then
                  ## linenumber
                  declare -n ARR_PROJECT="${PROJECT}"
                  SSHHOST=${ARR_PROJECT[${HOST}]}
         else
                  ## hostname
                  SSHHOST=${HOST}
         fi


          declare -n ARRAY_SSHHOST="${SSHHOST}"
          USERNAME=${ARRAY_SSHHOST["user"]}
          SSHPORT=${ARRAY_SSHHOST["port"]}
          SSHFQDN=${ARRAY_SSHHOST["fqdn"]}

          ## if fqdn is defined we allways connect to this
#          [ -n ${ARRAY_SSHHOST['fqdn']} ] && SSHHOST="${ARRAY_SSHHOST['fqdn']}"
#         TMP_FQDN="${ARRAY_SSHHOST['fqdn']}"
#         [ -n ${SSHFQDN} ] && SSHHOST="${SSHFQDN}"

#         if ( ${ARRAY_SSHHOST['fqdn']} && [ -n ${ARRAY_SSHHOST['fqdn']} ] ); then SSHHOST="${ARRAY_SSHHOST['fqdn']}"; fi

         ## add ssh-parameter if optional params defined
         [[ -n ${USERNAME} ]] && USERNAME="-l ${USERNAME}"
         [[ -n ${SSHPORT} ]]  && SSHPORT="-p ${SSHPORT}"
         [[ -n ${SSHFQDN} ]] && SSHHOST="${SSHFQDN}"

         echo "Executing: ssh $SSHPORT $USERNAME $SSHHOST"
         ssh $SSHPORT $USERNAME $SSHHOST 
}


#===  FUNCTION  ================================================================
#           NAME:  debug
#   DESCRIPTION:  print the arrays
#    PARAMETERS:  
#        RETURNS:  
#===============================================================================
function debug() {

         echo -e '\n### DEBUG START ##########################\n'
    
             echo "Debug: array_projects"
             for project in "${array_projects[@]}"; do

                  echo -e "\nproject: $project"

                  declare -n hosts="${project}"

                  for host in "${hosts[@]}"; do

                      declare -n vars="${host}"
                      printf "  - %s\n" "server: ${host}"

                      for i in "${!vars[@]}"; do
                           printf "     - %s: %s\n" "$i" "${vars[$i]}"
                      done
                  done

             done


         echo -e '\n### DEBUG END ############################\n'
}

#===  Main Script  =============================================================
#
#
#===============================================================================
INPUT_PROJECT=$1
[ -n "$2" ] && INPUT_HOST="$2" || INPUT_HOST="dummy"

get_projects

if ${DEBUG}; then debug; fi

print_mainmenu

get_projectname ${INPUT_PROJECT}

## check if group OR host given

while ! check_input "${INPUT_PROJECT}" "${INPUT_HOST}" ; do
    print_projectmenu "${INPUT_PROJECT}" "${INPUT_HOST}"
    read INPUT_HOST
    INPUT_HOST="${INPUT_HOST:-dummy}"
done


ssh_to_host ${project} ${INPUT_HOST} 

