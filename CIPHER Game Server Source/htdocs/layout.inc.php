<?php

$time_start = microtime (true);

function myhead ($title, $refresh = -1) {
  echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">
<html>
<head>  
  <title>$title</title>";
if ($refresh > 0) echo "<META HTTP-EQUIV='Refresh' CONTENT='$refresh'>\n  ";
echo "  <link rel='stylesheet' media='screen' href='/style.css'>
</head>
<body>

<h1>$title</h1>";
}

function myfooter() {
  global $time_start;
  $time_end = microtime(true);
  echo "<hr>
  <table border=0 width='100%'>
  <tr>
  	<td align=left>
		  Rendered in ".sprintf("%.5f",$time_end - $time_start)." seconds.
	</td>
	<td align=right>
	        The official time is: ".strftime('%a, %d.%m.%y %H:%M:%S')."
	</td>
  </table>
  </body>
  </html>";
}
  
?>
