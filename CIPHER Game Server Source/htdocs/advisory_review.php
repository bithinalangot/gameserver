<?php
require_once('db_inc.php');
connect();
require_once('layout.inc.php');
require_once('misc.inc.php');
require_once('auth.inc.php');
require_auth();

$id = get_int('id');
$size_input_fields = 50;

# action
$message = '';
if (get_string('submit')=='submit') {
	$score = param('score');
	$judge = param('judge');
	$comment = param('comment');
	$publish = get_int('publish');

	if ($publish) {
        	$sql = "UPDATE advisory SET score='$score', judge='$judge', judgecomment='$comment',publishtime=submittime+".($delay_advisory_publishment*60)." WHERE id='$id';";
	} else {
        	$sql = "UPDATE advisory SET score='$score', judge='$judge', judgecomment='$comment',publishtime=NULL WHERE id='$id';";
	}
	if (query($sql)) {
		header("Location: advisories.php");
		exit();
	} else {
		$message = '<font color=red>'.mysql_error().'</font>';
	}
} elseif((get_string("submit") == "delete")&&(get_int('sure')==1)) {

	$sql = "DELETE FROM advisory WHERE id=$id";
	if (query($sql)) {
		header("Location: advisories.php");
		exit();
	} else {
		$message = '<font color=red>'.mysql_error().'</font>';
	}

}

# load data
$sql = "SELECT fi_team,fi_service,advisory,exploit,patch,submittime,score,judge,judgecomment FROM advisory WHERE id = $id";
$result = query($sql);
if($row = mysql_fetch_array($result) ) {
	$service = $row['fi_service'];
	$team = $row['fi_team'];
	$advisory = $row['advisory'];
	$exploit = $row['exploit'];
	$patch = $row['patch'];
	$time = $row['submittime'];
	$time = date("H:i d.m.Y",$row["submittime"]);
	$score = $row['score'];
	$judge = $row['judge'];
	$comment = $row['judgecomment'];
} else {
  die("did not set variable id, or id='$id' is no valid advisory");
}

$teams = get_teams();
$services = get_services();
$services[0] = "(General Fault)";
if(!$service) $service=0;

	myhead('Review Advisory');
?>
<p><a href='advisories.php'>Back</a> to the list.</p>
<?php echo $message; ?>

<form method="post" />
	<input type=hidden name=id value="<?php echo $id; ?>">
	Delete! Are you sure? <input type=checkbox name=sure value="1">
	<input type="submit" name="submit" value="delete" />
</form>

<hr>
	
<form method="post" />
	<input type=hidden name=id value="<?php echo $id; ?>">
	<table>
	<tr><th>Team</th><td><?php echo $teams[$team]; ?></td></tr>
	<tr><th>Service</th><td><?php echo $services[$service]; ?></td></tr>
	<tr><th>Time</th><td><?php echo $time; ?></td></tr>
	<tr><th>Score</th><td><input type="text"       size=10 name="score" value="<?php echo $score; ?>"/></td></tr>
	<tr><th>Publish</th><td><input type="checkbox" value=1 name="publish" checked> (<?php echo " SCORE * $delay_advisory_publishment min nach $time"; ?>) </td></tr>
	<tr><th>Judge</th><td><input type="text"   size=<?php echo $size_input_fields; ?> name="judge" value="<?php echo $judge; ?>" /></td></tr>
	<tr><th>Comment</th><td><input type="text" size=<?php echo $size_input_fields; ?> name="comment" value="<?php echo $comment; ?>" /></td></tr>
	<tr><td colspan=2><input type="submit" name="submit" value="submit" /></td></tr>
	</table>
</form>

<hr>
<h3>Advisory:</h3>
<pre><?php echo stripslashes(htmlentities($advisory)); ?></pre><hr />
<h3>Exploit:</h3>
<pre><?php echo stripslashes(htmlentities($exploit)); ?></pre><hr />
<h3>Patch:</h3>
<pre><?php echo stripslashes(htmlentities($patch)); ?></pre>
<hr>
<?php
	myfooter();
?>
