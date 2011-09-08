package JGoff::App::Perltidy;

use PPI;
use Carp qw( croak );
use Moose;

# {{{ docs
=pod

PPI::Element
   PPI::Node
      PPI::Document
         PPI::Document::Fragment
      PPI::Statement
         PPI::Statement::Package
         PPI::Statement::Include
#        PPI::Statement::Sub
         PPI::Statement::Scheduled
         PPI::Statement::Compound
         PPI::Statement::Break
         PPI::Statement::Given
         PPI::Statement::When
         PPI::Statement::Data
         PPI::Statement::End
         PPI::Statement::Expression
            PPI::Statement::Variable
         PPI::Statement::Null
         PPI::Statement::UnmatchedBrace
         PPI::Statement::Unknown
      PPI::Structure
         PPI::Structure::Block
         PPI::Structure::Subscript
         PPI::Structure::Constructor
         PPI::Structure::Condition
         PPI::Structure::List
         PPI::Structure::For
         PPI::Structure::Given
         PPI::Structure::When
         PPI::Structure::Unknown
   PPI::Token
      PPI::Token::Whitespace
      PPI::Token::Comment
      PPI::Token::Pod
      PPI::Token::Number
         PPI::Token::Number::Binary
         PPI::Token::Number::Octal
         PPI::Token::Number::Hex
         PPI::Token::Number::Float
            PPI::Token::Number::Exp
         PPI::Token::Number::Version
      PPI::Token::Word
      PPI::Token::DashedWord
      PPI::Token::Symbol
         PPI::Token::Magic
      PPI::Token::ArrayIndex
#     PPI::Token::Operator
      PPI::Token::Quote
         PPI::Token::Quote::Single
         PPI::Token::Quote::Double
         PPI::Token::Quote::Literal
         PPI::Token::Quote::Interpolate
      PPI::Token::QuoteLike
         PPI::Token::QuoteLike::Backtick
         PPI::Token::QuoteLike::Command
         PPI::Token::QuoteLike::Regexp
         PPI::Token::QuoteLike::Words
         PPI::Token::QuoteLike::Readline
      PPI::Token::Regexp
         PPI::Token::Regexp::Match
         PPI::Token::Regexp::Substitute
         PPI::Token::Regexp::Transliterate
      PPI::Token::HereDoc
      PPI::Token::Cast
      PPI::Token::Structure
      PPI::Token::Label
      PPI::Token::Separator
      PPI::Token::Data
      PPI::Token::End
      PPI::Token::Prototype
      PPI::Token::Attribute
      PPI::Token::Unknown

=cut
# }}}

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
    q{-default} => {
      infix => { before => q{ }, after => q{ } },
      prefix => q{},
      postfix => q{}
    },
    q{->} => { infix => { before => q{}, after => q{} } },
    q{,} => { infix => { before => q{}, after => q{ } } },
  },
  statement => { pre => q{}, post => qq{\n} },
  indent => q{    },
  #
  # The last statement of a function doesn't get a newline.
  #
  subroutine => {
    inter => q{ },
    open => { pre => qq{\n  }, post => qq{\n} },
    close => { pre => qq{\n  }, post => q{} },
    attribute => { pre => q{ }, post => q{ } }
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

  $self->_remove_whitespace_before( %args );
  $self->_remove_whitespace_after( %args );
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

# {{{ _canon_whitespace_around( node => $node )

sub _canon_whitespace_around {
  my $self = shift;
  my %args = @_;
  croak "*** Internal error - No node passed in" unless
    $args{node};

  $self->_canon_whitespace_before( %args );
  $self->_canon_whitespace_after( %args );
}

# }}}

# {{{ _ppi_token_operator( node => $node )

sub _ppi_token_operator {
  my $self = shift;
  my %args = @_;
  croak "*** No node specified!" unless
    exists $args{node};
  my $node = $args{node};
  my $operator = $node->content;
  my $setting = defined $self->settings->{operator}->{$operator} ? 
                        $self->settings->{operator}->{$operator} :
                        $self->settings->{operator}->{'-default'};
  #
  # Prefix-only (!$x, ~$x,-$x,+$x)
  #
  if ( $operator eq '!' or
       $operator eq '~' or
       ( $operator eq '-' and
         ( !$node->sprevious_sibling or
            $node->sprevious_sibling->isa('PPI::Token::Operator') ) ) or
       ( $operator eq '+' and
         ( !$node->sprevious_sibling or
            $node->sprevious_sibling->isa('PPI::Token::Operator') ) ) or
       ( $operator eq '++' and
         ( !$node->sprevious_sibling or
            $node->sprevious_sibling->isa('PPI::Token::Operator') ) ) or
       ( $operator eq '--' and
         ( !$node->sprevious_sibling or
            $node->sprevious_sibling->isa('PPI::Token::Operator') ) ) ) {
    while ( $node->next_sibling and
            $node->next_sibling->isa('PPI::Token::Whitespace') ) {
      $node->next_sibling->remove;
    }

    if ( $node->snext_sibling and $setting->{prefix} ne q{} ) {
      my $whitespace = PPI::Token::Whitespace->new;
      $whitespace->set_content( $setting->{prefix} );
      $node->insert_after( $whitespace );
    }
  }

  #
  # Postfix ($x++, $x--)
  #
  elsif ( ( $operator eq '++' and
            ( !$node->sprevious_sibling or
               $node->sprevious_sibling->isa('PPI::Token::Symbol') ) ) or
          ( $operator eq '--' and
            ( !$node->sprevious_sibling or
               $node->sprevious_sibling->isa('PPI::Token::Symbol') ) ) ) {
    while ( $node->previous_sibling and
            $node->previous_sibling->isa('PPI::Token::Whitespace') ) {
      $node->previous_sibling->remove;
    }
    while ( $node->next_sibling and
            $node->next_sibling->isa('PPI::Token::Whitespace') ) {
      $node->next_sibling->remove;
    }

    if ( $node->sprevious_sibling and $setting->{postfix} ne q{} ) {
      my $whitespace = PPI::Token::Whitespace->new;
      $whitespace->set_content( $setting->{postfix} );
      $node->insert_before( $whitespace );
    }
  }

  #
  # Infix
  #
  else {
    while ( $node->next_sibling and
            $node->next_sibling->isa('PPI::Token::Whitespace') ) {
      $node->next_sibling->remove;
    }
    while ( $node->previous_sibling and
            $node->previous_sibling->isa('PPI::Token::Whitespace') ) {
      $node->previous_sibling->remove;
    }

    if ( $node->sprevious_sibling and $setting->{infix}->{before} ne q{} ) {
      my $whitespace = PPI::Token::Whitespace->new;
      $whitespace->set_content( $setting->{infix}->{before} );
      $node->insert_before( $whitespace );
    }
    if ( $node->snext_sibling and $setting->{infix}->{after} ne q{} ) {
      my $whitespace = PPI::Token::Whitespace->new;
      $whitespace->set_content( $setting->{infix}->{after} );
      $node->insert_after( $whitespace );
    }
  }
}

# }}}

# {{{ _ppi_statement_sub( node => $node )

sub _ppi_statement_sub {
  my $self = shift;
  my %args = @_;
  croak "*** No node specified!" unless
    exists $args{node};
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
  if ( my $node_list = $self->ppi->find('PPI::Statement::Sub') ) {
    for my $node ( @$node_list ) {
      $self->_ppi_statement_sub( node => $node );
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

=pod

 PPI::Element
    PPI::Node
       PPI::Document
          PPI::Document::Fragment
       PPI::Statement
          PPI::Statement::Package
          PPI::Statement::Include
          PPI::Statement::Sub
             PPI::Statement::Scheduled
          PPI::Statement::Compound
          PPI::Statement::Break
          PPI::Statement::Given
          PPI::Statement::When
          PPI::Statement::Data
          PPI::Statement::End
          PPI::Statement::Expression
             PPI::Statement::Variable
          PPI::Statement::Null
          PPI::Statement::UnmatchedBrace
          PPI::Statement::Unknown
       PPI::Structure
          PPI::Structure::Block
          PPI::Structure::Subscript
          PPI::Structure::Constructor
          PPI::Structure::Condition
          PPI::Structure::List
          PPI::Structure::For
          PPI::Structure::Given
          PPI::Structure::When
          PPI::Structure::Unknown
    PPI::Token
       PPI::Token::Whitespace
       PPI::Token::Comment
       PPI::Token::Pod
       PPI::Token::Number
          PPI::Token::Number::Binary
          PPI::Token::Number::Octal
          PPI::Token::Number::Hex
          PPI::Token::Number::Float
             PPI::Token::Number::Exp
          PPI::Token::Number::Version
       PPI::Token::Word
       PPI::Token::DashedWord
       PPI::Token::Symbol
          PPI::Token::Magic
       PPI::Token::ArrayIndex
       PPI::Token::Operator
       PPI::Token::Quote
          PPI::Token::Quote::Single
          PPI::Token::Quote::Double
          PPI::Token::Quote::Literal
          PPI::Token::Quote::Interpolate
       PPI::Token::QuoteLike
          PPI::Token::QuoteLike::Backtick
          PPI::Token::QuoteLike::Command
          PPI::Token::QuoteLike::Regexp
          PPI::Token::QuoteLike::Words
          PPI::Token::QuoteLike::Readline
       PPI::Token::Regexp
          PPI::Token::Regexp::Match
          PPI::Token::Regexp::Substitute
          PPI::Token::Regexp::Transliterate
       PPI::Token::HereDoc
       PPI::Token::Cast
       PPI::Token::Structure
       PPI::Token::Label
       PPI::Token::Separator
       PPI::Token::Data
       PPI::Token::End
       PPI::Token::Prototype
       PPI::Token::Attribute
       PPI::Token::Unknown

=cut

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
