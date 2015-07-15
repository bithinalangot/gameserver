<?php
	$debug = 1;

	$GAMEID = 2;

	# USED FOR DEBUGGING
	if ($debug) {
		error_reporting(E_ALL);
	} else {
		error_reporting(E_NONE);
	};

	$DB_HOST = '127.0.0.1';
	$DB_USER = 'cipher4';
	$DB_PWD = 'zmlf5GGmpeXp';
	$DB_DB = 'ctf';

	$textbox = "cols='70' rows='10'";
	$displayfreshscores = 600;
	$include_advisories_to_extra_score = 1;

	$delay_advisory_publishment = 30;  # in minutes per score
	#$delay_advisory_publishment = 1;

	$password_hash = '44643e20ea02c4c4ef3566cf033f900a'; # md5sum

?>
