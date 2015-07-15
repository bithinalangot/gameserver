<?php
require_once('db_inc.php');
connect();
require_once('layout.inc.php');
require_once('status_codes.inc.php');
require_once('auth.inc.php');

myhead('Scoreboard',60);

if (is_admin()) {
	echo "<p><a href='admin.php'>Back to the admin page.</a></p>";
} else {
	echo "<p><a href='/'>Back to the main page.</a></p>";
};
echo "<p>For an explanation of the scoring system please check 
  <a href='http://www.cipher-ctf.org/CaptureTheFlag.php' target='_blank'>this page</a>.</p>";

if (!($debug || game_has_started())) {

  echo "<center><p>The game has not started, please come back later.</p></center>";

} else {

  $teams = get_teams();
  $team_ids = array_keys($teams);
  sort($team_ids);

  $services = get_services();
  $service_ids = array_keys($services);

  //*********** read absolute results
  $use_extra_score = 0;
  $max_offensive = 1;
  $max_defensive = 1;
  $max_extra = 1;
  foreach($team_ids as $id) {
    $row = mysql_fetch_array(query("SELECT sum(score) as sum FROM scores WHERE (fi_game=$GAMEID)and(fi_team=$id)and(multiplier>0)"));
    $offensive[$id] = $row['sum'];
    $row = mysql_fetch_array(query("SELECT sum(score) as sum FROM scores WHERE (fi_game=$GAMEID)and(fi_team=$id)and(multiplier=0)"));
    $defensive[$id] = $row['sum'];
    $row = mysql_fetch_array(query("SELECT score_extra FROM `game_x_team` WHERE (fi_game=$GAMEID)and(fi_team=$id)"));
    $extra[$id] = $row['score_extra'];
    if ($include_advisories_to_extra_score) {
      $row = mysql_fetch_array(query("SELECT sum(score) as sum FROM advisory WHERE (fi_team=$id)"));
      $extra[$id] += $row['sum'];
    }
    if ($extra[$id]>0) $use_extra_score = 1;
    if ($offensive[$id] > $max_offensive) $max_offensive = $offensive[$id];
    if ($defensive[$id] > $max_defensive) $max_defensive = $defensive[$id];
    if ($extra[$id] > $max_extra) $max_extra = $extra[$id];
  }

  //************* normalize and sort
  $scores_max = 1;
  foreach($team_ids as $id) {
    $offensive[$id] = $offensive[$id]*100/$max_offensive;
    $defensive[$id] = $defensive[$id]*100/$max_defensive;
    $extra[$id] = $extra[$id]*100/$max_extra;
    $scores[$id] = $offensive[$id] + $defensive[$id] + $extra[$id];
    if ($scores[$id]>$scores_max) $scores_max=$scores[$id];
  }
  foreach($team_ids as $id) {
    $scores[$id] = $scores[$id]*100/$scores_max;
  }
  arsort($scores);
  $score_ids = array_keys($scores);
  

  // **************** output
  print "<table border=1 width='100%'>
          <tr><th class=team>&nbsp;</th>
              <th class=head>Total</th>
              <th class=head>Offensive</th>
              <th class=head>Defensive</th>";
  if( $use_extra_score) print "<th class=head>Ethical</th>";
  foreach($service_ids as $id)
    print "<th class=head>".$services[$id]."</th>";
  print "</tr>\n";

  foreach($score_ids as $id) {
    $logo_filename = "team$id.png";
    if (file_exists($logo_filename)) {
    	$logo_filename="<img src='$logo_filename'>";
    } else {
    	$logo_filename = '';
    }
    print "<tr>
            <th class=team>".$logo_filename.$teams[$id]."</th>
            <td class=score>".floor($scores[$id])."</td>
            <td class=score>".floor($offensive[$id])."</td>
            <td class=score>".floor($defensive[$id])."</td>";
    if($use_extra_score) print "<td class=score>".floor($extra[$id])."</td>\n";
    foreach($service_ids as $serv_id) {
      if ($row = mysql_fetch_array(query("SELECT status FROM service_status WHERE (fi_game=$GAMEID)and(fi_service=$serv_id)and(fi_team=$id)"))) {
        if ($row['status']==0) {
          print "<td class=statusup>".status($row['status'])."</td>\n";

        } elseif ($row['status']==5) {
          print "<td class=statusbroken>".status($row['status'])."</td>\n";
        } elseif ($row['status']==9) {
          print "<td class=statusbroken>".status($row['status'])."</td>\n";

        } else {
          print "<td class=statusdown>".status($row['status'])."</td>\n";
        }
      } else {
        print "<td class=statusdown>(game not<br>started)</td>\n";
      }
    }
    print "</tr>\n";
  }
  print "</table>\n";

}

myfooter();

?>
