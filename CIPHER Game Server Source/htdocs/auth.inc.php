<?php
	require_once('config.inc.php');
	require_once('layout.inc.php');

	session_start();

function is_admin() {
	global $password_hash;
	if (!array_key_exists('hash',$_SESSION)) return false;
	return $_SESSION['hash']==$password_hash;
}

function logout() {
	global $password_hash;
	unset($_SESSION['hash']);
}

function require_auth() {
	global $password_hash,$GAMEID;

	# already authenticated
	if (is_admin()) return;

	# in the process of authentication
	if (array_key_exists('password',$_REQUEST)) {
		$pwd_given = $_REQUEST['password'];
		$pwd_hash = md5($pwd_given);
		if ($pwd_hash == $password_hash) { 
			$_SESSION['hash']=$password_hash;
			header("Location: ".$_REQUEST['goto']);
			return;
		}
	}

	# before authentication
	myhead("Enter password");
	#echo '<pre>'.print_r($_SERVER,True).'</pre>';
	echo "
		<form method=post>
			<input type=hidden name=goto value='".$_SERVER['REQUEST_URI']."'>
			<p>Enter password: <input type=password name=password></p>
			<p><input type=submit value='Login'></p>
		</form>
	";
	myfooter();
	exit;
}

?>
