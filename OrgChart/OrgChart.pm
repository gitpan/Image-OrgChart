package Image::OrgChart;

use strict;
use GD;
use vars qw($VERSION $DEBUG);
require Exporter;


$VERSION = '0.01';

sub new {
    my ($pkg,@args) = @_;
    my %args;
    if ((scalar @args % 2) == 0) {
        %args = @args;
    }

    ## defaults
    my $self = {
        box_color      => [0,0,0],
        box_fill_color => [75,75,75],
        connect_color  => [0,0,0],
        text_color     => [0,0,0],
        bg_color       => [255,255,255],
        arrow_heads    => 0,
        fill_boxes     => 0,
        h_spacing      => 15,
        v_spacing      => 5,
        path_seperator => '/',
        font           => 'gdTinyFont',
        font_height    => 10,  ## ?
        font_width     => 5,   ## ?
        _data          => {},
        _track         => {
            longest_name => 0,
            shortest_name => 100,
            deapest_path => 0,
            most_keys  => 0,
            },
        _image_info    => {
            height    => 0,
            width     => 0,
            },
        color         => {
            ## used by allocateColor
        },
        data_type     => ( GD::Image->can('gif') ? 'gif' : 'png'),
    };

    ## from new() args
    for (keys %args) {
        $self->{$_} = $args{$_};
    }
    
    return bless($self,$pkg);
}

sub data_type {
    return shift->{data_type};
}

sub add {
    my ($self,$path) = @_;
    $path =~ s/^$self->{path_seperator}//;
    my @arr_path = split(/$self->{path_seperator}/,$path);
    warn("PATH($path) - ",join(',',@arr_path),"\n") if $DEBUG;
    my $curr = '$self->{_data}';
    my $depth = 0;
    foreach my $limb (@arr_path) {
         $curr .= "{'$limb'}";
         if (length($limb) > $self->{_track}{longest_name}) {
             $self->{_track}{longest_name} = length($limb);
         } elsif (length($limb) < $self->{_track}{shortest_name}) {
             $self->{_track}{shortest_name} = length($limb);
         }
    }
    warn("CREATING: $curr\n") if $DEBUG;
    eval("$curr = {} unless (exists $curr)");
    die $@ if $@;
}

sub set_hashref {
    my ($self,$href) = @_;
    $self->{_data} = $href;
}

sub add_hashref {
    my ($self,$href) = @_;
    foreach my $nkey (keys %{ $href }) {
        if ($self->{$nkey}) {
            &add_hashref($self->{$nkey},$href->{$nkey});
        } else {
            $self->{$nkey} = $href->{$nkey};
            if (length($nkey) > $self->{_track}{longest_name}) {
                $self->{_track}{longest_name} = length($nkey);
            } elsif (length($nkey) > $self->{_track}{shortest_name}) {
                $self->{_track}{shortest_name} = length($nkey);
            }
        }
    }
}

sub alloc_collors {
    my ($self,$image) = @_;
    $self->{color}{box_color} = $image->colorAllocate($self->{box_color}[0],$self->{box_color}[1],$self->{box_color}[2]);
    $self->{color}{box_fill_color} = $image->colorAllocate($self->{box_fill_color}[0],$self->{box_fill_color}[1],$self->{box_fill_color}[2]);
    $self->{color}{connect_color} = $image->colorAllocate($self->{connect_color}[0],$self->{connect_color}[1],$self->{connect_color}[2]);
    $self->{color}{text_color} = $image->colorAllocate($self->{text_color}[0],$self->{text_color}[1],$self->{text_color}[2]);
    $self->{color}{bg_color} = $image->colorAllocate($self->{bg_color}[0],$self->{bg_color}[1],$self->{bg_color}[2]);
}

sub draw_boxes {
    my ($self,$image) = @_;
    my ($ULx,$ULy) = (5,5); ## start with some padding
    &_draw_one_row_box($self,$self->{_data},$image,$ULx,$ULy);
}

sub _draw_one_row_box {
    my ($self,$href,$image,$indentX,$indentY) = @_;
    my ($ULx,$ULy) = ($indentX,$indentY);
    foreach my $person (sort keys %{ $href }) {
        my ($LRx,$LRy) = (  ($ULx+$self->{_track}{longest_name}*$self->{font_width})+2  ,  $ULy+$self->{font_height}+2  );
        $image->rectangle($ULx,$ULy,$LRx,$LRy,$self->{color}{box_color});
        $image->string(gdTinyFont,$ULx+2,$ULy+2,$person,$self->{color}{text_color});
        $ULy = ($LRy+$self->{v_spacing});
        my $R_c_point = &mid_point($LRx,$ULy,$LRx,$LRy);
        my $B_c_point = &mid_point($ULx,$LRy,$LRx,$LRy);
        my $depends = scalar keys %{ $href->{$person} };
        if ($depends > 0) {
            my $yval = ( $LRy + ($self->{v_spacing} + ($self->{font_height}+2/2)) );
            my $Xdep_len = ($yval-$B_c_point->[1]);
            my $cy = $yval + ( ($Xdep_len*$depends) - $Xdep_len );
            $self->_draw_line($image,$B_c_point,[$B_c_point->[0],$cy]);
            my ($dep_c_point);
            for (1..$depends) { 
                $dep_c_point = [$LRx,$yval];
                $self->_draw_line($image,[$B_c_point->[0],$yval],$dep_c_point);
                $yval += $Xdep_len;
            }
            $ULy = &_draw_one_row_box($self,$href->{$person},$image,$LRx,$ULy+$self->{v_spacing});
        }
    }
    return $ULy;
}

sub _draw_line {
    my ($self,$image,$from,$to) = @_;
    $image->line($from->[0],$from->[1],$to->[0],$to->[1],$self->{color}{connect_color});
    if ($self->{arrow_heads}) {
        ## draw arrowheads someday
        warn "WARNING: Arrowheads currently unsupported.\n";
    }
}

sub draw {
    my $self = shift;

    ## new image
    $self->_calc_depth();
    $self->calc_image_info();
    my $image = new GD::Image($self->{_image_info}{width},$self->{_image_info}{height});
    $self->alloc_collors($image);
    $image->fill(0,0,$self->{color}{bg_color});
    $self->draw_boxes($image);

    my $dt = $self->{data_type};
    return $image->$dt();
}

sub _calc_depth {
    my $self = shift;
    $Image::OrgChart::S::total = $self->{_track}{deapest_path};
    $Image::OrgChart::S::Kcount = $self->{_track}{most_keys};
    $Image::OrgChart::S::Lname = $self->{_track}{longest_name};
    $Image::OrgChart::S::Sname = $self->{_track}{shortest_name};
    &_re_f_depth($self->{_data});
    $self->{_track}{most_keys} = $Image::OrgChart::S::Kcount;
    $self->{_track}{deapest_path} = $Image::OrgChart::S::total;
    $self->{_track}{longest_name} = $Image::OrgChart::S::Lname;
    $self->{_track}{shortest_name} = $Image::OrgChart::S::Sname;
    undef($Image::OrgChart::S::total);
    undef($Image::OrgChart::S::Kcount);
    undef($Image::OrgChart::S::Lname);
    undef($Image::OrgChart::S::Sname);
}

sub _re_f_depth {
    my $href = shift;
    my $indent = shift;
    $indent ||= 0;
    if ( $indent > $Image::OrgChart::S::total ) {
        $Image::OrgChart::S::total = $indent;
    }
    foreach my $key (keys %$href) {
            if (length($key) > $Image::OrgChart::S::Lname) {
                $Image::OrgChart::S::Lname = length($key);
            } elsif (length($key) < $Image::OrgChart::S::Sname) {
                $Image::OrgChart::S::Sname = length($key);
            }        
        my $value = $href->{$key};
        if (ref($value) eq 'HASH') {
            &_re_f_depth($value, $indent + 1);
            $Image::OrgChart::S::Kcount = ( (scalar keys %$href > $Image::OrgChart::S::Kcount) ? scalar keys %$href : $Image::OrgChart::S::Kcount );
        }
    }
}

sub calc_image_info {
    my $self = shift;
    $self->{_image_info}{height} = 10*($self->{_track}{most_keys} * ($self->{v_spacing}) );
    $self->{_image_info}{width} = 10*($self->{_track}{deapest_path} * ($self->{_track}{longest_name} + $self->{h_spacing}) );
}

sub mid_point {
    my ($x1,$y1,$x2,$y2) = @_;
    my $X = (((_max($x1,$x2) - _min($x1,$x2))/2) + _min($x1,$x2));
    my $Y = (((_max($y1,$y2) - _min($y1,$y2))/2) + _min($y1,$y2));
    return [$X,$Y];
}

sub _min {
    my ($a,$b) = @_;
    return ( $a > $b ? $b : $a);
}

sub _max {
    my ($a,$b) = @_;
    return ( $a < $b ? $b : $a);
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Image::OrgChart - Perl extension for writing org charts

=head1 SYNOPSIS

  use Image::OrgChart;
  use strict; # every job should, eh ?
  
  my $org_chart = Image::OrgChart->new();
  $org_chart->add('/manager/middle-manager/employee1');
  $org_chart->add('/manager/middle-manager/employee2');
  $org_chart->add('/manager/middle-manager/employee3');
  $org_chart->add('/manager/middle-manager/employee4');
  
  $data = $org_chart->draw();
  if ($org_chart->data_type() eq 'gif') {
      ## write gif file
  } elsif ($org_chart->data_type() eq 'png') {
      ## write png file
  }

=head1 DESCRIPTION

 Image::OrgChart, uses the perl GD module to create OrgChart style images in gif or png format, depending on which is available from your version of GD.
 There are several ways to add data to the object, but the most common is the C<$object->add($path)>. The C<$path> can be seperated by any charachter, but the default is a L</>. See the C<new()> method for that and other configuration options.

=head1 FUNCTIONS 

=over 8

=item new([OPTIONS])

 Created a new Image::OrgChart object. Takes a hash-like list of configuration options. See list below.
 
=over 2
 
=item *

   box_color - box border color in arrref triplet. default [0,0,0]
   
=item *

   box_fill_color - box fill color in arrref triplet. default [75,75,75] 
   
=item *

   connect_color - line color in arrref triplet. default [0,0,0]
   
=item *

   text_color - text color in arrref triplet. default [0,0,0]
   
=item *

   bg_color - bg color in arrref triplet. default [255,255,255]
   
=item *

   arrow_heads - 1/0, currently unimplimented
   
=item *

   fill_boxes - 1/0, currently unimplimented

=item *

   h_spacing - horizontal spacing in (in pixels)
   
=item *

   v_spacing - vertical spacing in (in pixels)

=item *

path_seperator - Seperator to use for paths provided by the C<add()> command.


   
=back

=item add(PATH)

 Add data to the object using a seperated scalar. The seperator can be set in the C<new()> constructor, but defaults to L</>.
 
=item set_hashref(HASH_REF)

 This allows assignment of a hash-of-hashes as the data element of the object. People who have not persons underneath them should have an empty hash-reference as the value. e.g.
 
=over 3
 
 $hash{'root'}{'foo'} = {
                         'bar'      => {},
                         'more foo' => {},
                         'kung-foo' => {},
                        };
                        
=back
 
=item draw()

 this plots all of the data from the object and returns the image data.
 
=item data_type()

 returns the data type used by the version of GD in use.
  
=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs with options

  -AXC -v 0.01 -n Image::OrgChart

=back


=head1 AUTHOR

Matt Sanford E<lt>mzsanford@cpan.orgE<gt>

=head1 SEE ALSO

perl(1),GD

=cut
