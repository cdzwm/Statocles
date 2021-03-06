
use Statocles::Base 'Test';
use Statocles::Store::File;
use File::Copy::Recursive qw( dircopy );
use Capture::Tiny qw( capture );
my $SHARE_DIR = path( __DIR__, '..', '..', 'share' );
build_test_site( theme => $SHARE_DIR->child( 'theme' ) );

my $ignored_store = Statocles::Store::File->new(
    path => $SHARE_DIR->child( qw( store files ignore ) ),
);

subtest 'read files' => sub {
    my $store = Statocles::Store::File->new(
        path => $SHARE_DIR->child( qw( store files ) ),
    );
    my $content = $store->read_file( path( 'text.txt' ) );
    eq_or_diff $SHARE_DIR->child( qw( store files text.txt ) )->slurp_utf8, $content;
};

subtest 'has file' => sub {
    my $store = Statocles::Store::File->new(
        path => $SHARE_DIR->child( qw( store files ) ),
    );
    ok $store->has_file( path( 'text.txt' ) );
    ok !$store->has_file( path( 'missing.exe' ) );
};

subtest 'find files' => sub {
    my $store = Statocles::Store::File->new(
        path => $SHARE_DIR->child( qw( store files ) ),
    );
    my @expect_paths = (
        path( qw( text.txt ) )->absolute( '/' ),
        path( qw( image.png ) )->absolute( '/' ),
        path( qw( folder doc.markdown ) )->absolute( '/' ),
    );

    my $iter = $store->find_files;
    my @got_paths;
    while ( my $path = $iter->() ) {
        push @got_paths, $path;
    }

    cmp_deeply \@got_paths, bag( @expect_paths )
        or diag explain \@got_paths;

    subtest 'can pass paths to read_file' => sub {
        my ( $path ) = grep { $_->basename eq 'text.txt' } @got_paths;
        eq_or_diff $store->read_file( $path ),
            $SHARE_DIR->child( qw( store files text.txt ) )->slurp_utf8;
    };

};

subtest 'open file' => sub {
    my $store = Statocles::Store::File->new(
        path => $SHARE_DIR->child( qw( store files ) ),
    );

    my $fh = $store->open_file( path( 'text.txt' ) );
    my $content = do { local $/; <$fh> };
    eq_or_diff $content, $SHARE_DIR->child( qw( store files text.txt ) )->slurp_raw;
};

subtest 'write files' => sub {

    subtest 'string' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };

        my $tmpdir = tempdir;
        my $store = Statocles::Store::File->new(
            path => $tmpdir,
        );

        my $content = "\x{2603} This is some plain text";

        # write_file with string is written using UTF-8
        $store->write_file( path( qw( store files text.txt ) ), $content );

        my $path = $tmpdir->child( qw( store files text.txt ) );
        eq_or_diff $path->slurp_utf8, $content;

        ok !@warnings, 'no warnings from write'
            or diag "Got warnings: \n\t" . join "\n\t", @warnings;
    };

    subtest 'filehandle' => sub {
        my $tmpdir = tempdir;
        my $store = Statocles::Store::File->new(
            path => $tmpdir,
        );

        subtest 'plain text files' => sub {
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, $_[0] };

            my $fh = $SHARE_DIR->child( qw( store files text.txt ) )->openr_raw;

            $store->write_file( path( qw( store files text.txt ) ), $fh );

            my $path = $tmpdir->child( qw( store files text.txt ) );
            eq_or_diff $path->slurp_raw, $SHARE_DIR->child( qw( store files text.txt ) )->slurp_raw;

            ok !@warnings, 'no warnings from write'
                or diag "Got warnings: \n\t" . join "\n\t", @warnings;
        };

        subtest 'images' => sub {
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, $_[0] };

            my $fh = $SHARE_DIR->child( qw( store files image.png ) )->openr_raw;

            $store->write_file( path( qw( store files image.png ) ), $fh );

            my $path = $tmpdir->child( qw( store files image.png ) );
            ok $path->slurp_raw eq $SHARE_DIR->child( qw( store files image.png ) )->slurp_raw,
                'image content is correct';

            ok !@warnings, 'no warnings from write'
                or diag "Got warnings: \n\t" . join "\n\t", @warnings;
        };

    };
};

subtest 'verbose' => sub {

    local $ENV{MOJO_LOG_LEVEL} = 'debug';

    subtest 'write' => sub {
        my $tmpdir = tempdir;
        my $store = Statocles::Store::File->new(
            path => $tmpdir,
        );

        my ( $out, $err, $exit ) = capture {
            $store->write_file( 'path.html' => 'HTML' );
        };
        like $err, qr{\QWrite file: path.html};
    };

    subtest 'read' => sub {
        my $store = Statocles::Store::File->new(
            path => $SHARE_DIR->child( 'theme' ),
        );
        my $path = path( qw( blog post.html.ep ) );
        my ( $out, $err, $exit ) = capture {
            $store->read_file( $path );
        };
        like $err, qr{\QRead file: $path};

    };
};

done_testing;
