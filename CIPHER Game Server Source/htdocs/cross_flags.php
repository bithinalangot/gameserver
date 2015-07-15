<?php
require_once('db_inc.php');
connect();
require_once('layout.inc.php');

myhead('Cross Flags',60);

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

  foreach($team_ids as $id) {
    $sum_taken[$id] = 0;
    $sum_given[$id] = 0;
    foreach($team_ids as $id2) {
      $fresh[$id][$id2] = 0;
      $old[$id][$id2] = 0;
    }
  }

  $query = query('SELECT scores.fi_team as winner,`flag`.fi_team as looser,count(*) as nr,unix_timestamp(time) as time '.
                 'FROM scores,`flag` '.
                 "WHERE (scores.fi_game=$GAMEID)AND(`flag`.fi_game=$GAMEID)AND(scores.fi_flag=`flag`.id)".
                 "   AND(multiplier>0) GROUP BY winner,looser,(unix_timestamp(time)>=$fresh_now)");
  while($row = mysql_fetch_array($query)) {
    if ($row['time']>=$fresh_now) {
      $fresh[ $row['winner'] ][ $row['looser'] ] += $row['nr'];
    } else {
      $old[ $row['winner'] ][ $row['looser'] ] += $row['nr'];
    }
    $sum_taken[ $row['winner'] ] += $row['nr'];
    $sum_given[ $row['looser'] ] += $row['nr'];
    $sum_total += $row['nr'];
  }

  echo "<p>
        <table border=1 width='100%'>
        <tr><th class=team rowspan=".(sizeof($teams)+3).">T<br>a<br>k<br>e<br>r<br>s</th><th class=team colspan=".(sizeof($teams)+2).">Givers</th></tr>
             <tr><td>&nbsp;</td>";
  foreach($team_ids as $id) print "<th class=team>$id</th>";

  print "<th class=team>SUM</th></tr>\n";
  foreach($team_ids as $taker) {
    print "<tr><th class=team>$taker: ".$teams[$taker]."</th>";
    foreach($team_ids as $giver) {
      $fresh_ = $fresh[$taker][$giver];
      $old_   = $old[$taker][$giver];
      if(!$old_) $old_=0;
      if($fresh_>0) {
        print "<td class=score>$old_ + <font color=red>$fresh_</font></td>";
      } else {
        print "<td class=score>$old_</td>";
      }
    }
    print "<td class=sum>".$sum_taken[$taker]."</th></tr>\n";
  }

  print "<tr><th class=team>SUM</th>";
  foreach($team_ids as $id) {
    print "<td class=sum>".$sum_given[$id]."</td>";
  }
  print "<td class=sum>".$sum_total."</td></tr></table>\n";

}

myfooter();

?>
