<?php
require_once('db_inc.php');
connect();
require_once('layout.inc.php');
require_once('auth.inc.php');
require_once('misc.inc.php');
require_once('status_codes.inc.php');
require_auth();

myhead('Verbose Status of Services',60);
echo '<p><a href="admin.php">back to admin</a></p>';
$me = $_SERVER['PHP_SELF'];

$term = ''; 
if (isset($_REQUEST['term'])) $term=$_REQUEST['term'];
$id  = get_int('id');

//************************************************** SELECT 

echo "<table border=1>
	<tr><th colspan=2>Select filter</th></tr>";

$rows = query("SELECT id,name FROM service,game_x_service
               WHERE (service.id=game_x_service.fi_service)AND(game_x_service.fi_game=$GAMEID)
               ORDER BY service.id");
echo'<tr><th>Services</th><td> <form method=get>
		<input type=hidden name=term value=service>
		<select name=id>';
while($row = mysql_fetch_array($rows)) {
	$service[$row['id']] = $row['name'];
	$sel = '';
	if (($term=='service')&&($id==$row['id'])) $sel = 'selected';
	echo "<option $sel value=".$row['id']."'>#".$row['id'].' | '.$row['name'];
}
echo "</select><input type=submit value='OK'></form></td></tr>
      <tr><th>Teams</th><td> <form method=get>
		<input type=hidden name=term value=team>
		<select name=id>";
$rows = query("SELECT id,name FROM team,game_x_team
               WHERE (team.id=game_x_team.fi_team)AND(game_x_team.fi_game=$GAMEID)
               ORDER BY team.id");
while($row = mysql_fetch_array($rows)) {
	$team[$row['id']] = $row['name'];
	$sel = '';
	if (($term=='service')&&($id==$row['id'])) $sel = 'selected';
	echo "<option $sel value=".$row['id']."'>#".$row['id'].' | '.$row['name'];
}
echo "</select><input type=submit value='OK'></form></td></tr>\n";
echo "</table><hr>\n";

/*************************** DISPLAY DATA *********************************/

if (($id>0)&&($term!='')) {


$now = time();
if ($term == 'team') {
	$rows = $service;
	$cols = $team;
	$other = 'service';
} else {
	$rows = $team;
	$cols = $service;
	$other = 'team';
}
echo "<center><h3>$term: #$id ".$cols[$id]."</h3></center>";

echo "<table width='100%' border=1>
	<tr><th>$other</th><th>Last change</th><th>Status</th><th>Public Info</th><th>Internal Info</th></tr>";
reset($rows);
while(list($i,$name) = each($rows)) {
	echo "<tr><th>#$i:$name</th>";
	$subq = query("SELECT unix_timestamp(last_change) as time,info,debug,status FROM service_status
                      WHERE (fi_game=$GAMEID)AND(fi_$other=$i)AND(fi_$term=$id)");
	if ($sub=mysql_fetch_array($subq)) {
		echo "<td>".($now-$sub['time'])." sec ago</td>
                      <td>".status($sub['status'])."</td>
                      <td><pre>".htmlentities($sub['info'])."</pre></td>
                      <td><pre>".htmlentities($sub['debug'])."</pre></td>";
	} else {
		echo "<td>(no data yet)</td>";
	}
	echo "</tr>";
}
echo "</table>";

} else {
	echo "<center>Choose something to display</center>";
}
myfooter();
?>
