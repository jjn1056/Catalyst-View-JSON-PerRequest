use Test::Most;

{
  package MyApp::Model::Fatal;

  use Moo;
  extends 'Catalyst::Model';

  sub TO_JSON {
    die "HUGE FATAL ERROR OF SOME KIND";
  }

  sub ACCEPT_CONTEXT {
    my ($self, $c, @args) = @_;
    return ref($self)->new(@args);
  }

  $INC{'MyApp/Model/Fatal.pm'} = __FILE__;


  # ----------
  package MyApp::View::JSON;

  use Moo;
  extends 'Catalyst::View::JSON::PerRequest';


  # ----------
  package MyApp::Controller::Root;
  use base 'Catalyst::Controller';

  $INC{'MyApp/View/JSON.pm'} = __FILE__;

  sub custom :Local Args(0) {
    my ($self, $c) = @_;
    $c->view->data('Fatal');
    $c->view->ok();
  }

  $INC{'MyApp/Controller/Root.pm'} = __FILE__;


  # ----------
  package MyApp;
  
  use Catalyst;

  MyApp->config(
    default_view =>'JSON',
    'Controller::Root' => { namespace => '' },
    'View::JSON' => {
      handle_encode_error => \&Catalyst::View::JSON::PerRequest::HANDLE_ENCODE_ERROR,
    },
  );

  MyApp->setup;
}

use Catalyst::Test 'MyApp';
use JSON::MaybeXS;

{
  ok my ($res, $c) = ctx_request( '/custom' ), "Request";
  is $res->code, 500, "HTTP response code";
  my %json = %{ decode_json $res->content };
  like($json{error}, qr/HUGE FATAL ERROR OF SOME KIND/, "Returned the fatal error in the JSON payload");
}

done_testing;
