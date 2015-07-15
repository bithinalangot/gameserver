<?php
	require_once('config.inc.php');

function connect() {
	global $dsn,$DB_HOST,$DB_USER,$DB_PWD,$DB_DB;

	$dsn = mysql_connect ($DB_HOST,$DB_USER,$DB_PWD);

	if (!$dsn) {
		die ('Could not connect: '.mysql_error() );
	} else if (!mysql_select_db($DB_DB,$dsn) ) {
		die ('DB not found '.mysql_error() ) ;
	}

	return $dsn;
}

function param($name) {
	if (isset($_REQUEST[$name])) {
		$val = $_REQUEST[$name];
		//if (get_magic_quotes_gpc() || is_numeric($val)) return $val;
		if (get_magic_quotes_gpc()) return $val;
		return mysql_real_escape_string($val);
	} else {
		die("no parameter with name '$name' given");
	}
}

function query($sql) {
	global $dsn;

	if ($result = mysql_query($sql)) {
		return $result;
	} else {
		die("<font color=red>Error in DB-access: ".mysql_error()."</font>");
	}
}

function get_services() {
	global $GAMEID;
	
	# load services data
	$sql = 'SELECT fi_service,name FROM `game_x_service`,service
	        WHERE (`game_x_service`.fi_service=service.id) AND fi_game = '.$GAMEID;
	$result = query($sql);
	while ($row = mysql_fetch_array($result)) {
		$services[$row['fi_service']] = $row['name'];
	}

	return $services;
}

function get_teams() {
	global $GAMEID;

	# load team data
	$sql = 'SELECT fi_team,name FROM `game_x_team`,team 
	        WHERE (`game_x_team`.fi_team=team.id) AND fi_game = '.$GAMEID;
	$result = query($sql);
	while ($row = mysql_fetch_array($result)) {
		$teams[$row['fi_team']] = $row['name'];
	}

	return $teams;
}

function dict2options($dict) {
	$keys = sort(array_keys($dict),SORT_NUMERIC);
	$string = '';
	foreach(array_keys($dict) as $key) {
		$string .= "<option value='$key'>".$dict[$key]."</option>\n";
	}
	return $string;
}

function game_has_started() {
	global $GAMEID;

	$result = query("SELECT unix_timestamp(start) as start FROM game WHERE id=$GAMEID");
	if ($row = mysql_fetch_array($result)) {
		if ($row['start'] <= time()) return True;
		return False;
	} else {
		die(mysql_error());
	}
}

function game_has_stopped() {
	global $GAMEID;

	$result = query("SELECT unix_timestamp(stop) as stop FROM game WHERE id=$GAMEID");
	if ($row = mysql_fetch_array($result)) {
		if ($row['stop'] < time()) return True;
		return False;
	} else {
		die(mysql_error());
	}
}

function game_runs() {
	global $GAMEID;

	$result = query("SELECT unix_timestamp(start) as start,unix_timestamp(stop) as stop FROM game WHERE id=$GAMEID");
	if ($row = mysql_fetch_array($result)) {
		$now = time();
		if (($row['start']<=$now)&&($row['stop'] > $now)) return True;
		return False;
	} else {
		die(mysql_error());
	}
}

?>
