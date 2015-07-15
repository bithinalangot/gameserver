<?php

function get_int($name,$default=0) {
	if(array_key_exists($name,$_REQUEST)) {
		if (isset($_REQUEST[$name])) {
			return (int) $_REQUEST[$name];
		}
	}
	return (int) $default;
}

function get_string($name,$default='') {
	if(array_key_exists($name,$_REQUEST)) {
		if (isset($_REQUEST[$name])) {
			return (string) $_REQUEST[$name];
		}
	}
	return (string) $default;
}

?>
