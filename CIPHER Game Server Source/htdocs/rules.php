<?php
require_once('layout.inc.php');

myhead('The rules',3600);

echo "<p><a href='.'>Back</a> to main screen.</p>

<p>Due to frequent requests and of course for consistency reasons, this page
lists the rules that are applicable in the game &quot;Cipher 3&quot;</p>

<h2>Preface</h2>

<p>IT security is an interesting area, where skills, and knowledge can make people powerful.
   The intention of the Cipher contests is to educate and train users in their skills, as well 
   as raising their awareness on IT security issues.</p>

<p>However, abusing these skills will bring woe and destruction to our world. We therefore want to
   make sure that participants in out contests are aware of their moral obligations, by setting up
   a few rules. The rules' purpose is to ensure that the contest remains fun for honest participants
   and ensure smooth operation. We therefore tried to keep the set of rules as small and
   transparent as possible.</p>

<h2>The Rules</h2>

<p><ul>
";

function rule($title,$content) {
  return "<li><b>$title</b><br>
            $content
";
}

echo rule('Gamemasters',
        'Any decision by the gamemasters is not subject to discussion. However, we will try to limit 
         the amount of decisions to a small number and will only intervene where absolute necessary.');

echo rule('Advisories',
        'Teams are allowed to submit advisories during the game on any issue that they find
         within the vulnerable box. Advisories have to be submitted by a webform and are 
         reviewed by the game\'s organisors.<br>
	 Advisories are <b>published</b> to be available to all teams a certain amount of time after 
	 their submission (ranging from <i>immediatly</i> to <i>about 2-3 hours later</i>).
	 The worse the quality of the advisory, the sooner will it be published.');

echo rule('Filtering',
        'Any kind of filtering that is not done in the applications themselves, or in a
         wrapper that is written during the game and handles only a single application, is considered against 
         the rules.<br>
         This specifically prohibts filtering based on IP addresses, other IP headers, TCP headers, ports, 
         and the like. We also
         prohibit any kind of filtering or behaviour that tries to distinct between the gameserver and
         other players - while it remains allowed to distinct between an attack and a regular request.');

echo rule('Scoring',
        'The total score of a team is calculated from three sub-categories
         <ul>'.
             rule('Ethical score/Advisories',
                  '<ul>'.
                  rule('Ethical behaviour',
                        'Each team is initally assign 10 <i>ethical scores</i>. 
                         Breaking the rules can be fined with deduction from this amount. Teams that accumulate
                         10 deducted points are excluded from the game - regardless of their actual amount of
                         ethical scores.').
                  rule('Advisories',
                       'Each advisory is scored 0 to 5 <i>ethical scores</i>, depending on its quality.
                        We try to assign scores for each vulnerablity only once, in a first come, first served
                        fashion.').
                  '</ul>').
             rule('Defensive Score',
                  'A flag is considered defended and gets scored with 1 point, iff
                   it was successfuly retrieved by the gameserver and 
                   it wasn\'t submitted by another team by the end of its expiry time.').
             rule('Offensive Score',
                  'A flag is considered caught and gets awarded with 1 point, iff
                  the submitting team has the same service actively running, of which the flag originates').
             rule('Total',
             'The total score is calculated as follows: for each of the three
              categories a team is assigned a value of relative scores to the team with the most scores in each 
              respective category. These two or three relative scores are then added and normalized, such that 
              the leading team has 100%.')
        .'</ul>'
      );

echo rule('Discouraged Behaviour I',
     'The following actions are discouraged and possibly fined with negative scores:
       <ul>
        <li>Automated scanning (ports, IPs, etc.) or usage of vulnerability scanners.
        <li>Attacks like Denial-of-Service, Distributed-Denial-of-Service or Bandwith Exhaustion.
        <li>Deployment of network-layer or OS-wide techniques that
          <ul>
            <li>try to destinct between gameserver and players
            <li>limit the effect of attacks, like e.g. overflows or injections
          </ul>
        <li>Any attacks or changes on any host that are directed against routing.
        <li>Destructive behaviour (e.g. deleting vital system files).
        <li>Intentionally supporting other teams.
	<li>In the IRC-channel: Swearing, flooding, and similar.
        <li><i>This list is not complete.</i>
       </ul>');

echo rule('Discouraged Behaviour II',
     "The following is discouraged and is possibly fined with negative scores and/or immediate dispension from the game:
      <ul>
        <li>Attacking the game server or any other host of the organisors.
        <li>Attacking systems outside the VPN. All traffic has to happen within the VPN.
        <li>Relaying data through other team's networks into the Internet.
        <li>Cheating on the team's size leads to immediate disqualification.
        <li><i>This list is not complete.</i>
      </ul>");

echo '
</ul></p>

<p>&nbsp;</p>';
myfooter();
?>
