package QBit::HTTPAPI::XML;

=encoding UTF-8
=cut

=head1 Описание

Сериализует структуру perl в xml.

=cut

use qbit;

our @ISA    = qw(Exporter);
our @EXPORT = qw(pl2xml);

sub pl2xml {
    my ($data, $pretty) = @_;

    my $cr = $pretty ? "\n" : '';
    my $xml = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>$cr<response>"
        . _pl2xml($data, 1, pretty => $pretty)
        . "$cr</response>";
    return \$xml;
}

sub _pl2xml {
    my ($data, $indent, %opts) = @_;

    my $string = '';

    if (ref($data)) {
        if (ref($data) eq 'HASH') {
            $string .= indent($indent, "<hashref>", %opts);
            if (%$data) {
                $indent++;
                foreach my $key (sort(keys(%$data))) {
                    my $type =
                        "<item key=\""
                      . xml_escape($key) . "\""
                      . (defined($data->{$key}) ? '' : " defined=\"false\"") . ">";
                    $string .= indent($indent, $type, %opts);
                    if (ref($data->{$key})) {
                        $string .= _pl2xml($data->{$key}, $indent + 1, %opts);
                        $string .= indent($indent, "</item>", %opts);
                    } else {
                        $string .= xml_escape($data->{$key}) . "</item>";
                    }
                }
                $indent--;
            }
            $string .= indent($indent, "</hashref>", %opts);
        } elsif (ref($data) eq 'ARRAY') {
            $string .= indent($indent, "<arrayref>", %opts);
            if (@$data) {
                $indent++;
                for (my $i = 0; $i < @$data; $i++) {
                    my $type =
                      "<item key=\"" . xml_escape($i) . "\"" . (defined($data->[$i]) ? '' : " defined=\"false\"") . ">";
                    $string .= indent($indent, $type, %opts);
                    if (ref($data->[$i])) {
                        $string .= _pl2xml($data->[$i], $indent + 1, %opts);
                        $string .= indent($indent, "</item>", %opts);
                    } else {
                        $string .= xml_escape($data->[$i]) . "</item>";
                    }
                }
                $indent--;
            }
            $string .= indent($indent, "</arrayref>", %opts);
        } else {
            throw gettext('Can\'t convert object');
        }
    } else {
        my $type = "<scalar" . (defined($data) ? '' : " defined=\"false\"") . ">";
        $string .= indent($indent, $type . xml_escape($data) . "</scalar>", %opts);
    }

    return $string;
}

sub xml_escape {
    # ============================================================
    # Transforms and filters input characters to acceptable XML characters
    # (or filters them out completely).
    # ------------------------------------------------------------
    local $_ = shift;
    return '' if not defined $_;

    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;
    s/[\0\ca\cb\cc\cd\ce\cf\cg\ch\ck\cl\cn\co\cp\cq\cr\cs\ct\cu\cv\cw\cx\cy\cz\c[\c\\c]\c^\c_]//g;
    s/'/&apos;/g;
    s/"/&quot;/g;

    return $_;
}

sub indent {
    my ($indent, $type, %opts) = @_;

    return ($opts{pretty} ? "\n" . " " x (4 * $indent) : '') . $type;
}

TRUE;
