<?php
require_once('db_inc.php');
connect();
require_once('layout.inc.php');
require_once('misc.inc.php');

$id = get_int('id');

# load data
$sql = "SELECT fi_team,fi_service,advisory,exploit,patch,submittime,publishtime,score,judge,judgecomment FROM advisory WHERE id = $id";
$result = query($sql);
if($row = mysql_fetch_array($result) ) {
	$service = $row['fi_service'];
	$team = $row['fi_team'];
	$advisory = $row['advisory'];
	$exploit = $row['exploit'];
	$patch = $row['patch'];
	$submittime = $row['submittime'];
	$publishtime = $row['publishtime'];
	$time = date("H:i d.m.Y",$row["submittime"]);
	$score = $row['score'];
	$judge = $row['judge'];
	$comment = $row['judgecomment'];
} else {
  die("no advisory id='$id'");
}

if (time() <= $publishtime) 
	die("this advisory is not yet to be published");

if (!(strlen($publishtime)))
	die("advisory not to be published");

if (!(strlen($score) && strlen($judge) && strlen($comment)))
	die("advisory not reviewed");

$teams = get_teams();
$services = get_services();
$services[0] = "(General Fault)";
if(!$service) $service=0;

	myhead('Display Advisory');

echo "<p><a href='advisories.php'>Back</a> to the list.</p>

<hr>

<p>Advisory from <b>".$teams[$team]."</b> on Service <b>".$services[$service]."</b></p>
<p>Submitted at $time</p>
<p>Scored by $judge with $score scores.<br>
	<blockquote>Comment: &quot;$comment&quot;</blockquote>
</p>

<hr />

<h3>Advisory:</h3>
<pre>".stripslashes(htmlentities($advisory))."</pre>

<hr />

<h3>Exploit:</h3>
<pre>".stripslashes(htmlentities($exploit))."</pre>

<hr />

<h3>Patch:</h3>
<pre>".stripslashes(htmlentities($patch))."</pre>

";

	myfooter();
?>
