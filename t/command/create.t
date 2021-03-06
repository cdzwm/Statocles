
use Statocles::Base 'Test';
my $SHARE_DIR = path( __DIR__, '..', 'share' );
use Statocles::Command;
use Capture::Tiny qw( capture );
use YAML;

subtest 'create a site' => sub {
    my $cwd = cwd;

    subtest 'project site with file deploy' => sub {
        my $tmp = tempdir;
        chdir $tmp;

        my $in = $SHARE_DIR->child( qw( create project_file_in.txt ) )->openr_utf8;
        local *STDIN = $in;

        my @args = ( 'create' );
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };

        is $exit, 0;
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        eq_or_diff $out, $SHARE_DIR->child( qw( create project_file_out.txt ) )->slurp_utf8;

        my $expect_config = site_config();
        $expect_config->{site}{args}{nav}{main}[0]{href} = "/blog";
        $expect_config->{site}{args}{index} = "page";
        $expect_config->{deploy}{class} = "Statocles::Deploy::File";
        $expect_config->{deploy}{args}{path} = ".";

        ok $tmp->child( 'site.yml' )->is_file, 'site.yml file exists';
        cmp_deeply
            YAML::Load( $tmp->child( 'site.yml' )->slurp_utf8 ),
            $expect_config,
            'config is complete and correct';

        ok $tmp->child( 'blog' )->is_dir, 'blog dir exists';
        ok $tmp->child( 'static' )->is_dir, 'static dir exists';
        ok $tmp->child( 'page' )->is_dir, 'page dir exists';
        ok !$tmp->child( 'theme' )->exists, 'theme dir does not exists';

        chdir $cwd;
    };

    subtest 'do nothing at all' => sub {
        my $tmp = tempdir;
        chdir $tmp;

        my $in = $SHARE_DIR->child( qw( create none_in.txt ) )->openr_utf8;
        local *STDIN = $in;

        my @args = ( 'create' );
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };

        is $exit, 0;
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        eq_or_diff $out, $SHARE_DIR->child( qw( create none_out.txt ) )->slurp_utf8;

        my $expect_config = site_config();
        $expect_config->{deploy}{class} = 'Statocles::Deploy::File';
        $expect_config->{deploy}{args}{path} = '.';

        ok $tmp->child( 'site.yml' )->is_file, 'site.yml file exists';
        cmp_deeply
            YAML::Load( $tmp->child( 'site.yml' )->slurp_utf8 ),
            $expect_config,
            'config is complete and correct';

        ok $tmp->child( 'blog' )->is_dir, 'blog dir exists';
        ok $tmp->child( 'static' )->is_dir, 'static dir exists';
        ok $tmp->child( 'page' )->is_dir, 'page dir exists';
        ok !$tmp->child( 'theme' )->exists, 'theme dir does not exists';

        chdir $cwd;
    };

    chdir $cwd;
};

subtest 'git deploy' => sub {
    if ( !eval { require Statocles::Deploy::Git; 1 } ) {
        pass "No test: Statocles::Deploy::Git failed to load: $@";
        return;
    }

    my $git_version = Statocles::Deploy::Git->_git_version;
    diag "Git version: $git_version";
    if ( $git_version < 1.007002 ) {
        pass "No test: Git 1.7.2 or higher required";
        return;
    }

    require Git::Repository;
    my $cwd = cwd;

    subtest 'basic blog site with git' => sub {
        my $tmp = tempdir;
        chdir $tmp;

        my $in = $SHARE_DIR->child( qw( create basic_blog_in.txt ) )->openr_utf8;
        local *STDIN = $in;

        my @args = ( 'create' );
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };

        is $exit, 0;
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        eq_or_diff $out, $SHARE_DIR->child( qw( create basic_blog_out.txt ) )->slurp_utf8;

        ok $tmp->child( 'site.yml' )->is_file, 'site.yml file exists';
        my $expect_config = site_config();

        $expect_config->{deploy}{class} = 'Statocles::Deploy::Git';
        $expect_config->{deploy}{args}{branch} = 'master';
        $expect_config->{theme}{args}{store} = 'theme';

        cmp_deeply
            YAML::Load( $tmp->child( 'site.yml' )->slurp_utf8 ),
            $expect_config,
            'config is complete and correct';

        ok $tmp->child( 'blog' )->is_dir, 'blog dir exists';
        ok $tmp->child( 'static' )->is_dir, 'static dir exists';
        ok $tmp->child( 'page' )->is_dir, 'page dir exists';
        ok $tmp->child( 'theme' )->is_dir, 'theme dir exists';

        ok $tmp->child( '.git' )->is_dir, 'git repository created';
        eq_or_diff $tmp->child( '.gitignore' )->slurp,
            qq{\n.statocles\n},
            'gitignore is created',
            ;

        chdir $cwd;
    };

    subtest 'init in existing git repo' => sub {
        my $tmp = tempdir;
        chdir $tmp;

        Git::Repository->run( 'init' );
        $tmp->child( '.gitignore' )->spew( "some\n\nexisting\npaths\n" );

        my $in = $SHARE_DIR->child( qw( create basic_blog_in.txt ) )->openr_utf8;
        local *STDIN = $in;

        my @args = ( 'create' );
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };

        is $exit, 0;
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        eq_or_diff $out, $SHARE_DIR->child( qw( create basic_blog_out.txt ) )->slurp_utf8;

        ok $tmp->child( 'site.yml' )->is_file, 'site.yml file exists';
        my $expect_config = site_config();

        $expect_config->{deploy}{class} = 'Statocles::Deploy::Git';
        $expect_config->{deploy}{args}{branch} = 'master';
        $expect_config->{theme}{args}{store} = 'theme';

        cmp_deeply
            YAML::Load( $tmp->child( 'site.yml' )->slurp_utf8 ),
            $expect_config,
            'config is complete and correct';

        ok $tmp->child( 'blog' )->is_dir, 'blog dir exists';
        ok $tmp->child( 'static' )->is_dir, 'static dir exists';
        ok $tmp->child( 'page' )->is_dir, 'page dir exists';
        ok $tmp->child( 'theme' )->is_dir, 'theme dir exists';

        ok $tmp->child( '.git' )->is_dir, 'git repository still exists';
        eq_or_diff $tmp->child( '.gitignore' )->slurp,
            qq{some\n\nexisting\npaths\n\n.statocles\n},
            'gitignore is added to',
            ;

        chdir $cwd;
    };

};

done_testing;

sub site_config {
    return {
        site => {
            class => 'Statocles::Site',
            args => {
                title => 'My Statocles Site',
                nav => {
                    main => [
                        {
                            title => 'Blog',
                            href => '/',
                        },
                    ],
                },
                theme => { '$ref' => 'theme' },
                apps => {
                    blog => { '$ref' => 'blog_app' },
                    page => { '$ref' => 'page_app' },
                    static => { '$ref' => 'static_app' },
                },
                index => 'blog',
                deploy => { '$ref' => 'deploy' },
            },
            on => [
                {
                    build => {
                        '$class' => 'Statocles::Plugin::LinkCheck',
                        '$method' => 'check_pages',
                    },
                },
            ],
        },

        blog_app => {
            class => 'Statocles::App::Blog',
            args => {
                store => 'blog',
                url_root => '/blog',
            },
        },

        page_app => {
            class => 'Statocles::App::Plain',
            args => {
                store => 'page',
                url_root => '/page',
            },
        },

        static_app => {
            class => 'Statocles::App::Static',
            args => {
                store => 'static',
                url_root => '/static',
            },
        },

        theme => {
            class => 'Statocles::Theme',
            args => {
                store => '::default',
            },
        },

    };
}

