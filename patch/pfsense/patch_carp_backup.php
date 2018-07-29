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
file_put_contents("/tmp/dyn.stop0", var_export($config['dyndnses'], true) );
// END_DEBUG
// filter out bad items before we proccess
$config['dyndnses']['dyndns'] = array_filter($config['dyndnses']['dyndns']);
foreach($config['dyndnses']['dyndns'] as $dyn_index => $dummy_dyn ) {
	// force all enables to null (disabled)
	$config['dyndnses']['dyndns'][$dyn_index]['enable'] = null;
	// Turn on ID = 0 (first entry)
	if( (string)$config['dyndnses']['dyndns'][$dyn_index]['id'] === "0" ) {
		$config['dyndnses']['dyndns'][$dyn_index]['enable'] = true;
		// DEBUG
		file_put_contents("/tmp/dyn.stop-id0", var_export($config['dyndnses'], true) );
	}
	// Unset enable for all non-ID 0 entries
	if( (string)$config['dyndnses']['dyndns'][$dyn_index]['id'] > "0") {
		unset($config['dyndnses']['dyndns'][$dyn_index]['enable']); 
		file_put_contents("/tmp/dyn.stop-id1", var_export($config['dyndnses'], true) );
	}
}
// DEBUG - write out the array after we've changed the enables
file_put_contents("/tmp/dyn.stop1", var_export($config['dyndnses'], true) );
// END_DEBUG

wc_msg = gettext('CARP triggered DynDNS disable.');
write_config($wc_msg);
