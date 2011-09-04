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
#     $bar += 32;
#     do_stuff ( );
#   }
#
has DEBUG => ( is => 'rw', isa => 'Int', default => 0 );
has settings => ( is => 'rw', isa => 'HashRef', default => sub { {
  operator => {
    '+' => { pre => ' ', post => ' ', unary => '' },
    '-' => { pre => ' ', post => ' ', unary => '' },

    '++' => { pre => '', post => '' }, '--' => { pre => '', post => '' },
    '!' => '', '~' => '',

    ',' => { pre => '', post => ' ' },
    '=>' => { pre => ' ', post => ' ' },
    '->' => { pre => '', post => '' },

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
    '//' => { pre => ' ', post => ' ' },
    'or' => { pre => ' ', post => ' ' },
    'dor' => { pre => ' ', post => ' ' },
    '^' => { pre => ' ', post => ' ' },
    '+=' => { pre => ' ', post => ' ' }, '-=' => { pre => ' ', post => ' ' },
    '*=' => { pre => ' ', post => ' ' }, '/=' => { pre => ' ', post => ' ' },
    '.=' => { pre => ' ', post => ' ' }, '//=' => { pre => ' ', post => ' ' },
    '*' => { pre => ' ', post => ' ' },
    '/' => { pre => ' ', post => ' ' },
    '%' => { pre => ' ', post => ' ' },
    '<<' => { pre => ' ', post => ' ' },
    '>>' => { pre => ' ', post => ' ' },
  },
  statement => { pre => '', post => "\n" },
  indent => '    ',
  #
  # The last statement of a function doesn't get a newline.
  #
  subroutine => {
    open => { pre => "\n  ", post => "\n" },
    close => { pre => "\n  ", post => "\n  " }
  }
} } );

has ppi => ( is => 'rw', isa => 'Object' );

=head1 NAME

JGoff::App::Perltidy - The great new JGoff::App::Perltidy!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

# {{{ _remove_whitespace_before( node => $node )

sub _remove_whitespace_before {
  my $self = shift;
  my %args = @_;
  croak "*** Internal error - No node passed in" unless
    $args{node};

  while ( $args{node}->previous_sibling and
          $args{node}->previous_sibling->isa('PPI::Token::Whitespace') ) {
    $args{node}->previous_sibling->remove;
  }
}

# }}}

# {{{ _remove_whitespace_after( node => $node )

sub _remove_whitespace_after {
  my $self = shift;
  my %args = @_;
  croak "*** Internal error - No node passed in" unless
    $args{node};

  while ( $args{node}->next_sibling and
          $args{node}->next_sibling->isa('PPI::Token::Whitespace') ) {
    $args{node}->next_sibling->remove;
  }
}

# }}}

# {{{ _remove_whitespace_around( node => $node )

sub _remove_whitespace_around {
  my $self = shift;
  my %args = @_;
  croak "*** Internal error - No node passed in" unless
    $args{node};

  $self->_remove_whitespace_before( node => $args{node} );
  $self->_remove_whitespace_after( node => $args{node} );
}

# }}}

# {{{ _canon_whitespace_before( node => $node [, whitespace => ' ' ] )

sub _canon_whitespace_before {
  my $self = shift;
  my %args = @_;
  croak "*** Internal error - No node passed in" unless
    $args{node};

  delete $args{whitespace} if $args{whitespace} and $args{whitespace} eq q{};

  return unless $args{node}->previous_sibling;

  $self->_remove_whitespace_before( node => $args{node} );
  if ( $args{whitespace} ) {
    my $whitespace = PPI::Token::Whitespace->new;
    $whitespace->set_content( $args{whitespace} );
    $args{node}->insert_before( $whitespace ) or
      croak "*** Could not insert whitespace!";
  }
}

# }}}

# {{{ _canon_whitespace_after( node => $node [, whitespace => ' ' ] )

sub _canon_whitespace_after {
  my $self = shift;
  my %args = @_;
  croak "*** Internal error - No node passed in" unless
    $args{node};

  delete $args{whitespace} if $args{whitespace} and $args{whitespace} eq q{};

  return unless $args{node}->next_sibling;

  $self->_remove_whitespace_after( %args );
  if ( $args{whitespace} ) {
    my $whitespace = PPI::Token::Whitespace->new;
    $whitespace->set_content( $args{whitespace} );
    $args{node}->next_sibling->insert_before( $whitespace ) or
      croak "*** Could not insert whitespace!";
  }
}

# }}}

# {{{ _binary_operator( node => $node )

sub _binary_operator {
  my $self = shift;
  my %args = @_;
  croak "*** No node specified!" unless
    exists $args{'node'};

  my $operator = $args{node}->content;
  my $setting = $self->settings->{'operator'}->{$operator};

  croak "*** No '$operator' operator settings specified!" unless
    defined $setting;
  $self->_canon_whitespace_before(
    node => $args{node},
    whitespace => $setting->{'pre'}
  );
  $self->_canon_whitespace_after(
    node => $args{node},
    whitespace => $setting->{'post'}
  );
}

# }}}

# {{{ _unary_operator( node => $node )

sub _unary_operator {
  my $self = shift;
  my %args = @_;
  croak "*** No node specified!" unless
    exists $args{'node'};

  my $operator = $args{node}->content;
  my $setting = $self->settings->{'operator'}->{$operator};

  croak "*** No '$operator' operator settings specified!" unless
    $setting;
  $self->_canon_whitespace_before( node => $args{node}, pre => $setting );
  $self->_canon_whitespace_after( node => $args{node}, post => $setting );
}

# }}}

# {{{ _ppi_token_operator( node => $node )

sub _ppi_token_operator {
  my $self = shift;
  my %args = @_;
  croak "*** No node specified!" unless
    exists $args{node};

  my %action = (
    '++' => 'unary',  '--' => 'unary',
    '!' => 'unary', '~' => 'unary', 'not' => 'unary',
    '<>' => 'unary',
  );
  my $operator = $args{node}->content;
  if ( $operator eq '+' or
       $operator eq '-' ) {
    if ( $args{node}->previous_sibling ) {
      $self->_binary_operator( node => $args{node} );
    }
    else {
      $self->_canon_whitespace_after(
        node => $args{node},
        whitespace => $self->settings->{$operator}->{unary}
      );
    }
  }
  elsif ( exists $action{$operator} and
          $action{$operator} eq 'unary' ) {
    $self->_unary_operator( node => $args{node} );
  }
  else {
    $self->_binary_operator( node => $args{node} );
  }
}

# }}}

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use JGoff::App::Perltidy;

    my $perltidy = JGoff::App::Perltidy->new;
    print $perltidy->reformat( text => '$x++ - 5 < 32; map { $_+1 } @foo' );

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

  if ( my $node_list = $self->ppi->find('PPI::Token::Operator') ) {
    for my $node ( @$node_list ) {
      $self->_ppi_token_operator( node => $node );
    }
  }
  if ( my $node_list = $self->ppi->find('PPI::Statement') ) {
    for my $node ( @$node_list ) {
      $self->_remove_whitespace_around( node => $node );
    }
    for my $node ( @$node_list ) {
      next unless $node->next_sibling;

      my $whitespace = PPI::Token::Whitespace->new;
      $whitespace->set_content( $self->settings->{statement}{post} );
      $node->insert_after( $whitespace );
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
