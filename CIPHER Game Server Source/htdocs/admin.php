<?php
require_once('db_inc.php');
connect();
require_once('layout.inc.php');
require_once('auth.inc.php');
require_auth();

myhead('Admin Page',60);
echo "

<p>On this server you can find:
<ul>
  <li><p>The <a href='scores.php'>scoreboard</a></p>

  <li><p>Do some <a href='announcements.php'>announcements.</a></p>

  <li><p>Everything about <a href='advisories.php?game=$GAMEID'>advisories.</a></p>
  
  <li>Statistics</li>
  <ul>
    <li><p><a href='cross_flags.php'>Which team took flags from which other team?</a></p>
  
    <li><p><a href='team_service.php'>Which team compromised which service?</a></p>
  </ul>

  <li>Game Details</li>
  <ul>
    <li><p>Drones: <a href='drones.php'>Which drones are running?</a></p>
  
    <li><p>Performance: <a href='performance.php'>How the gameserver scripts performing?</a></p>
  
    <li><p>Service status: <a href='service_status.php'>Verbose status on single services</a></p>
  
    <li><p>Service status: <a href='script_history.php'>History on single services</a></p>
  </ul>

  <!-- <li><p><a href='pings.php'>Connectivity Information</a></p>

  <li><p><a href='rules.php'>The rules</a></p> -->

  <li><p><a href='index.php?logout=1'>Logout</a></p>
</ul></p>
";

echo "<h2>Announcements</h2>";

if (is_admin()) print "<p><a href='announcements.php'>New announcement</a></p>";

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
myfooter();
?>
