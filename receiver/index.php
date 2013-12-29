<!doctype html>
<html>
<head>
	<link type="text/css" rel="stylesheet" href="marketing.css">
	<title>TriviaCast: A Game for Friends</title>
</head>
<body>
	<div id="top">
		<h1 id="prompt"></h1>
		<form id="submitPrompt">
			<input type="text" name="promptSubmission" id="promptSubmission" placeholder="Submit a prompt..." size="40">
			<input type="submit" value="Add">
		</form>
		<h2 id="formlink"><a href="#" onclick="showAddPrompt();">submit a prompt &raquo;</a></h2>
	</div>
	<div id="content">
		<h2>TriviaCast is a game for friends.</h2>
		<p>It's played on iOS and Android devices combined with the awesome Google Chromecast. It can be played with three people,
			but it gets better with more.</p>
		<p>Basically, a prompt appears on the TV screen and everyone responds to it with their phone or tablet. Once everyone's
			submitted something, you take turns trying to guess who said what, for points. And
			<a href="#" onclick="showAddPrompt();">the prompts are crowdsourced</a>!</p>

		<h2>How it Works</h2>
		<p>One person should have a Chromecast and a TV. Everyone gets on that person's wifi and behaves while connected. Everyone
			installs and opens the TriviaCast app on their phone or tablet &mdash; and you're ready to play!</p>

		<h2>Want More?</h2>
		<p>Detailed information and game rules are available on TriviaCast's <a href="https://github.com/jbrophy17/trivia-cast/">Github repository</a>.</p>
	</div>

	<script src="http://code.jquery.com/jquery-2.0.3.min.js"></script>
	<script type="text/javascript">
	currentPrompt = '';
	currentPromptID = -1;
	updater = null;
	adding = false;

	function fetchNew(){
		var newPrompt = $.get("db.php", { "type" : "get", "limit" : 1, "notID" : currentPromptID }, function(data){
			data = $.parseJSON(data);
			if(data.type == "success"){
				currentPrompt = data.responses[0].text;
				currentPromptID = data.responses[0].ID;
				$('#prompt').fadeOut();
				startShowCountdown();
			}
			else{
				console.error("Received API error: " + data);
			}
			});
	}

	function startShowCountdown(){
		setTimeout(function(){ if(!adding) { $('#prompt').html(currentPrompt).fadeIn(); } }, 1000);
	}

	function showAddPrompt(){
		clearInterval(updater);
		adding = true;
		$('#prompt').hide();
		$('#formlink').fadeOut();
		$('#submitPrompt').fadeIn();
		return false;
	}

	function addPrompt(){
		var newPrompt = $('#promptSubmission').val();
		if(newPrompt.length > 0 || newPrompt == "Submit a prompt..."){
			$.post("db.php?type=put", { "text" : newPrompt, "author" : "" }, function(response){
				console.debug(response);
				response = $.parseJSON(response);

				if(response.type == "success"){
					$('#submitPrompt').fadeOut();
					setTimeout(function(){ $('#prompt').html("Thanks for your submission!").fadeIn(); $('#promptSubmission').val(''); adding = false; setTimeout(init, 1500);}, 500);
				}
				else{
					console.error("Received API error: " + data);
				}
			});
		}
		else{
			$('#promptSubmission').css('background', '#EDE17C');
		}

		return false;
	}

	function init(){
		// set update interval to 10 seconds.
		fetchNew();
		updater = setInterval(fetchNew, 10000);
	}

	$(function(){
		init();
	});

	$('#top').hover(function(){
		if(!adding){
			$('#formlink').fadeIn('fast');
		}
	}, function(){
		$('#formlink').fadeOut('slow');
	});

	$('#submitPrompt').submit(function(e){
		e.preventDefault();
		addPrompt();
	});
	</script>
	<?php include "tracking.php"; ?>
</body>
</html>