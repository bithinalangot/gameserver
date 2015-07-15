<?php
require_once('db_inc.php');
connect();
require_once('layout.inc.php');
require_once('auth.inc.php');
require_once('misc.inc.php');
require_once('status_codes.inc.php');
require_auth();

myhead('Script History',60);
echo '<p><a href="admin.php">back to admin</a></p>';
$me = $_SERVER['PHP_SELF'];

$show_team    = get_int('team');
$show_service = get_int('service');

//************************************************** SELECT 

echo "<form method=get>
        <table border=1>
	<tr><th colspan=2>Select filter</th></tr>";

$rows = query("SELECT id,name FROM service,game_x_service
               WHERE (service.id=game_x_service.fi_service)AND(game_x_service.fi_game=$GAMEID)
               ORDER BY service.id");
echo'<tr><th>Services</th><td> 
		<select name=service>';
while($row = mysql_fetch_array($rows)) {
	$service[$row['id']] = $row['name'];
	$sel = '';
	if (($show_service==$row['id'])) $sel = 'selected';
	echo "<option $sel value=".$row['id'].">#".$row['id'].' | '.$row['name'];
}
echo "</select></td></tr>
      <tr><th>Teams</th><td> 
		<select name=team>";
$rows = query("SELECT id,name FROM team,game_x_team
               WHERE (team.id=game_x_team.fi_team)AND(game_x_team.fi_game=$GAMEID)
               ORDER BY team.id");
while($row = mysql_fetch_array($rows)) {
	$team[$row['id']] = $row['name'];
	$sel = '';
	if (($show_team==$row['id'])) $sel = 'selected';
	echo "<option $sel value=".$row['id'].">#".$row['id'].' | '.$row['name'];
}
echo "</select></td></tr>
      <tr><td colspan=2 align=right><input type=submit value='Select'></td></tr>
      </table></form><hr>\n";

/*************** quick switch ****************/

echo "<p>Quick Switch Services:";
foreach($service as $sid=>$sname) echo "&nbsp;<a href='$me?service=$sid&team=$show_team'>$sname</a>";
echo "</p>";
echo "<p>Quick Switch Teams:";
foreach($team as $tid=>$tname) echo "&nbsp;<a href='$me?service=$show_service&team=$tid'>$tname</a>";
echo "</p>";

echo "<hr>\n";

/*************************** DISPLAY DATA *********************************/

if (($show_team>0)&&($show_service>0)) {

$now = time();
echo "<center><h3>History of ".$service[$show_service]." at ".$team[$show_team]."</h3></center>";

echo "<table width='100%' border=1>
	<tr><th>Time, Seconds, Status</th>
            <th>Store/Public</th><th>Store/Internal</th><th>Retrieve/Public</th><th>Retrieve/Internal</th></tr>";
$data = query("SELECT time,seconds,result,store_public,store_internal,retrieve_public,retrieve_internal
               FROM performance
               WHERE (fi_game=$GAMEID)AND(fi_service=$show_service)AND(fi_team=$show_team)
               ORDER BY time DESC
               LIMIT 10");
while($row = mysql_fetch_array($data)) {
	echo "<tr>
                 <th>".$row['time']."<br><br>".$row['seconds']." sec.<br>Result:".status($row['result'])."</td>
                 <td><pre>".htmlentities($row['store_public'])."</pre></td>
                 <td><pre>".htmlentities($row['store_internal'])."</pre></td>
                 <td><pre>".htmlentities($row['retrieve_public'])."</pre></td>
                 <td><pre>".htmlentities($row['retrieve_internal'])."</pre></td>
	      </tr>";
}
echo "</table>";

} else {
	echo "<center>Choose something to display</center>";
}
myfooter();
?>
