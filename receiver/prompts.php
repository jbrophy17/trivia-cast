<?php
Header("Content-type: application/javascript");
define('filename', "newList.txt");

if(file_exists(filename)){
	$fileOfThings = file_get_contents(filename);
	$things = explode("\n", $fileOfThings);

	echo 'prompts = new Array();' . "\n";
	foreach($things as $thing){
		$thing = trim($thing);
		if(strlen($thing)){
			echo 'prompts.push("' . $thing . '");' . "\n";
		}
	}

	echo 'console.log("Imported " + ' . sizeof($things) . ' + " prompts.");' . "\n";
}
else{
	echo 'console.error("Couldn\'t find prompts file.");' . "\n";
}