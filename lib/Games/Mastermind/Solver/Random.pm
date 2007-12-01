#!/usr/bin/env perl
package Games::Mastermind::Solver::Random;
use Moose;
extends 'Games::Mastermind::Solver';

sub make_guess {
    my $self = shift;
    join '', map { $self->random_peg } 1 .. $self->holes;
}

1;

