<?php

/**************************************************************************
 patch_carp_master.php
 Copyright (C) 2018-* Phillip R. Jaenke <prj+patchdev@rootwyrm.com>
 All rights reserved.

 This code is licensed under the Mixed-Use Protective License
 http://github.com/rootwyrm/rootcore/MUPL.md
**************************************************************************/
/* All others follow the leader... */
$first = null;
foreach($config['dyndnses']['dyndns'] as $dyn_index => $dummy_dyn ) {
	// DEBUG
	file_put_contents("/tmp/dyn.start0", var_export($config['dyndnses'], true) );
	// END_DEBUG
	$config['dyndnses']['dyndns'][$dyn_index]['enable'] = false;
	if($first == null && (string)$config['dyndnses']['dyndns'[$dyn_index]['id'] == "0") {
		$first = $dyn_index;
	}
	// DEBUG
	file_put_contents("/tmp/dyn.start1", var_export($config'dyndnses'], true) );
	// END_DEBUG
	if($first !== null) {
		$config['dyndnses']['dyndns'[$first]['enable'] = true;
	}
	// DEBUG
	file_put_contents("/tmp/dyn.start2", var_export($config'dyndnses'], true) );
	// END_DEBUG
}

/* Always ensure that DynDNS ID 0 is enabled. */
foreach($config['dyndnses']['dyndns'] as &$dyn_zero) {
	if($dyn_zero['id'] == 0) {
		$dyn_zero['enable'] = true;
	}
}
unset($dyn_zero);

