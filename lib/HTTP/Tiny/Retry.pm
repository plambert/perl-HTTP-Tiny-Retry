package HTTP::Tiny::Retry;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use parent 'HTTP::Tiny';

sub request {
    my ($self, $method, $url, $options) = @_;

    $self->{retries} //= $ENV{HTTP_TINY_RETRIES} // 3;
    $self->{retry_delay} //= $ENV{HTTP_TINY_RETRY_DELAY} // 2;

    my $retries = 0;
    my $res;
    while (1) {
        my $res = $self->SUPER::request($method, $url, $options);
        return $res if $res->{status} !~ /\A[5]/;
        last if $retries >= $self->{retries};
        $retries++;
        log_trace "Failed requesting %s (%s - %s), retrying in %d second(s) (%d of %d) ...",
            $url,
            $res->{status},
            $res->{reason},
            $self->{retry_delay},
            $retries,
            $self->{retries};
        sleep $self->{retry_delay};
    }
    $res;
}

1;
# ABSTRACT: Retry failed HTTP::Tiny requests

=head1 SYNOPSIS

 use HTTP::Tiny::Retry;

 my $res  = HTTP::Tiny::Retry->new(
     # retries     => 4, # optional, default 3
     # retry_delay => 5, # optional, default is 2
     # ...
 )->get("http://www.example.com/");


=head1 DESCRIPTION

This class is a subclass of L<HTTP::Tiny> that retry fail responses (a.k.a.
responses with 5xx statuses; 4xx are considered the client's fault so we don't
retry those).


=head1 ENVIRONMENT

=head2 HTTP_TINY_RETRIES

Int. Used to set default for the L</retries> attribute.

=head2 HTTP_TINY_RETRY_DELAY

Int. Used to set default for the L</retry_delay> attribute.


=head1 SEE ALSO

L<HTTP::Tiny>

L<HTTP::Tiny::Patch::Retry>, patch version of this module.
