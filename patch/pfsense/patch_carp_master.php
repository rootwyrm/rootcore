<?php

/**************************************************************************
 patch_carp_master.php
 Copyright (C) 2018-* Phillip R. Jaenke <prj+patchdev@rootwyrm.com>
 All rights reserved.

 This code is licensed under the Mixed-Use Protective License
 http://github.com/rootwyrm/rootcore/MUPL.md
**************************************************************************/
/* All others follow the leader... */
// DEBUG - dump the source array before we fuck with it
file_put_contents("/tmp/dyn.start0", var_export($config['dyndnses'], true) );
// END_DEBUG
// filter out bad items before we proccess
$config['dyndnses']['dyndns'] = array_filter($config['dyndnses']['dyndns']);
foreach($config['dyndnses']['dyndns'] as $dyn_index => $dummy_dyn ) {
	// force all enables to null (disabled)
	$config['dyndnses']['dyndns'][$dyn_index]['enable'] = null;
	// Turn on ID = 0 (first entry)
	if( (string)$config['dyndnses']['dyndns'][$dyn_index]['id'] === "0" ) {
		$config['dyndnses']['dyndns'][$dyn_index]['enable'] = true;
	}
	// Switched DynDNS entries are all above ID 0
	if( (string)$config['dyndnses']['dyndns'][$dyn_index]['id'] > "0") {
		$config['dyndnses']['dyndns'][$dyn_index]['enable'] = true;
	}
}
// DEBUG - write out the array after we've changed the enables
file_put_contents("/tmp/dyn.start1", var_export($config['dyndnses'], true) );
// END_DEBUG

// Write config before forcing update
write_config("CARP triggered DynDNS enable.");

// Force update.
shell_exec("/etc/rc.dyndns.update");

