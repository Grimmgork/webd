use strict;
use HTTP::Daemon;
use HTTP::Status;
use HTTP::Status qw(:constants);

$SIG{PIPE} = 'IGNORE'; # prevent perl from quitting if trying to write to a closed socket ???

my $d = HTTP::Daemon->new(
	LocalPort => 5050,
	ReuseAddr => 1,
	Timeout => 1
) || die;

while(1){
	my $c = $d->accept || next;
	my $req = $c->get_request;
	unless(defined $req){
		$c->close;
		undef($c);
		next;
     }
	print $req->method, " ", $req->uri->path, "\n";
	$c->force_last_request;
	my $pid = fork();
	die if not defined $pid;
	if(not $pid){ # child process -> $pid = 0
		my $res;
		eval{ $res = get_response($req) };
		if($@){
			print "ERROR: $@\n";
			$res = status_message_res(500);
		}
		$c->send_response($res);
		$c->close;
		undef($c);
		exit;
	}
}

sub get_response{
	my $req = shift;

	if($req->method eq "GET" and $req->uri->path =~ m/^\/hello$/){
		return HTTP::Response->new(200, undef, ["content-type" => "text/plain"], "hello world!");
	}

	return status_message_res(404);
}

sub status_message_res{
	my $code = shift;
	my $message = status_message($code);
	return HTTP::Response->new($code, undef, ["content-type" => "text/plain"], "$code - $message");
}