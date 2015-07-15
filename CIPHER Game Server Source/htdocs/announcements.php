<?php
require_once('config.inc.php');
require_once('db_inc.php');
connect();
require_once('auth.inc.php');
require_auth();

$message = '';
if (array_key_exists('submit',$_POST) && ($_POST['submit'] == 'submit')) {
	$message = param('message');
	$sql = "INSERT INTO announce VALUES(NULL,$GAMEID,NOW(),\"$message\")";
	if (query($sql)) {
		header("Location: /");
		exit;
	} else {
		$message = "<font color=red>".mysql_error()."</font>";
	}
}

	myhead('New Announcement');
?>
<p><a href='/'>Back</a> to the main screen.</p>
<?php echo $message ?>
<form method=post>
	<p><b>Announce</b></p>
	<p><textarea name='message' <?php echo $textbox?>></textarea></p>
	<p><input type=submit value=submit name=submit></p>
</form>
<?php
	myfooter();
?>
