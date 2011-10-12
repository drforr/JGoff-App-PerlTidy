package JGoff::App::Perltidy;

use PPI;
use Carp qw( croak );
use Moose;

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
  $node->set_content( $whitespace );
  return $node;
}

# }}}

# {{{ _canonize_before( $node, $ws )

sub _canonize_before {
  my $self = shift;
  my ( $node, $whitespace ) = @_;
  while ( $node->previous_sibling and
          $node->previous_sibling->isa( 'PPI::Token::Whitespace' ) ) {
    $node->previous_sibling->remove;
  }
  $node->insert_before( $self->_whitespace_node( $whitespace ) );
}

# }}}

# {{{ _canonize_after( $node, $ws )

sub _canonize_after {
  my $self = shift;
  my ( $node, $ws ) = @_;
  while ( $node->next_sibling and
          $node->next_sibling->isa( 'PPI::Token::Whitespace' ) ) {
    $node->next_sibling->remove;
  }
  $node->insert_after( $self->_whitespace_node( $ws ) );
}

# }}}

# {{{ _debug_stack( $node, $indent, $scope, $index )

sub _debug_stack {
  my $self = shift;
  my %args = @_;
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

  if ( $node->isa( 'PPI::Element' ) ) {
    if ( $node->isa( 'PPI::Node' ) ) {
      if ( $node->isa( 'PPI::Document' ) ) {
        if ( $node->isa( 'PPI::Document::Fragment' ) ) {
die "Uncaught " . ref( $node );
        }
        else {
#die "Uncaught " . ref( $node );
        }
      }
      elsif ( $node->isa( 'PPI::Statement' ) ) {
        if ( $node->isa( 'PPI::Statement::Package' ) ) {
          while( $node->child(0)->next_sibling->isa( 'PPI::Token::Whitespace' ) ) {
            $node->child(0)->next_sibling->remove;
          }
          $node->child(0)->insert_after( $self->_whitespace_node( ' ' ) );
#print "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Statement::Include' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Statement::Sub' ) ) {
          if ( $node->isa( 'PPI::Statement::Scheduled' ) ) {
die "Uncaught " . ref( $node );
          }
          else {
die "Uncaught " . ref( $node );
          }
        }
        elsif ( $node->isa( 'PPI::Statement::Compound' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Statement::Break' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Statement::Given' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Statement::When' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Statement::Data' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Statement::End' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Statement::Expression' ) ) {
          if ( $node->isa( 'PPI::Statement::Variable' ) ) {
die "Uncaught " . ref( $node );
          }
          else {
die "Uncaught " . ref( $node );
          }
        }
        elsif ( $node->isa( 'PPI::Statement::Null' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Statement::UnmatchedBrace' ) ) {
die "Uncaught " . ref( $node );
        }
        else {
die "Uncaught " . ref( $node );
        }
      }
      elsif ( $node->isa( 'PPI::Structure' ) ) {
        if ( $node->isa( 'PPI::Structure::Block' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Structure::Subscript' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Structure::Constructor' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Structure::Condition' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Structure::List' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Structure::For' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Structure::Given' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Structure::When' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Structure::Unknown' ) ) {
die "Uncaught " . ref( $node );
        }
        else {
die "Uncaught " . ref( $node );
        }
      }
      else {
die "Uncaught " . ref( $node );
      }
    }
    elsif ( $node->isa( 'PPI::Token' ) ) {
      if ( $node->isa( 'PPI::Token::Whitespace' ) ) {
      }
      elsif ( $node->isa( 'PPI::Token::Comment' ) ) {
die "Uncaught " . ref( $node );
#        $self->_canonize_before( $node, '' );
#        my $content = $node->content;
#        $content =~ s{ ^ [#] \s* }{# }x;
#        $node->set_content( $content );
      }
      elsif ( $node->isa( 'PPI::Token::Pod' ) ) {
die "Uncaught " . ref( $node );
      }
      elsif ( $node->isa( 'PPI::Token::Number' ) ) {
        if ( $node->isa( 'PPI::Token::Number::Binary' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Token::Number::Octal' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Token::Number::Hex' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Token::Number::Float' ) ) {
          if ( $node->isa( 'PPI::Token::Number::Exp' ) ) {
die "Uncaught " . ref( $node );
          }
          else {
die "Uncaught " . ref( $node );
          }
        }
        elsif ( $node->isa( 'PPI::Token::Number::Version' ) ) {
die "Uncaught " . ref( $node );
        }
        else {
die "Uncaught " . ref( $node );
        }
      }
      elsif ( $node->isa( 'PPI::Token::Word' ) ) {
        if ( $node->parent->isa( 'PPI::Statement::Package' ) ) {
          return;
        }
die "Uncaught " . ref( $node );
      }
      elsif ( $node->isa( 'PPI::Token::DashedWord' ) ) {
die "Uncaught " . ref( $node );
      }
      elsif ( $node->isa( 'PPI::Token::Symbol' ) ) {
        if ( $node->isa( 'PPI::Token::Magic' ) ) {
die "Uncaught " . ref( $node );
        }
        else {
die "Uncaught " . ref( $node );
        }
      }
      elsif ( $node->isa( 'PPI::Token::ArrayIndex' ) ) {
die "Uncaught " . ref( $node );
      }
      elsif ( $node->isa( 'PPI::Token::Operator' ) ) {
die "Uncaught " . ref( $node );
      }
      elsif ( $node->isa( 'PPI::Token::Quote' ) ) {
        if ( $node->isa( 'PPI::Token::Quote::Single' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Token::Quote::Double' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Token::Quote::Literal' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Token::Quote::Interpolate' ) ) {
die "Uncaught " . ref( $node );
        }
        else {
die "Uncaught " . ref( $node );
        }
      }
      elsif ( $node->isa( 'PPI::Token::QuoteLike' ) ) {
        if ( $node->isa( 'PPI::Token::QuoteLike::Backtick' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Token::QuoteLike::Command' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Token::QuoteLike::Regexp' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Token::QuoteLike::Words' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Token::QuoteLike::Readline' ) ) {
die "Uncaught " . ref( $node );
        }
        else {
die "Uncaught " . ref( $node );
        }
      }
      elsif ( $node->isa( 'PPI::Token::Regexp' ) ) {
        if ( $node->isa( 'PPI::Token::Regexp::Match' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Token::Regexp::Substitute' ) ) {
die "Uncaught " . ref( $node );
        }
        elsif ( $node->isa( 'PPI::Token::Regexp::Transliterate' ) ) {
die "Uncaught " . ref( $node );
        }
        else {
die "Uncaught " . ref( $node );
        }
      }
      elsif ( $node->isa( 'PPI::Token::HereDoc' ) ) {
die "Uncaught " . ref( $node );
      }
      elsif ( $node->isa( 'PPI::Token::Cast' ) ) {
die "Uncaught " . ref( $node );
      }
      elsif ( $node->isa( 'PPI::Token::Structure' ) ) {
die "Uncaught " . ref( $node );
      }
      elsif ( $node->isa( 'PPI::Token::Label' ) ) {
die "Uncaught " . ref( $node );
      }
      elsif ( $node->isa( 'PPI::Token::Separator' ) ) {
die "Uncaught " . ref( $node );
      }
      elsif ( $node->isa( 'PPI::Token::Data' ) ) {
die "Uncaught " . ref( $node );
      }
      elsif ( $node->isa( 'PPI::Token::End' ) ) {
die "Uncaught " . ref( $node );
      }
      elsif ( $node->isa( 'PPI::Token::Prototype' ) ) {
die "Uncaught " . ref( $node );
      }
      elsif ( $node->isa( 'PPI::Token::Attribute' ) ) {
die "Uncaught " . ref( $node );
      }
      elsif ( $node->isa( 'PPI::Token::Unknown' ) ) {
die "Uncaught " . ref( $node );
      }
      else {
die "Uncaught " . ref( $node );
      }
    }
  }
  else {
die "Uncaught " . ref( $node );
  }

=pod

  if ( $node->isa( 'PPI::Token' ) ) {
    if ( $node->isa( 'PPI::Token::Word' ) ) {
      if ( $node->content eq 'my' ) {
        $self->_canonize_after( $node, ' ' );
      }
    }
    elsif ( $node->isa( 'PPI::Token::Operator' ) ) {
      if ( $node->content eq '=' ) {
        $self->_canonize_before( $node, ' ' );
        $self->_canonize_after( $node, ' ' );
      }
    }
  }
  elsif ( $node->isa( 'PPI::Statement' ) ) {
    if ( $node->isa( 'PPI::Statement::Variable' ) ) {
      $self->_canonize_after( $node, "\n" );
    }
    elsif ( $node->isa( 'PPI::Statement::Sub' ) ) {
    }
    elsif ( $node->isa( 'PPI::Statement::Expression' ) or
            $node->isa( 'PPI::Statement' ) ) {
      my $whitespace;
      $whitespace = "\n" if
        $node->previous_sibling;
#        $node->previous_sibling or
#        $node->parent->isa( 'PPI::Structure::Block' );
      $whitespace .= '    ' if $scope > 0;
      $node->insert_before( $self->_whitespace_node( $whitespace ) ) if
        $whitespace
    }
  }
  elsif ( $node->isa( 'PPI::Structure::Block' ) ) {
    # sub foo ->XXX<- {
    $node->insert_before( $self->_whitespace_node( "\n  " ) );
$node->child(0)->insert_before(
  $self->_whitespace_node( "\n" )
);
    # sub foo { $first++ ->XXX<- }
    $node->child(-1)->insert_after(
      $self->_whitespace_node( "\n  " )
    );
  }

=cut

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
