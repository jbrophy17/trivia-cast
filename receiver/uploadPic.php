<?php
function debugLog($msg){
	$msg = "Received FILES at " . date('g:i:s a n/j/y') . " from " . $_SERVER['REMOTE_ADDR'] . "\n\n" . $msg . "\n\n======\n\n";
	$old = file_get_contents("log.txt");
	file_put_contents("log.txt", $msg . $old);
}

// save an uploaded image and return a URL to it.

define('UPLOAD_BASE_URL', 'http://jeffastephens.com/trivia-cast/profile_pics/');

$output = array();
$output['type'] = 'uploadResult';

// no file
if(!isset($_FILES['file'])){
	$output['error'] = -1;
	$output['message'] = 'No file was uploaded.';
	debugLog(print_r($output, true));
	die(json_encode($output));
}

// error
if($_FILES['file']['error'] > 0){
	$output['error'] = $_FILES['file']['error'];
	debugLog(print_r($output, true));
	die(json_encode($output));
}

else{
	$filename = md5(time() . rand(1,100)) . ".jpg";
	
	$uploadDir = '/home6/colorap5/www/jeff/trivia-cast/profile_pics/';
	$uploadDestination = $uploadDir . $filename;

	if(move_uploaded_file($_FILES['file']['tmp_name'], $uploadDestination)){
		$output['filename'] = UPLOAD_BASE_URL . $filename;
	}
	else{
		$output['error'] = 9;
	}

	echo json_encode($output);
}

// debug logs
$msg = $_POST['msg'];

$log =  print_r($_FILES, true) . "\n\n" . print_r($output, true);
debugLog($log);
