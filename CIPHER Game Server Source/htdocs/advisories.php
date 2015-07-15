<?php
require_once('db_inc.php');
connect();
require_once('layout.inc.php');
require_once('auth.inc.php');

$teams = get_teams();
$services = get_services();
$services[0] = '(General Fault)';

$sql_filter='';
if (array_key_exists('service',$_GET)) {
  $serv_descr = param('service');
  if ($serv_descr != 'all') $sql_filter = 'WHERE fi_service = '.$serv_descr;
};

$sql = 'SELECT id, score, submittime, publishtime, fi_service, fi_team, judge, judgecomment FROM advisory '. $sql_filter .' ORDER BY submittime DESC;';

$result = query($sql);

$review = '';
if (is_admin()) $review='<td>Review</td>';

myhead('Advisories');

echo "<p><a href='.'>Back</a> to main screen.</p>";
if (game_has_started()) {
echo "
<p><a href='advisory_submit.php'>Submit</a> a new advisory.</p>
<form method='get'/>
<p>Service <select name='service'><option value='all'>(View all)";
echo dict2options($services);
echo "</select><input type='submit' value='Filter By Service' /></p>


<table border=1 width='100%'>
<tr><td>Service</td><td>Team</td><td>Time</td><td>points</td><td width=20%>Comment</td><td>Display</td>$review</tr>";

  while ($row = mysql_fetch_array($result)) {
    if (!is_numeric($row['score'])) {
      $color='#ffcccc';
      $row['score'] = '?';
    } else {
      $color = 'white';
    }
  
    $time = date("H:i d.m.Y",$row["submittime"]);
    if(!$row['fi_service']) $row['fi_service']=0;
    echo "<tr>
      <td bgcolor='$color'>".$services[$row['fi_service']]."</td>
      <td bgcolor='$color'>".$teams[$row['fi_team']]."</td>
      <td bgcolor='$color'>".$time."</td>
      <td bgcolor='$color' align=right>".$row['score']."</td>";
    if ((is_numeric($row['score']) && isset($row['judge']) && isset($row['judgecomment']))) {
      if (strlen($row['judgecomment'])>0) {
        echo "<td bgcolor='$color'>".$row['judge'].' says &quot;'.$row['judgecomment']."&quot;</td>\n";
      } else {
        echo "<td bgcolor='$color'>".$row['judge']." says nothing.</td>\n";
      }
      if (!$row['publishtime']) {
        if ($row['judge']) {
          echo "<td bgcolor='$color'>(not to be published)</td>";
        } else {
          echo "<td bgcolor='$color'>(not reviewed)</td>";
        }
      } else {
        if (time() > $row['publishtime']) {
  	echo "<td bgcolor='$color'><a href='advisory_display.php?id=".$row['id']."'>Display</a></td>";
        } else {
  	echo "<td bgcolor='$color'>(not yet)</td>";
        }
      }
    } else {
        echo "<td bgcolor='$color'>&nbsp;</td><td bgcolor='$color'>(not reviewed)</td>";
    }
    if (is_admin()) {
            echo "<td bgcolor='$color'><a href='advisory_review.php?id=".$row['id']."'>Review</a></td>";
    } else {
    }
    echo "</tr>\n";
  }

echo "</table>
</form>";
} else {
echo "<p>Game has not started, yet</p>";
};

  myfooter();
// vim: et ts=2
?>
