<?php
require_once('db_inc.php');
connect();
require_once('layout.inc.php');
require_once('auth.inc.php');
require_auth();

myhead('Drones',60);

echo '<p><a href="admin.php">back to admin</a></p>
	<table border=1 cellpadding=3 cellspacing=3>
      	<tr><th>id</th><th>Heartbeat</th><th>host</th><th>PID</th><th>Status</th><th>On Service</th></tr>
';

$query = query("SELECT id,unix_timestamp(heartbeat) as hb,host,pid,status FROM drone ORDER by id");
$now = time();
while($row = mysql_fetch_array($query)) {
	$sub_q = query("SELECT service.name FROM service,service_status 
                        WHERE (service.id=service_status.fi_service)AND(service_status.fi_drone=".$row['id'].")");
        $on_service = '<idle>';
        if ($sub_r = mysql_fetch_array($sub_q)) $on_service = $sub_r['name'];
	echo "<tr><td>".$row['id']."</td><td>".($now-$row['hb'])." sec ago</td>
	<td>".$row['host']."</td> <td>".$row['pid']."</td> <td>".$row['status']."</td><td>$on_service</td></tr>\n";
}

echo '</table>
      <p>&nbsp;</p>';
myfooter();
?>
