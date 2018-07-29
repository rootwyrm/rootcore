# Patches for pfSense

**IMPORTANT: THIS IS NOT "OPEN" SOURCE. READ THE LICENSE BELOW.**

# License Terms

This code is copyright (c) 2017-* Phillip R. Jaenke, All rights reserved

[Licensed under the Mixed-Use Protective License](https://github.com/rootwyrm/rootcore/blob/master/MUPL.md)

*Your use case and use type matters.*

**BAD FAITH PENTALTIES:**
* $50,000.00 USD minimum for unauthorized inclusion or distribution
* $1.00 USD per unauthorized commercial sale, minimum $25,000.00 USD

# Installation Guide

## Installing the patch
1. Install the `System_Patches` package from the official pfSense repository on ALL cluster members.
2. Navigate to System -> Patches
3. Click "Add New Patch"
4. Fill in Description as: `patch_carp_dyndns`
5. Fill in URL/Commit ID as: `https://raw.githubusercontent.com/rootwyrm/rootcore/master/patch/pfsense/patch_carp_dyndns.patch`
6. Path Strip Count should be `1`
7. Base Directory must be `/`
8. Make sure `Ignore Whitespace` is checked.
9. **(OPTIONAL)** Auto Apply *may be* checked.
10. Repeat steps 1-9 for **ALL CLUSTER MEMBERS**.

## Configuring Dynamic DNS for this patch
1. Create the FIRST Dynamic DNS entry on EACH firewall - This entry **MUST BE UNIQUE** to each firewall, but the specific configuration does not matter.
2. Create the Dynamic DNS entries you want to fail over on ALL firewalls.
3. Create any Dynamic DNS entries you want to be DISABLED on failover on EACH firewall.

## IMPORTANT CAVEATS
* The FIRST Dynamic DNS entry on the firewall will **ALWAYS** be enabled and active.
* **NEVER DELETE THE UNIQUE FIRST DYNAMIC DNS ENTRY. MAKE ALL CHANGES BY EDITING.**
* All OTHER Dynamic DNS entries will be disabled when CARP mode is BACKUP regardless of presence on other firewalls.
* This patch does NOT add configuration syncing for Dynamic DNS! **You must configure Dynamic DNS entries you wish to fail over individually on all firewalls.**
* Dynamic DNS entries will go through a **forced update on failover**. This can cause problems if you are potentially rate-limited.
* Any Dynamic DNS entries which are not present on all firewalls will be DISABLED when the CARP is in BACKUP and will become ENABLED when the CARP is in MASTER
* If a firewall has multiple CARP entries, **ANY MASTER will trigger.** *It is critical to NOT permit split-brain with this patch.*
