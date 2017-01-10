# ZimbraScripts
Miscellaneous Zimbra Collaboration scripts and tools

## zimbra_populateserver.sh - Populate a Zimbra server
Create a batch of sample domains, mailboxes, distribution lists and classes of service for testing purpouses
```
Usage: $0  [-h] [-d domains] [-m mailboxes] [-l dlists] [-c cos] [-t 1]

[-h] = Print this help message and exit.
[-d domains] = Number of domains to create.
[-m mailboxes] = Number of domains to create.
[-l dlists] = Number of domains to create.
[-c cos] = Number of domains to create.
[-t 1] = Test Mode - create scripts but don't change the system.

All arguments are optional, if any argument is missing you'll be prompted to either fall back to default values or quit.

```
