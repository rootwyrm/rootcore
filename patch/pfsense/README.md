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
11. Click `Fetch`
12. Click `Test` - SEE CAVEATS REGARDING REVERTING CLEANLY
13. Click `Apply` **on the current CARP master first**
14. Proceed to Configuring Dynamic DNS

## Configuring Dynamic DNS for this patch
1. Create the FIRST Dynamic DNS entry on EACH firewall - This entry **MUST BE UNIQUE** to each firewall, but the specific configuration does not matter.
2. Create the Dynamic DNS entries you want to fail over on ALL firewalls.
3. Create any Dynamic DNS entries you want to be DISABLED on failover on EACH firewall.

## Verifying the function
1. Go to "Status -> CARP" on your MASTER
2. Click "Enter Persistent CARP Maintenance Mode" and confirm all CARP IPs are in BACKUP
3. Navigate to Dynamic DNS configuration and confirm that entries are grayed out (disabled)
4. Go to your new MASTER node
5. Confirm Dynamic DNS entries are enabled and updated on your new MASTER

## IMPORTANT CAVEATS
* The FIRST Dynamic DNS entry on the firewall will **ALWAYS** be enabled and active.
* **NEVER DELETE THE UNIQUE FIRST DYNAMIC DNS ENTRY. MAKE ALL CHANGES BY EDITING.**
* All OTHER Dynamic DNS entries will be disabled when CARP mode is BACKUP regardless of presence on other firewalls.
* This patch does NOT add configuration syncing for Dynamic DNS! **You must configure Dynamic DNS entries you wish to fail over individually on all firewalls.**
* Dynamic DNS entries will go through a **forced update on failover**. This can cause problems if you are potentially rate-limited.
* Any Dynamic DNS entries which are not present on all firewalls will be DISABLED when the CARP is in BACKUP and will become ENABLED when the CARP is in MASTER
* If a firewall has multiple CARP entries, **ANY MASTER will trigger.** *It is critical to NOT permit split-brain with this patch.*
* **THE PATCH MAY DISAPPEAR FROM YOUR SYSTEM PATCHES BUT STILL BE APPLIED, OR THE PATCH WILL CLAIM TO BE UNABLE TO REVERT CLEANLY.** This is due to code quality issues and limitations of pfSense. If it disappears, re-add the patch, click Fetch, then click Test.
* Using this patch to fail over IPv6 `gif(4)` interfaces using Hurricane Electric [TunnelBroker.net](https://www.tunnelbroker.net/) **IS SUPPORTED** but you must configure the GIF interface on each firewall when it is the MASTER. The GIF interface will behave brokenly on BACKUP nodes but IPv6 should remain working (as the gateway will report down.)
