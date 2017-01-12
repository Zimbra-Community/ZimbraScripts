#!/bin/bash

usage(){
  echo ""
  echo "Usage: $0  [-h] [-d domains] [-m mailboxes] [-l dlists] [-c cos] [-t 1]"
  echo ""
  echo "[-h] = Print this help message and exit."
  echo "[-d domains] = Number of domains to create"
  echo "[-m mailboxes] = Number of domains to create"
  echo "[-l dlists] = Number of domains to create"
  echo "[-c cos] = Number of domains to create"
  echo "[-t 1] = Test Mode - create scripts but don't change the system."
  echo ""
  echo "At least one argument between \"-d\", \"-m\" \"-l\", \"-c\" and \"-t\" is required, if any argument is missing you'll be prompted to either fall back to default values or quit."
  echo "If no argument at all is entered or if -h is specified, the script will display this usage message and quit."
  echo ""
  }

# Check user
  if [ "$(whoami)" != 'root' ]; then
          echo "Must run as root"
          exit 1;
  fi

# Setting Defaults
  DOMAINS=10
  MAILBOXES=100
  LISTS=10
  COS=10
  DRYRUN=0

# Argument validation
if [ $# -eq 0 ]; then
		usage
		exit 1
	fi

while getopts :d:m:l:c:t:h opts; do
  if [ "$OPTARG" -eq "$OPTARG" ] &>/dev/null
  then
    case ${opts} in
      d) DOMAINS=${OPTARG} ;;
      m) MAILBOXES=${OPTARG} ;;
      l) LISTS=${OPTARG} ;;
      c) COS=${OPTARG} ;;
      t) DRYRUN=${OPTARG} ;;
      h) usage ; exit 1;;
    esac
  else
    echo ""
    echo "ERROR: All parameters must be integers. Check parameter $OPTARG and retry."
    exit 1
  fi
done

if [ $# -lt 8 ]; then
  echo ""
  echo "Not enough arguments, any missing value will fall back to default (Domains: 10 | Mailboxes 100 | DLists 10 | COS 10)"
  read -r -p "Do you want to continue? [y/n] " response
    if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
      then
        echo ""
        echo "Falling back to default for missing values"
      else
        echo ""
        echo "Closing..."
        exit 0
    fi
fi

# Create .zmprov files
## Domains
let DOMAINS_R=$DOMAINS-1
for i in `eval echo {0..$DOMAINS_R}`; do echo "cd example$i.com"; done > /tmp/createDomain.zmprov
## Mailboxes
for i in `eval echo {1..$MAILBOXES}`; do echo "ca user$i@example$(($i % $DOMAINS)).com \"\" displayName User$i cn User$i"; done > /tmp/createAccount.zmprov
## Dlists
let LISTS_R=$LISTS-1
for i in `eval echo {0..$LISTS_R}`; do echo "cdl dl$i@example$(($i % $DOMAINS)).com"; done > /tmp/createDlist.zmprov
## Populate Dlists
for i in `eval echo {1..$MAILBOXES}`; do echo "adlm dl$(($i % $LISTS))@example$(($i % $DOMAINS)).com user$i@example$(($i % $DOMAINS)).com"; done > /tmp/popDlist.zmprov
## Create Classes of Service
for i in `eval echo {1..$COS}`; do echo "cc CoS$i" ; done > /tmp/createCOS.zmprov
## Populate Classes of Service
COSLIST=(`su - zimbra -c "zmprov gac -v | grep -i zimbraid: | sed 's/zimbraId: //'"`)
for i in `eval echo {1..$MAILBOXES}`; do echo "ma user$i@example$(($i % $DOMAINS)).com zimbraCosID ${COSLIST[$(($i % $DOMAINS))]}"; done > /tmp/popCOS.zmprov
unset COSLIST

# Populate server (only if not in dry run mode)
if [[ $DRYRUN -eq 1 ]] ; then
  echo ""
  echo "Test Mode selected, script files were created in /tmp but not executed."
  echo "To manually run the scripts, execute \"zmprov -f filename.zmprov\" as the zimbra user."
  echo ""
  echo "Exiting..."
  exit 0
else
  echo "Creating $DOMAINS domains."
  su - zimbra -c "zmprov -f /tmp/createDomain.zmprov" > /dev/null
  echo "Creating $MAILBOXES mailboxes"
  su - zimbra -c "zmprov -f /tmp/createAccount.zmprov" > /dev/null
  echo "Creating $LISTS Distribution Lists"
  su - zimbra -c "zmprov -f /tmp/createDlist.zmprov" > /dev/null
  echo "Populating Distribution Lists"
  su - zimbra -c "zmprov -f /tmp/popDlist.zmprov" > /dev/null
  echo "Creating $COS Classes of Service"
  su - zimbra -c "zmprov -f /tmp/createCOS.zmprov" > /dev/null
  echo "Polulating Classes of Service"
  su - zimbra -c "zmprov -f /tmp/popCOS.zmprov" > /dev/null
fi
