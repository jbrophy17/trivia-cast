<?php
Header("Content-type: application/javascript");
define('filename', "newList.txt");

if(file_exists(filename)){
	$fileOfThings = file_get_contents(filename);
	$things = explode("\n", $fileOfThings);

	echo 'promptList = new String[' . sizeof($things) . ']' . "\n";

	$loopcount = 0;
	foreach($things as $thing){
		if(strlen($thing)){
			echo 'promptList.add("' . trim($thing) . '");' . "\n";
		}
		$loopcount++;
	}
}
else{
	echo 'Couldn\'t find prompts file.' . "\n";
}