#!/bin/bash

# Script for simplified work with heat
# Script should be run in direcotry /root/heat via $ . _custom_script_for_heat_use
# Script can be run in any directory with heat templates, however the should be
# named XXtemplate_name.yaml

################################################################################
# Settings
HEATDIR=./lib
ENVDIR=./env

################################################################################
# Functions

function select_template {
  unset options i
  while IFS= read -r -d $'\0' f; do
    options[i++]=$(basename $f)
  done < <(find $HEATDIR -maxdepth 1 -type f -name "*.yaml" -print0 | sort -z)

  printf "Select template:\n\n"
  select opt in "${options[@]}" "Return"; do
    case $opt in
      *.yaml)
        echo $opt
        STACKNAME=${opt:2:${#opt}-7}
        TEMPLATE=$opt
        break
        ;;
      "Return")
        break
        ;;
      *)
        echo "This is not a number"
        ;;
    esac
  done
  tput reset
}

function select_env {
  unset options i
  while IFS= read -r -d $'\0' f; do
    options[i++]=$(basename $f)
  done < <(find $ENVDIR -maxdepth 1 -type f -name "*.yaml" -print0 | sort -z)

  printf "Select environment:\n\n"
  select opt in "${options[@]}" "Do not use environment" "Return"; do
    case $opt in
      *.yaml)
        echo $opt
        ENVNAME=${opt:2:${#opt}-7}
        USEENV=true
	break
        ;;
      "Do not use environment")
	USEENV=false
        break
        ;;
      "Return")
        break
        ;;
      *)
        echo "This is not a number"
        ;;
    esac
  done
  tput reset
}

################################################################################
# Main script
tput reset
TEMPLATE=none
STACKNAME=none

printf "\n*******************************************\n"
printf   "* Custom heat tool for openstack-tutorial *"
printf "\n*******************************************\n"

#printf "\nSelect template:\n"
#select_template

all_done=0
while (( !all_done )); do
  printf "\nSelected template:     $TEMPLATE\n"
  printf "Selected stack name:   $STACKNAME\n\n"
  printf "Options:\n"
  PS3="
Choose your heat option: "
  options=(
             "Select template"
             "Create stack"
             "Show stack"
             "Watch stack status"
             "Delete stack"
             "Force Delete, Create and Watch"
             "Clean screen"
             "Quit"
  )
  select opt in "${options[@]}"
  do
      case $opt in
          "Select template")
              tput reset
              select_template
              break ;;
          "Create stack")
              tput reset
              openstack stack create --template "$HEATDIR/$TEMPLATE" $STACKNAME
              break ;;
          "Show stack")
              tput reset
              openstack stack show $STACKNAME
              break ;;
          "Watch stack status")
              watch -n 1 openstack stack show --max-width 100 $STACKNAME
              tput reset
              break ;;
          "Delete stack")
              printf "\n"
              openstack stack delete $STACKNAME
              tput reset
              break ;;
          "Force Delete, Create and Watch")
              tput reset
              printf "\n"
              openstack stack delete --yes --wait $STACKNAME
              if [ $? -eq 0 ]; then
                openstack stack create --template "$HEATDIR/$TEMPLATE" $STACKNAME
                if [ $? -eq 0 ]; then
                  watch -n 1 openstack stack show --max-width 100 $STACKNAME
                fi
              fi
              break ;;
          "Clean screen")
              tput reset
              break ;;
          "Quit")
              all_done=1;
              break
              ;;
          *) printf  "\nInvalid option\n";;
      esac
  done
done
