<?php
require_once('db_inc.php');
connect();
require_once('layout.inc.php');
require_once('auth.inc.php');
require_once('status_codes.inc.php');
require_auth();

myhead('Performance',60);

$term = 'service'; 
if (isset($_REQUEST['term'])) $term=$_REQUEST['term'];
$minutes = 10;
if (isset($_REQUEST['minutes'])) $minutes=get_int('minutes');

echo '<p><a href="admin.php">back to admin</a></p>
  <p><a href="'.$_SERVER['PHP_SELF'].'?term=service">Services</a>
  <p><a href="'.$_SERVER['PHP_SELF']."?term=team\">Teams</a>
  <p><table border=1>
  <tr><th>Name</th><th>Lag in Seconds</th><th>Seconds</th><th>Return Codes (last $minutes minutes)</th></tr>
";

$now = time();
$rows = query("SELECT id,name FROM $term,game_x_$term 
               WHERE ($term.id=game_x_$term.fi_$term)AND(game_x_$term.fi_game=$GAMEID)
               ORDER BY $term.id");
while($row = mysql_fetch_array($rows)) {
  echo "<tr><td>#".$row['id'].":".$row['name']."</td>";
  $subq = query("SELECT unix_timestamp(max(time)) as time,avg(seconds) as sec 
                 FROM performance 
                 WHERE (fi_game=$GAMEID)
                 GROUP BY fi_$term
                 HAVING fi_$term=".$row['id']);
  if ($sub=mysql_fetch_array($subq)) {
    echo "<td align=center>".($now-$sub['time'])."</td><td align=center>".sprintf("%.3f",$sub['sec'])."</td>";
  } else {
    echo "<td colspan=2>(no data yet)</td>";
  }
  echo "<td>";
  // TODO ------------------ fix SQL statement
  //                WHERE (fi_game=$GAMEID)AND(fi_$term=".$row['id'].")AND(DATE_SUB(CURDATE(),INTERVAL $minutes MINUTE)>time)
  $res_q = query("SELECT result,count(result) as n 
                  FROM performance
                  WHERE (fi_game=$GAMEID)AND(fi_$term=".$row['id'].")
                  GROUP BY result
                  HAVING n>0
                  ORDER BY n DESC");
  while($sub = mysql_fetch_array($res_q)) {
    echo '['.$sub['n'].'x <b>'.status($sub['result']).'</b>] '; 
  }
  echo "</td></tr>\n";
}

echo '</table>
      <p>&nbsp;</p>';
myfooter();
?>
