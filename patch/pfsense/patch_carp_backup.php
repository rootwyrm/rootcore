/**************************************************************************
 patch_carp_master.php
 Copyright (C) 2018-* Phillip R. Jaenke <prj+patchdev@rootwyrm.com>
 All rights reserved.

 This code is licensed under the Mixed-Use Protective License
 http://github.com/rootwyrm/rootcore/MUPL.md
 BAD FAITH PENALTIES:
 - $50,000.00 USD minimum for unauthorized inclusion or distribution
 - $1.00 USD per unauthorized commercial sale, minimum $25,000.00 USD
**************************************************************************/
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
		file_put_contents("/tmp/dyn.stop0a", var_export($config['dyndnses'], true) );	
		$config['dyndnses']['dyndns'][$dyn_index]['enable'] = true;
		$config['dyndnses']['dyndns'][$dyn_index]['force'] = true;
		file_put_contents("/tmp/dyn.stop0b", var_export($config['dyndnses'], true) );	
	}
	// Unset enable for all non-ID 0 entries
	if( (string)$config['dyndnses']['dyndns'][$dyn_index]['id'] > "0") {
		file_put_contents("/tmp/dyn.stop1a", var_export($config['dyndnses'], true) );	
		unset($config['dyndnses']['dyndns'][$dyn_index]['enable']); 
		file_put_contents("/tmp/dyn.stop1b", var_export($config['dyndnses'], true) );	
	}
}
// DEBUG - write out the array after we've changed the enables
file_put_contents("/tmp/dyn.stop1", var_export($config['dyndnses'], true) );
// END_DEBUG

write_config("CARP triggered DynDNS disable.");
