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
        print "Guessing $guess. How many black and white pegs? ";
        local $_ = <>;
        return /(\d+)\D+(\d+)/;
    }},
);

# repeatedly prompt the user until we get realistic input
sub play {
    my $self  = shift;
    my $guess = shift;
    my ($black, $white);

    do {
        do {
            ($black, $white) = $self->get_result->($guess);
        }
        until defined $black && defined $white;
    }
    until $black + $white <= $self->holes;

    return ($black, $white);
}

# go from zero to solution
sub solve {
    my $self = shift;

    while (1) {
        my $guess = $self->make_guess;

        # no solution found
        return undef if !defined($guess);

        my ($black, $white) = $self->play($guess);

        return $guess
            if $black == $self->holes;

        push @{ $self->history }, [$guess, $black, $white];

        $self->result_of($guess, $black, $white);
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

    my $last = $self->history->[-1];

    return undef if !defined($last);
    return $last->[0];
}

sub random_peg {
    my $self = shift;

    return $self->pegs->[rand @{$self->pegs}];
}

sub all_codes {
    my $self = shift;

    my $possibilities = {};

    my @pegs  = @{ $self->pegs };
    my $holes = $self->holes;

    # generate all holes-length permutations of @pegs recursively
    my $generate;
    $generate = sub {
        my $p = shift;
        my $len = 1 + shift;

        if ($len == $holes) {
            $possibilities{$p . $_} = 1 for @pegs;
        }
        else {
            $recurse->($p . $_, $len) for @pegs;
        }
    };

    $recurse->('', 0);

    return $possibilities;
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
provide the answers to how many black pegs and how many white pegs a code
gives.

You must instantiate a subclass of this module to actually break codes. There
are a number of different solver modules, described in L</ALGORITHMS>.

L<Games::Mastermind> is the same game, except it plays the role of code maker.

=head1 ALGORITHMS

Here are the algorithms, in roughly increasing order of quality.

=head2 L<Games::Mastermind::Solver::Random>

This randomly guesses until it gets the right answer. It does not attempt to
avoid guessing the same code twice.

=head2 L<Games::Mastermind::Solver::Sequential>

This guesses each code in order until it gets the right answer. It uses no
information from the results to prepare its next guesses.

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
C<black pegs> and C<white pegs>, as return value. I will call this method
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
Each item in C<history> is an array refrence itself, containing the guess, its
black pegs, and its white pegs.

=head1 SUBCLASSING

This module uses L<Moose> so please use it to extend this module. C<:)>

Your solver should operate such that any update to its internal state is caused
by C<result_of>, not C<make_guess>. This is because your C<result_of> method
may be called (multiple times) before C<make_guess> is first called.

If you absolutely have to entangle your guessing and result processing code,
one way to make this work is to have C<result_of> do all the calculation and
store the next guess to make in an attribute.

=head2 REQUIRED METHODS

=head3 make_guess

This method will receive no arguments, and expects a string representing the
guessed code as a result. If your C<make_guess> returns C<undef>, that will be
interpreted as "unable to solve this code."

=head2 OPTIONAL METHODS

=head3 result_of

This method will receive three arguments: the guess made, the number of black
pegs, and the number of white pegs. It doesn't have to return anything.

=head2 HELPER METHODS

=head3 last_guess

This returns the last code guessed, or C<undef> if no code has been guessed
yet.

=head3 random_peg

This returns a peg randomly selected from valid pegs.

=head3 all_codes

This returns a hash reference of all possible codes. This is not cached in any
way, so each call is a large speed penalty.

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

