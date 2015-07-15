<?php
require_once('db_inc.php');
connect();
require_once('layout.inc.php');

myhead('Teams on Services',60);

$fresh_minutes = floor($displayfreshscores/60);

echo "<p><a href='/'>Back to the main page.</a></p>

      <p><font color=red>Red</font> numbers denote flags collected in the last $fresh_minutes minutes.</p>";

if (!($debug || game_has_started())) {

  echo "<center><p>The game has not started, please come back later.</p></center>";

} else {

  $fresh_now = time() - $displayfreshscores;
  $sum_total = 0;

  $teams = get_teams();
  $team_ids = array_keys($teams);
  sort($team_ids);

  $services = get_services();
  $service_ids = array_keys($services);
  sort($service_ids);

  $sum_total = 0;
  foreach($team_ids as $id) {
    $sum_team[$id] = 0;
    foreach($service_ids as $id2) {
      $sum_service[$id2] = 0;
      $fresh[$id][$id2] = 0;
      $old[$id][$id2] = 0;
    }
  }

  $fresh_now = time()-$displayfreshscores;
  $query = query("SELECT fi_team,fi_service,count(*) as nr,unix_timestamp(time) as time 
                  FROM scores WHERE (scores.fi_game=$GAMEID)AND(multiplier>0)
                  GROUP BY fi_team,fi_service,(unix_timestamp(time)>=$fresh_now)");
  while($row = mysql_fetch_array($query)) {
    if ($row['time']>=$fresh_now) {
      $fresh[ $row['fi_team'] ][ $row['fi_service'] ] += $row['nr'];
    } else {
      $old[ $row['fi_team'] ][ $row['fi_service'] ] += $row['nr'];
    }
    $sum_team[ $row['fi_team'] ] += $row['nr'];
    $sum_service[ $row['fi_service'] ] += $row['nr'];
    $sum_total += $row['nr'];
  }

  echo "<p>
        <table border=1 width='100%'>
        <tr><th class=team rowspan=".(sizeof($teams)+3).">T<br>e<br>a<br>m</th><th class=team colspan=".(sizeof($services)+2).">Services</th></tr>
             <tr><td>&nbsp;</td>";
  foreach($service_ids as $id) print "<th class=team>".$services[$id]."</th>";
  print "<th class=team>SUM</th></tr>\n";

  foreach($team_ids as $tid) {
    print "<tr><th class=team>$tid: ".$teams[$tid]."</th>";
    foreach($service_ids as $sid) {
      $fresh1 = $fresh[$tid][$sid];
      $old1   = $old[$tid][$sid];
      if(!$old1) $old1=0;
      if($fresh1>0) {
        print "<td class=score>$old1 + <font color=red>$fresh1</font></td>";
      } else {
        print "<td class=score>$old1</td>";
      }
    }
    print "<td class=sum>".$sum_team[$tid]."</th></tr>\n";
  }
  print "<tr><th class=team>SUM</th>";
  foreach($service_ids as $id) {
    print "<td class=sum>".$sum_service[$id]."</td>";
  }
  print "<td class=sum>".$sum_total."</td></tr></table>\n";

}

myfooter();

?>
