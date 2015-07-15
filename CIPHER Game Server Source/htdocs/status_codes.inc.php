<?php
	// describe status codes in words
	$descr_status[0] = 'OK';
	$descr_status[1] = 'error';
	$descr_status[5] = 'wrong flag';
	$descr_status[9] = 'output garbled';
	$descr_status[13] = 'network down';
	$descr_status[17] = 'timeout';
	$descr_status[21] = 'foul!';

function status($numerical) {
	global $descr_status;
	if (array_key_exists($numerical,$descr_status)) {
		return $descr_status[$numerical];
	} else {
		return '#'.$numerical;
	}
}
?>
