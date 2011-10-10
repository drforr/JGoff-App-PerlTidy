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
has DEBUG => ( is => 'rw', isa => 'Bool', default => undef );
has settings => ( is => 'rw', isa => 'HashRef', default => sub { { } } );

has ppi => ( is => 'rw', isa => 'Object' );

=head1 NAME

JGoff::App::Perltidy - The great new JGoff::App::Perltidy!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

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
  $whitespace =~ s{ }{|}g if $self->DEBUG;
  $node->set_content( $whitespace );
  return $node;
}

# }}}

# {{{ _debug_stack( $node, $indent, $scope, $index )

sub _debug_stack {
  my $self = shift;
  my %args = @_;
#  my ( $node, $indent, $scope, $index ) = @_;
  my $node = $args{node};
  my $indent = $args{indent};
  my $scope = $args{scope};
  my $index = $args{index};

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

# {{{ _reformat( $node, $indent, $scope, $index )

sub _reformat {
  my $self = shift;
  my %args = @_;
  my $node = $args{node};
  my $scope = $args{scope};

  my $ref = ref $node;

  if ( $node->isa( 'PPI::Token::Word' ) ) {
    if ( $node->content eq 'my' ) {
      while ( $node->next_sibling and
              $node->next_sibling->isa( 'PPI::Token::Whitespace' ) ) {
        $node->next_sibling->remove;
      }
      $node->insert_after( $self->_whitespace_node( " " ) );
    }
  }
  elsif ( $node->isa( 'PPI::Token::Operator' ) ) {
    if ( $node->content eq '=' ) {
      while ( $node->previous_sibling and
              $node->previous_sibling->isa( 'PPI::Token::Whitespace' ) ) {
        $node->previous_sibling->remove;
      }
      $node->insert_before( $self->_whitespace_node( " " ) );
      while ( $node->next_sibling and
              $node->next_sibling->isa( 'PPI::Token::Whitespace' ) ) {
        $node->next_sibling->remove;
      }
      $node->insert_after( $self->_whitespace_node( " " ) );
    }
  }
  elsif ( $node->isa( 'PPI::Statement' ) ) {
    if ( $node->isa( 'PPI::Statement::Variable' ) ) {
      while ( $node->next_sibling and
              $node->next_sibling->isa( 'PPI::Token::Whitespace' ) ) {
        $node->next_sibling->remove;
      }
    }
    elsif ( $node->isa( 'PPI::Statement::Sub' ) ) {
      $node->insert_before( $self->_whitespace_node( "\n" ) );
    }
    else {
      my $whitespace;
      $whitespace = "\n" if
        $node->previous_sibling or
        $node->parent->isa( 'PPI::Structure::Block' );
      $whitespace .= '    ' if $scope > 0;
      $node->insert_before( $self->_whitespace_node( $whitespace ) ) if
        $whitespace
    }
  }
  elsif ( $node->isa( 'PPI::Structure::Block' ) ) {
    # sub foo ->XXX<- {
    $node->insert_before( $self->_whitespace_node( "\n  " ) );
    # sub foo { $first++ ->XXX<- }
    $node->child(-1)->insert_after(
      $self->_whitespace_node( "\n  " )
    );
  }
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

  my @stack = ( {
    node => $self->ppi, indent => 0, scope => 0, index => [ 0 ]
  } );

  my $scope = 0;
  while ( @stack ) {
    my %args = %{ pop @stack };
    my $node = $args{node};
    my $indent = $args{indent};
    my $scope = $args{scope};
    my $index = $args{index};
    $self->_debug_stack( %args ) if
      $DEBUG and $DEBUG == 1;

    $self->_reformat( %args );

    if ( $node->can( 'elements' ) ) {
      my @index = @$index;
      my @elements = $node->elements;
      for ( my $idx = $#elements ; $idx >= 0 ; $idx-- ) {
        push @stack, {
          node => $elements[$idx], 
          indent => $indent + 1, 
          scope => $node->isa( 'PPI::Structure::Block' ) ? 1 : 0,
          index => [ @index, $idx ] 
        };
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
