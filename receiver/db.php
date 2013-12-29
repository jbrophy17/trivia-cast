<?php
require_once("backend_constants.php");

define("DB_TABLE", "prompts");

$valid_commands = array("get", "put", "approve");
$response = array();
$type = $_GET['type'];

if(!in_array($type, $valid_commands)){
	$repsonse['type'] = 'error';
	$response['message'] = 'Invalid command (not "get" or "put").';
	die(json_encode($response));
}

// valid command; connect to DB
$db = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
if($db->connect_errno){
	$response['type'] = 'error';
	$response['message'] = 'Failed to connect to database: ' . $db->connect_error;
	die(json_encode($response));
}

// add a new prompt to database
if($type == 'put'){
	$text = trim(htmlentities($db->real_escape_string($_POST['text'])));
	$author = trim(htmlentities($db->real_escape_string($_POST['author'])));
	$auth_key = md5(time() . $text);

	if(!strlen($author) || strlen($author) > 255){
		$author = 'Anonymous';
	}

	if(strlen($text) > 255){
		$response['type'] = 'error';
		$response['message'] = 'That prompt is too long. (Max length: 255)';
		die(json_encode($response));
	}

	// check for dupes
	//$dupe_query = "SELECT `ID` FROM `" . DB_TABLE . "` WHERE LOWER(`text`) = LOWER('$text');";

	$query = "INSERT INTO `" . DB_TABLE . "` (`text`, `author`, `time`, `ip`, `auth_key`) VALUES ('$text', '$author', " . time() . ", '" . $_SERVER['REMOTE_ADDR'] . "', '$auth_key');";

	if($db->query($query) === TRUE){
		$email_body = "Good news! A new TriviaCast prompt was added by $author from {$_SERVER['REMOTE_ADDR']} (" . gethostbyaddr($_SERVER['REMOTE_ADDR']) . ").\n\n\"$text\"\n\n";
		$email_body .= "Approve this prompt by clicking this link: http://trivia-cast.com/db.php?type=approve&auth=" . $auth_key;

		$approvers = array("jefftheman45@gmail.com", "brophs@gmail.com");
		foreach($approvers as $email){
			mail($email, "New TriviaCast Prompt Added", $email_body);
		}

		$response['type'] = 'success';
		$response['message'] = 'Your prompt was successfully added to TriviaCast.';
		die(json_encode($response));
	}
	else{
		$response['type'] = 'error';
		$response['message'] = 'A database error occurred: ' . $db->error;
		die(json_encode($response));
	}
}

// get an random-ordered array of prompts from database
else if($type == 'get'){
	$limit = 0;
	if(isset($_GET['limit'])){
		$limit = intval($_GET['limit']);
	}

	$limitString = '';
	if(isset($_GET['notID'])){
		$limitString = " AND `ID` != " . $db->real_escape_string($_GET['notID']);
	}

	$query = "SELECT `ID`, `text`, `author` FROM `" . DB_TABLE . "` WHERE `auth_key` = ''$limitString;";

	if($result = $db->query($query)){
		$responses = array();

		while($row = $result->fetch_assoc()){
			$responses[] = $row;
		}

		shuffle($responses);

		if($limit > 0){
			$responses = array_slice($responses, 0, $limit);
		}

		$response['type'] = 'success';
		$response['responses'] = $responses;

		die(json_encode($response));
	}
	else{
		$response['type'] = 'error';
		$response['message'] = 'A database error occurred: ' . $db->error;
		die(json_encode($response));
	}
}

else if($type == 'approve'){
	$auth_key = $db->real_escape_string($_GET['auth']);
	$query = "UPDATE `" . DB_TABLE . "` SET `auth_key` = '' WHERE `auth_key` = '$auth_key' LIMIT 1;";

	if($result = $db->query($query)){
	?><!doctype html>
<html>
<head>
	<title>TriviaCast Admin</title>
</head>
<body>
<?php

		if($db->affected_rows > 0){
			echo '<h1>Prompt approved.</h1>';
		}
		else{
			echo '<h1>Invalid request or already approved.</h1>';
		}
	?>
</body>
</html><?php
	}
	else{
		die("Database error: " . $db->error);
	}
}

else{
	// should never happen...
	$response['type'] = 'error';
	$response['message'] = 'Invalid command and initial check failed.';
	die(json_encode($response));
}
