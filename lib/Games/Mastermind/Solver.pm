#!perl
package Games::Mastermind::Solver;
use Moose;

has holes => (
    is      => 'ro',
    isa     => 'Int',
    default => 4,
);

has pegs => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [qw/K B G R Y W/] },
);

has history => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has get_result => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub { sub {
        my $guess = shift;
        print "Guessing $guess. How many white and black pegs? ";
        local $_ = <>;
        return /(\d+)\D+(\d+)/;
    }},
);

# repeatedly prompt the user until we get realistic input
sub play {
    my $self  = shift;
    my $guess = shift;
    my ($white, $black);

    do {
        do {
            ($white, $black) = $self->get_result->($guess);
        }
        until defined $white && defined $black;
    }
    until $white + $black <= $self->holes;

    return ($white, $black);
}

# go from zero to solution
sub solve {
    my $self = shift;

    while (1) {
        my $guess = $self->make_guess;

        # no solution found
        return undef if !defined($guess);

        push @{ $self->history }, $guess;

        my ($white, $black) = $self->play($guess);

        return $guess
            if $white == $self->holes;

        $self->result_of($guess, $white, $black);
    }
}

# don't let the user instantiate this directly
around new => sub {
    my $orig  = shift;
    my $class = shift;
    $class = blessed($class) || $class;

    if ($class eq 'Games::Mastermind::Solver') {
        confess "You must choose a subclass of Games::Mastermind::Solver. I recommend Games::Mastermind::Solver::Sequential.";
    }

    $orig->($class, @_);
};

# callback to let the solver module know how he did
sub result_of { }

# the meat of the solver modules
sub make_guess {
    confess "Your subclass must override make_guess.";
}

# auxiliary methods

sub last_guess {
    my $self = shift;

    $self->history->[-1];
}

sub random_peg {
    my $self = shift;

    return $self->pegs->[rand @{$self->pegs}];
}

=head1 NAME

Games::Mastermind::Solver - quickly solve Mastermind

=head1 VERSION

Version 0.01 released ???

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Games::Mastermind::Solver::Sequential;
    my $solver = Games::Mastermind::Solver::Sequential->new();
    printf "The solution is %s!\n", $solver->solve;

=head1 DESCRIPTION

Mastermind is a code-breaking game played by two players, the "code maker" and
the "code breaker".

This module plays the role of code breaker. The only requirement is that you
provide the answers to how many white pegs and how many black pegs a code
gives.

You must instantiate a subclass of this module to actually break codes. There
are a number of different solver modules, described in L</ALGORITHMS>.

L<Games::Mastermind> is the same game, except it plays the role of code maker.

=head1 ALGORITHMS

=over 4

=item L<Games::Mastermind::Solver::Random>

This randomly guesses until it gets the right answer. It does not attempt to
avoid guessing the same code twice.

=item L<Games::Mastermind::Solver::Sequential>

This guesses each code in order until it gets the right answer. It uses no
information from the results to prepare its next guesses.

=back

=head1 USAGE

=head2 C<new>

Creates a new L<Games::Mastermind::Solver::*> object. Note that you MUST
instantiate a subclass of this module. C<new> takes a number of arguments:

=head3 C<holes>

The number of holes. Default: 4.

=head3 C<pegs>

The representations of the pegs. Default: 'K', 'B', 'G', 'R', 'Y', 'W'.

=head3 C<get_result>

A coderef to call any time the module wants user input. It passes the coderef
the string of the guess (e.g. C<KRBK>) and expects to receive two numbers,
C<white pegs> and C<black pegs>, as return value. I will call this method
multiple times if necessary to get sane output, so you don't need to do much
processing.

The default queries the user through standard output and standard input.

=head2 C<solve>

The method to call to solve a particular game of Mastermind. This takes no
arguments. It returns the solution as a string, or C<undef> if no solution
could be found.

=head2 C<holes>

This will return the number of holes used in the game.

=head2 C<pegs>

This will return an array reference of the pegs used in the game.

=head2 C<history>

This will return an array reference of the guesses made so far in the game.

=head1 SUBCLASSING

This module uses L<Moose> so please use it to extend this module. C<:)>

=head2 REQUIRED METHODS

=head3 make_guess

This method will receive no arguments, and expects a string representing the
guessed code as a result. If your C<make_guess> returns C<undef>, that will be
interpreted as "unable to solve this code."

=head2 OPTIONAL METHODS

=head3 result_of

This method will receive three arguments: the guess made, the number of white
pegs, and the number of black pegs. It doesn't have to return anything.

=head2 HELPER METHODS

=head3 last_guess

This returns the last code guessed, or C<undef> if no code has been guessed
yet.

=head3 random_peg

This returns a peg randomly selected from valid pegs.

=head1 SEE ALSO

L<Games::Mastermind>, L<http://sartak.katron.org/nh/mastermind>

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail.com> >>

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-games-mastermind-solver at rt.cpan.org>, or browse
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Mastermind-Solver>.

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Games::Mastermind::Solver

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Mastermind-Solver>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Mastermind-Solver>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Mastermind-Solver>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Mastermind-Solver>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

