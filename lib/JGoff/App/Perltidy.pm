package JGoff::App::Perltidy;

use PPI;
use Carp qw( croak );
use Moose;

#
# Defaults to Whitesmith
#
# $x = 0;
# sub foo
#   {
#     $bar++;
#     do_stuff();
#   }
#
has settings => ( is => 'rw', isa => 'HashRef', default => sub { {
  operator => {
    '<' => { pre => ' ', post => ' ' }, 'lt' => { pre => ' ', post => ' ' },
    '<=' => { pre => ' ', post => ' ' }, 'le' => { pre => ' ', post => ' ' },
    '>' => { pre => ' ', post => ' ' }, 'gt' => { pre => ' ', post => ' ' },
    '>=' => { pre => ' ', post => ' ' }, 'ge' => { pre => ' ', post => ' ' },
    '==' => { pre => ' ', post => ' ' }, 'eq' => { pre => ' ', post => ' ' },
    '!=' => { pre => ' ', post => ' ' }, 'ne' => { pre => ' ', post => ' ' },
    '&' => { pre => ' ', post => ' ' },
    '&&' => { pre => ' ', post => ' ' },
    'and' => { pre => ' ', post => ' ' },
    '|' => { pre => ' ', post => ' ' },
    '||' => { pre => ' ', post => ' ' },
    'or' => { pre => ' ', post => ' ' },
    'dor' => { pre => ' ', post => ' ' },
    '^' => { pre => ' ', post => ' ' },
    '+=' => { pre => ' ', post => ' ' },
    '-=' => { pre => ' ', post => ' ' },
    '*=' => { pre => ' ', post => ' ' },
    '/=' => { pre => ' ', post => ' ' },
    '*' => { pre => ' ', post => ' ' },
    '/' => { pre => ' ', post => ' ' },
    '%' => { pre => ' ', post => ' ' },
  },
  indent => '    ',
  #
  # The last statement of a function doesn't get a newline.
  #
  subroutine => {
    pre_open => "\n  ",
    post_open => "\n",
    pre_close => "\n  ",
    post_close => "\n  "
  }
} } );

has ppi => ( is => 'rw', isa => 'Object' );

=head1 NAME

JGoff::App::Perltidy - The great new JGoff::App::Perltidy!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

# {{{ _canon_whitespace_before( node => $node [, pre => ' ' ] )

sub _canon_whitespace_before {
  my $self = shift;
  my %args = @_;
  croak "*** Internal error - No node passed in" unless
    $args{node};

  delete $args{pre} if $args{pre} and $args{pre} eq q{};

  return unless $args{node}->previous_sibling;

  while ( $args{node}->previous_sibling->isa('PPI::Token::Whitespace') ) {
    $args{node}->previous_sibling->remove;
  }
  my $whitespace = PPI::Token::Whitespace->new;
  $whitespace->set_content( $args{pre} );
  $args{node}->previous_sibling->insert_after( $whitespace ) or
    croak "*** Could not insert whitespace!";
}

# }}}

# {{{ _canon_whitespace_after( node => $node [, post => ' ' ] )

sub _canon_whitespace_after {
  my $self = shift;
  my %args = @_;
  croak "*** Internal error - No node passed in" unless
    $args{node};

  delete $args{post} if $args{post} and $args{post} eq q{};

  return unless $args{node}->next_sibling;

  while ( $args{node}->next_sibling->isa('PPI::Token::Whitespace') ) {
    $args{node}->next_sibling->remove;
  }
  my $whitespace = PPI::Token::Whitespace->new;
  $whitespace->set_content( $args{post} );
  $args{node}->next_sibling->insert_before( $whitespace ) or
    croak "*** Could not insert whitespace!";
}

# }}}

# {{{ _binop( node => $node )

sub _binop {
  my $self = shift;
  my %args = @_;
  croak "*** No node specified!" unless
    exists $args{'node'};

  my $content = $args{node}->content;
  my $setting = $self->settings->{'operator'}->{$content};

  croak "*** No '$content' operator settings specified!" unless
    $setting;
  $self->_canon_whitespace_before(
    node => $args{node}, pre => $setting->{'pre'} );
  $self->_canon_whitespace_after(
    node => $args{node}, post => $setting->{'post'} );
}

# }}}

# {{{ _operator( node => $node )

sub _operator {
  my $self = shift;
  my %args = @_;
  croak "*** No node specified!" unless
    exists $args{node};

# # This is the list of valid operators
# ++   --   **   !    ~    +    -
# =~   !~   x
# <<   >>   cmp  ~~
# <=>  .    ..   ...  ,
# //
# ?    :    =    .=   //=
# <>   =>   ->
# not

# # This is the list of valid operators
# ++   --   **   !    ~    +    -
# =~   !~   *    /    %    x
# <<   >>   lt   gt   le   ge   cmp  ~~
# ==   !=   <=>  .    ..   ...  ,
# &    |    ^    &&   ||   //
# ?    :    =    +=   -=   *=   .=   //=
# <    >    <=   >=   <>   =>   ->
# and  or   dor  not  eq   ne

  my %binop = (
    '>' => 1, '>=' => 1, 'gt' => 1, 'ge' => 1,
    '<' => 1, '<=' => 1, 'lt' => 1, 'le' => 1,
    '==' => 1, '!=' => 1, 'eq' => 1, 'ne' => 1,
    '&' => 1, '&&' => 1, 'and' => 1,
    '|' => 1, '||' => 1, 'or' => 1, 'dor' => 1,
    '^' => 1,
    '+=' => 1, '-=' => 1, '*=' => 1, '/=' => 1,
    '*' => 1, '/' => 1, '%' => 1,
  );
  my %action = ();
  $action{$_} = 'binop' for keys %binop;

  my $content = $args{node}->content;

  croak "*** Unknown operator type '$action{$content}'!" unless
    exists $action{$content};
  if ( $action{$content} eq 'binop' ) {
    $self->_binop( node => $args{node} );
  }
  elsif ( $action{$content} eq 'unop' ) {
    $self->_unop( node => $args{node} );
  }
}

# }}}

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use JGoff::App::Perltidy;

    my $foo = JGoff::App::Perltidy->new();
    ...

=head1 METHODS

=head2 reformat( text => $code )

=cut

# {{{ reformat( text => $code )

sub reformat {
  my $self = shift;
  my %args = @_;
  croak "*** No text specified!" unless
    exists $args{text};

  $self->ppi( PPI::Document->new( \$args{text} ) );

  my $node_list = $self->ppi->find('PPI::Token::Operator');
  if ( $node_list and @$node_list ) {
    for my $node ( @$node_list ) {
      $self->_operator( node => $node, DUMP => ( $args{DUMP} || 0 ) );
    }
  }

  return $self->ppi->content;
}

# }}}

=head1 AUTHOR

Jeffrey Goff, C<< <jgoff at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-jgoff-app-perltidy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JGoff-App-Perltidy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JGoff::App::Perltidy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JGoff-App-Perltidy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JGoff-App-Perltidy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JGoff-App-Perltidy>

=item * Search CPAN

L<http://search.cpan.org/dist/JGoff-App-Perltidy/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jeffrey Goff.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of JGoff::App::Perltidy
