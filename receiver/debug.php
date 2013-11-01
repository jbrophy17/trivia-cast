<?php
$msg = $_POST['msg'];

$log = "\n\n======\n\nReceived POST at " . date('g:i a n/j/y') . " from " . $_SERVER['REMOTE_ADDR'] . "\n\n" . $msg;

file_put_contents("log.txt", $log, FILE_APPEND);