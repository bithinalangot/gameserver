<?php
require_once('db_inc.php');
connect();
require_once('config.inc.php');
require_once('layout.inc.php');
require_once('misc.inc.php');

if (game_has_stopped())
  die("game has stopped"); 

$message = '';
$game_runs=1;
if (game_runs()) {
  if (array_key_exists('submit',$_POST)) {

    $team = get_int('team');
    if($team==0) die("you'd better choose a team");
    $service = get_int('service');
    $advisory = param('advisory');
    $exploit = param('exploit');
    $patch = param('patch');

    if ($service) {
      $sql = "INSERT INTO advisory (fi_team,fi_service,submittime,advisory,exploit,patch) 
              VALUES ('$team','$service',".time().",'$advisory','$exploit','$patch');";
	  } else {
      $sql = "INSERT INTO advisory (fi_team,submittime,advisory,exploit,patch) 
              VALUES ('$team',".time().",'$advisory','$exploit','$patch');";
    };
    if (query($sql)) {
      header("Location: advisories.php");
      exit();
    } else {
      $message = '<p><font color=red>'.mysql_error().'</font></p>';
    }
  }
} else {
  $game_runs=0;
  $message = '<p><font color=red>Game is currently not active.</font></p>';
}

# load data
$teams = get_teams();
$services = get_services();

# main display
  myhead('Advisory Submission Page');
  echo "<p><a href='advisories.php'>Back</a> to last screen.</p>";
  echo $message;
  if(!$game_runs) exit();
?>

<ul>
  <li>Advisories should be in <b>English</b>, bitte.</li>
  <li>Advisories will be considered first come, first served.</li>
  <li>Length, Detail, and Correctness will be the criteria judged to award points.</li>
</ul>

<form action="advisory_submit.php" method="post" >
  <p>Team Name:<select name="team">
  <option value='0'>-- PLS CHOOSE TEAM --
  <?php echo dict2options($teams) ?>
  </select></p>
  <p>Service:<select name="service">
  <option value='0'>- General fault-</option>
  <?php echo dict2options($services); ?>
  </select></p>
  <p>Advisory :</p>
  <p><textarea <?php echo $textbox ?> name="advisory"></textarea></p>
  <p>Exploit :</p>
  <p><textarea <?php echo $textbox ?> name="exploit"></textarea></p>
  <p>Patch :</p>
  <p><textarea <?php echo $textbox ?> name="patch"></textarea></p>
  <p><input type="submit" name="submit" value="submit" /> </p>
</form>
<?php
    myfooter();
?>
