# -*- mode: perl -*-
use Test2::Bundle::Extended;
use Capture::Tiny ':all';
use Data::Dumper;
use Cwd;

# Set some enviroment vars
$ENV{MUNIN_PLUGSTATE} = getcwd() . "/testdata/default";
$ENV{MUNIN_MASTER_IP} = "127.0.0.1";

# test config output, check it corresponds to output of original plugins
sub test_config {
    my ($command, $expected) = @_;

    my ($config, $stderr, $exit) = capture {
	system("./plugins/$command", "config");
    };

    # Touch state file so we don't have to fetch
    utime(undef, undef, getcwd() . "/testdata/default/hg612-");

    if ($exit) {
	diag(
	    sprintf(
		"\nCommand: %s\n\nSTDOUT:\n\n%s\n\nSTDERR:\n\n%s\n\n",
		"./plugins/$command config", $config, $stderr
	    )
	);
    }

    is($config, $expected, "$command configuration");
}

test_config(
    "hg612_atm1",
<<'EOF'
host_name hg612
graph_category network
graph_title atm1 traffic
graph_args --base 1000
graph_vlabel bytes per ${graph_period}
down.label received
down.type DERIVE
down.min 0
down.cdef down,8,*
down.draw AREA
up.label sent
up.type DERIVE
up.info Traffic of the atm1 interface.
up.min 0
up.cdef up,8,*
EOF
);

test_config(
    "hg612_atm1_uptime",
<<EOF
host_name hg612
graph_category system
graph_title atm1 Uptime in days
graph_args --base 1000 -l 0
graph_vlabel VDSL Uptime in days
graph_scale no
uptime.label Uptime in days
uptime.draw AREA
EOF
);

test_config(
    "hg612_current_speed",
<<'EOF'
host_name hg612
graph_category speed
graph_title Sync Speed
graph_args --base 1000
graph_vlabel Speed (bps)
graph_scale yes
graph_order downstream upstream
downstream.label Downstream
downstream.draw AREA
upstream.label Upstream
upstream.draw AREA
EOF
);

test_config(
    "hg612_errors",
<<'EOF'
host_name hg612
graph_category line
graph_title Errors
graph_args --base 1000
graph_vlabel errors down (-) / up (+) per ${graph_period}
graph_scale no
downcrc.label CRC errors
downcrc.type DERIVE
downcrc.graph no
upcrc.label CRC errors
upcrc.type DERIVE
upcrc.negative downcrc
upcrc.info Errors received
downfec.label FEC errors
downfec.type DERIVE
downfec.graph no
upfec.label FEC errors
upfec.type DERIVE
upfec.negative downfec
upfec.info Errors received
downhec.label HEC errors
downhec.type DERIVE
downhec.graph no
uphec.label HEC errors
uphec.type DERIVE
uphec.negative downhec
uphec.info Errors received
EOF
);

test_config(
    "hg612_interleaving",
<<'EOF'
host_name hg612
graph_category line
graph_title Interleave Depth
graph_args --base 1000
graph_vlabel Interleave Depth
graph_scale no
graph_order upstream downstream
downstream.label Downstream
downstream.draw LINE
upstream.label Upstream
upstream.draw LINE
EOF
);

test_config(
    "hg612_max_speed",
<<'EOF'
host_name hg612
graph_category speed
graph_title Maximum Attainable Speed
graph_args --base 1000
graph_vlabel Max Speed (bps)
graph_scale yes
graph_order downstream upstream
downstream.label Downstream
downstream.draw AREA
upstream.label Upstream
upstream.draw AREA
EOF
);

test_config(
    "hg612_ptm1",
<<'EOF'
host_name hg612
graph_category network
graph_title ptm1 traffic
graph_args --base 1000
graph_vlabel bytes per ${graph_period}
down.label received
down.type DERIVE
down.min 0
down.cdef down,8,*
down.draw AREA
up.label sent
up.type DERIVE
up.info Traffic of the ptm1 interface.
up.min 0
up.cdef up,8,*
EOF
);

test_config(
    "hg612_ptm1_uptime",
<<'EOF'
host_name hg612
graph_category system
graph_title ptm1 Uptime in days
graph_args --base 1000 -l 0
graph_vlabel VDSL Uptime in days
graph_scale no
uptime.label Uptime in days
uptime.draw AREA
EOF
);

test_config(
    "hg612_pwr",
<<'EOF'
host_name hg612
graph_category line
graph_title Aggregate Tx Power
graph_args --base 1000
graph_vlabel Actual Aggregate Tx Power (dBm)
graph_scale no
downstream.label Downstream
downstream.draw LINE
upstream.label Upstream
upstream.draw LINE
EOF
);

test_config(
    "hg612_snr",
<<'EOF'
host_name hg612
graph_category line
graph_title SNR Margin (dB)
graph_args --base 1000
graph_vlabel SNR Margin (dB)
graph_scale no
graph_order upstream downstream
downstream.label Downstream
downstream.draw LINE
upstream.label Upstream
upstream.draw LINE
EOF
);

test_config(
    "hg612_sync_speed",
<<'EOF'
host_name hg612
graph_category speed
graph_title Attainable vs Current Sync Speed
graph_args --base 1000
graph_vlabel Sync Rate Actual (-) Attainable (+)
graph_scale yes
downstream.label Downstream
downstream.draw LINE
downstream.graph no
upstream.label Upstream
upstream.draw LINE
upstream.graph no
maxdownstream.label Downstream
maxdownstream.draw AREA
maxdownstream.negative downstream
maxupstream.label Upstream
maxupstream.draw AREA
maxupstream.negative upstream
EOF
);

test_config(
    "hg612_vdsl_attenuation",
<<'EOF'
host_name hg612
graph_category line
graph_title Line Attenuation (dB)
graph_args --base 1000
graph_vlabel Line Attenuation (dB)
graph_scale no
U0.label U0
U1.label U1
U2.label U2
U3.label U3
U4.label U4
D1.label D1
D2.label D2
D3.label D3
EOF
);

# test fetch output (with several input files)
sub test_fetch {
    my ($command, $expected, $testdataset, $expectedExit) = @_;

    $testdataset = "default" unless defined $testdataset;
    $expectedExit = 0 unless defined $expectedExit;

    $ENV{MUNIN_PLUGSTATE} = getcwd() . "/testdata/$testdataset";

    # Touch state file so we don't have to fetch
    utime(undef, undef, getcwd() . "/testdata/$testdataset/hg612-");

    my ($result, $stderr, $exit) = capture {
	system("./plugins/$command", "fetch");
    };

    if ($exit ne $expectedExit) {
	diag(
	    sprintf(
		"\nCommand: %s\n\nSTDOUT:\n\n%s\n\nSTDERR:\n\n%s\n\nexit:%d\n\n",
		"./plugins/$command fetch", $result, $stderr, $exit
	    )
	);
    }

    is($result, $expected, "$command fetch output");
}

test_fetch("hg612_atm1", "", undef, 256);

test_fetch(
    "hg612_atm1_uptime",
<<EOF
uptime.value 1.32748842592593
EOF
);

test_fetch(
    "hg612_current_speed",
<<EOF
upstream.value 6987000
downstream.value 24998000
EOF
);

test_fetch(
    "hg612_errors",
<<EOF
upcrc.value 210
downcrc.value 0
upfec.value 0
downfec.value 19730
uphec.value 0
downhec.value 0
EOF
);

test_fetch(
    "hg612_interleaving",
<<EOF
upstream.value 1
downstream.value 4
EOF
);

test_fetch(
    "hg612_max_speed",
<<EOF
upstream.value 6987000
downstream.value 39584000
EOF
);

test_fetch(
    "hg612_ptm1",
<<EOF
down.value 2045808671
up.value 851813310
EOF
);

test_fetch(
    "hg612_ptm1_uptime",
<<EOF
uptime.value 1.32748842592593
EOF
);

test_fetch(
    "hg612_pwr",
<<'EOF'
upstream.value 4.1
downstream.value 11.5
EOF
);

test_fetch(
    "hg612_snr",
<<'EOF'
upstream.value 6.1
downstream.value 13.8
EOF
);

test_fetch(
    "hg612_sync_speed",
<<'EOF'
maxupstream.value 6987000
maxdownstream.value 39584000
upstream.value 6987000
downstream.value 24998000
EOF
);

done_testing;
