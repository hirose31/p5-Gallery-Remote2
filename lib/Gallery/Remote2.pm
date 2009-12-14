package Gallery::Remote2;

use strict;
use warnings;
use Carp;

use LWP::UserAgent;
use HTTP::Request::Common;
$HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Deparse = 1;
sub p(@) {
    print STDERR Dumper(\@_);
}

our $VERSION = '0.01_01';

my $PROTOCOL_VERSION = 2.13;

my $GR_STAT_SUCCESS            = 0;
my $PROTO_MAJ_VER_INVAL        = 101;
my $PROTO_MIN_VER_INVAL        = 102;
my $PROTO_VER_FMT_INVAL        = 103;
my $PROTO_VER_MISSING          = 104;
my $PASSWD_WRONG               = 201;
my $LOGIN_MISSING              = 202;
my $UNKNOWN_CMD                = 301;
my $NO_ADD_PERMISSION          = 401;
my $NO_FILENAME                = 402;
my $UPLOAD_PHOTO_FAIL          = 403;
my $NO_WRITE_PERMISSION        = 404;
my $NO_VIEW_PERMISSION         = 405;
my $NO_CREATE_ALBUM_PERMISSION = 501;
my $CREATE_ALBUM_FAILED        = 502;
my $MOVE_ALBUM_FAILED          = 503;
my $ROTATE_IMAGE_FAILED        = 504;

sub new {
    my($class, %arg) = @_;

    my %prop;
    for (qw(url username password)) {
        $prop{$_} = delete $arg{$_} || "";
    }

    my $self = bless {
        %prop,
        _ua    => LWP::UserAgent->new,
        _login => undef,
       }, $class;

    $self->{_ua}->agent(__PACKAGE__.'/'.$VERSION);
    $self->{_ua}->cookie_jar({});


    return $self;
}

sub login {
    my($self) = @_;

    $self->{_login} = 0;
    my $res = $self->{_ua}->request(
        POST $self->{url},
        Content_Type => 'form-data',
        Content => [
            'g2_controller'             => 'remote:GalleryRemote',
            'g2_form[protocol_version]' => $PROTOCOL_VERSION,
            'g2_form[cmd]'              => "login",
            'g2_form[uname]'            => $self->{username},
            'g2_form[password]'         => $self->{password},
           ],
       );

    my($code, $gr2_res) = $self->_parse_response($res);

    if ($code != 200) {
        return 0;
    } else {
        if ($gr2_res->{status} == $GR_STAT_SUCCESS) {
            $self->{_login} = 1;
            return 1;
        } else {
            return 0;
        }
    }
}

sub fetch_albums       { croak 'still not implemented: ',(caller(0))[3]; }
sub fetch_albums_prune { croak 'still not implemented: ',(caller(0))[3]; }

sub add_item {
    my($self, %arg) = @_;

    if (! defined $self->{_login}) {
        $self->login or return 0;
    }

    for (qw(filepath album)) {
        if (! exists $arg{$_}) {
            carp "missing arg: $_";
            return 0;
        }
    }
    if (! exists $arg{filename}) {
        $arg{filename} = substr($arg{filepath},rindex($arg{filepath},"/")+1);
    }

    my $res = $self->{_ua}->request(
        POST $self->{url},
        Content_Type => 'form-data',
        Content => [
            'g2_controller'             => 'remote:GalleryRemote',
            'g2_form[protocol_version]' => $PROTOCOL_VERSION,
            'g2_form[cmd]'              => "add-item",
            'g2_form[set_albumName]'    => $arg{album},
            'g2_form[caption]'          => $arg{caption} || "",
            'g2_userfile'               => [ $arg{filepath} ],
            'g2_userfile_name'          => $arg{filename},
            'g2_authToken'              => "",
           ],
       );

    my($code, $gr2_res) = $self->_parse_response($res);

    if ($code != 200) {
        carp $gr2_res->{error};
        return 0;
    } else {
        if ($gr2_res->{status} == $GR_STAT_SUCCESS) {
            return 1;
        } else {
            carp Dumper($gr2_res); # fixme
            return 0;
        }
    }

}

sub album_properties     { croak 'still not implemented: ',(caller(0))[3]; }
sub new_album            { croak 'still not implemented: ',(caller(0))[3]; }
sub fetch_album_images   { croak 'still not implemented: ',(caller(0))[3]; }
sub move_album           { croak 'still not implemented: ',(caller(0))[3]; }
sub increment_view_count { croak 'still not implemented: ',(caller(0))[3]; }
sub image_properties     { croak 'still not implemented: ',(caller(0))[3]; }
sub no_op                { croak 'still not implemented: ',(caller(0))[3]; }

sub _parse_response {
    my($self, $res) = @_;
    my($code, $gr2_res);

    $code = $res->code;
    if ($res->is_error) {
        $gr2_res->{error} = $res->error_as_HTML;
    } else {
        my $content = $res->content;
        $content =~ s/^.*#__GR2PROTO__[\r\n]+//s;
        for (split /[\r\n]+/, $content) {
            my($k,$v) = split /=/, $_, 2;
            $gr2_res->{$k} = $v;
        }
    }

    return ($code, $gr2_res);
}


1;
__END__

=head1 NAME

Gallery::Remote2 - Perl extension for interacting with the Gallery remote protocol 2.

=head1 SYNOPSIS

  use Gallery::Remote2;
  
  my $gr2 = Gallery::Remote2->new(
      url      => 'http://example.com/gr2/main.php',
      username => 'scott',
      password => 'tiger',
     );
  my $r;
  
  $r = $gr2->login or die;
  
  $r = $gr2->add_item(
      filepath => "/path/to/uploadme.jpg",
      filename => "photo title",
      album    => "album_name",
     ) or die;

=head1 DESCRIPTION

Gallery::Remote2 is a perl module that allows remote access to a remote gallery.

Gallery::Remote2 supports only Gallery Remote protocol 2.

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 SEE ALSO

L<http://codex.gallery2.org/Gallery_Remote:Protocol>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
