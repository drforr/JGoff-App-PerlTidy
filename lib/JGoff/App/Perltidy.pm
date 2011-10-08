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
# Defaults to Whitesmith, most complex I could find.
#
# $x = 0;
# sub foo
#   {
#     $bar++;
#     $bar += 32;
#     do { $stuff++ };
#     die "Blah blah" if # Conditionals at EOL,
#       $bar == 1;       # tests below that.
#     this( list => 'of', parameters => [qw( is really-long )],
#           and => 'will', wrap => 'at', 72 => columns );
#     if ( my $condition = stuff( like => this() )
#       {
#         $func = 27 / int( $stuff );
#       }
#   }
#
has DEBUG => ( is => 'rw', isa => 'Int', default => 0 );
has settings => ( is => 'rw', isa => 'HashRef', default => sub { { } } );

has ppi => ( is => 'rw', isa => 'Object' );

=head1 NAME

JGoff::App::Perltidy - The great new JGoff::App::Perltidy!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=pod

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

# {{{ _whitespace_node( whitespace => $ws )

sub _whitespace_node {
  my $self = shift;
  my %args = @_;

  my $whitespace = PPI::Token::Whitespace->new;
  $whitespace->set_content( $args{whitespace} );
  return $whitespace;
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
      $node->insert_after(
        $self->_whitespace_node( whitespace => $setting->{prefix} ) );
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
      $node->insert_before(
        $self->_whitespace_node( whitespace => $setting->{postfix} ) );
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
      $node->insert_before(
        $self->_whitespace_node( whitespace => $setting->{infix}->{before} ) );
    }
    if ( $node->snext_sibling and $setting->{infix}->{after} ne q{} ) {
      my $whitespace = PPI::Token::Whitespace->new;
      $node->insert_after(
        $self->_whitespace_node( whitespace => $setting->{infix}->{after} ) );
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
  my $node = $args{node};
  my $setting = $self->settings->{subroutine};

  $node = $node->first_element; # 'sub'

  $node = $node->snext_sibling; # 'foo' - work backwards
  while ( $node->previous_sibling and
          $node->previous_sibling->isa('PPI::Token::Whitespace') ) {
    $node->previous_sibling->remove;
  }
  if ( $setting->{inter} ne q{} ) {
    $node->insert_before(
      $self->_whitespace_node( whitespace => $setting->{inter} ) );
  }

  $node = $node->snext_sibling; # '{}'
  while ( $node->previous_sibling and
          $node->previous_sibling->isa('PPI::Token::Whitespace') ) {
    $node->previous_sibling->remove;
  }
  if ( $setting->{open}->{pre} ne q{} ) {
    $node->insert_before(
      $self->_whitespace_node( whitespace => $setting->{open}->{pre} ) );
  }
  $node = $node->schild(0); # '{-><-}'
  while ( $node->previous_sibling and
          $node->previous_sibling->isa('PPI::Token::Whitespace') ) {
    $node->previous_sibling->remove;
  }
#use YAML;die Dump($node);
  if ( $setting->{open}->{post} ne q{} ) {
    $node->insert_before(
      $self->_whitespace_node( whitespace => $setting->{open}->{post} ) );
  }
}

# }}}

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use JGoff::App::Perltidy;

    my $perltidy = JGoff::App::Perltidy->new;
    print $perltidy->reformat( text => '$x++ - 5 < 32; map { $_+1 } @foo' );

=head1 METHODS

=head2 reformat( text => $code )

=cut

# {{{ _whitespace_node( $ws )

sub _whitespace_node {
  my $self = shift;
  my ( $whitespace ) = @_;

  my $node = PPI::Token::Whitespace->new;
  $node->set_content( $whitespace );
  return $node;
}

# }}}

# {{{ _debug_stack

sub _debug_stack {
  my $self = shift;
  my ( $node, $indent, $index ) = @_;

  my $ref = ref( $node );
  $ref =~ s{^PPI::}{};
  my $str;
#  $str = $sub;
  $str .= " (" . join( ',', map { sprintf "%02d", $_ } @$index ) . ") ";
  $str .= ' ' x ( 30 - length($str) + $indent );
  $str .= $ref;
  $str .= ' ' x ( 60 - length($str) );
  $str .= " (" . $node->content . ")" if $node->isa( 'PPI::Token' );
  $str .= "\n";
  warn $str;
}

# }}}

# {{{ reformat( text => $code )

sub reformat {
  my $self = shift;
  my %args = @_;
  croak "*** No text specified!" unless
    exists $args{text};
  my $DEBUG = $args{debug};

  $self->ppi( PPI::Document->new( \$args{text} ) );

  my @stack = ( [ $self->ppi, 0, [ 0 ] ] );

  while(@stack) {
    my ( $node, $indent, $index ) = @{ pop @stack };

    $self->_debug_stack( $node, $indent, $index ) if $DEBUG and $DEBUG == 1;

    if ( $node->isa( 'PPI::Statement' ) ) {
      $node->insert_after( $self->_whitespace_node( "\n|" ) )
        if $node->next_sibling;
    }
    elsif ( $node->isa( 'PPI::Structure::Block' ) ) {
      $node->first_element->insert_after(
        $self->_whitespace_node( "\n|||||" )
      );
      $node->insert_before( $self->_whitespace_node( "\n|||" ) );
    }

    if ( $node->can( 'elements' ) ) {
      my @index = @$index;
      my @elements = $node->elements;
      for ( my $idx = $#elements ; $idx >= 0 ; $idx-- ) {
        push @stack, [
          $elements[$idx], 
          $indent + 1, 
          [ @index, $idx ] 
        ];
      }
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
