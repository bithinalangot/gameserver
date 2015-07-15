<?php
require_once('db_inc.php');
connect();
require_once('layout.inc.php');
require_once('auth.inc.php');

if (array_key_exists('logout',$_REQUEST)) {
	if ($_REQUEST['logout']) {
		logout();
	}
}

myhead('Main Page',60);
echo "

<p>On this server you can find:
<ul>
  <li><p>The <a href='scores.php'>scoreboard</a></p>

  <li><p>Everything about <a href='advisories.php?game=$GAMEID'>advisories.</a></p>

  <li><p>Statistics: <a href='team_service.php'>Which team compromised which service?</a></p>

  <!-- <li><p><a href='pings.php'>Connectivity Information</a></p> -->

  <li><p><a href='debugging_info.php'>Services' Status</a></p>

  <li><p><a href='http://www.cipher-ctf.org/CaptureTheFlag.php'>The rules</a></p>
</ul></p>
";

echo "<h2>Announcements</h2>";

$q = query("SELECT unix_timestamp(timestamp) as time,message FROM announce WHERE fi_game=$GAMEID ORDER BY timestamp DESC");
$count = 0;
while($row=mysql_fetch_array($q)) {
  if(!$count) echo '<table border=1 width="100%">';
  $msg_time = strftime("%d.%m. %H:%M",$row['time']);
  echo "<tr><td align=center nowrap>$msg_time</td><td>".$row['message']."</td></tr>";
  ++$count;
}
if ($count) {
  echo '</table>';
} else {
  echo '<i>There are currently no announcements.</i>';
}

echo '<p>&nbsp;</p>';
echo '<p>Go to <a href=admin.php>Admin area</a></p>';
myfooter();
?>
