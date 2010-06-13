use v6;

subset State of Str where
    'gone' | 'fetched' | 'built' | 'tested' | 'installed'
;
enum Result <failure success forced-success>;

role App::Pls::ProjectsState {
    method state-of($project --> State) { !!! }
    method set-state-of($project, State $state) { !!! }
    method deps-of($project) { !!! }
    method reached-state($project, State $state --> Bool) { !!! }
}

class App::Pls::ProjectsState::Hash does App::Pls::ProjectsState {
    has %!projects;

    method new(%projects is rw) {
        self.bless(*, :%projects);
    }

    method state-of($project --> State) {
        (%!projects{$project} // { :state<gone> })<state> // 'gone';
    }

    method set-state-of($project, State $state) {
        %!projects{$project}<state> = $state;
    }

    method deps-of($project) {
        if %!projects.exists($project) {
            if %!projects{$project}.exists('deps') {
                return %!projects{$project}<deps>.list;
            }
            return ();
        }
        die "No such project: $project";
    }

    method reached-state($project, $goal-state --> Bool) {
        my $actual-state = self.state-of($project);
        my @states = <gone fetched built tested installed>;
        my %state-levels = invert @states;
        return %state-levels{$actual-state} >= %state-levels{$goal-state};
    }
}

role App::Pls::Fetcher {
    method fetch($project) { !!! }
}

role App::Pls::Builder {
    method build($project) { !!! }
}

role App::Pls::Tester {
    method test($project) { !!! }
}

role App::Pls::Installer {
}

class App::Pls::Core {
    has App::Pls::ProjectsState $!projects;
    has App::Pls::Fetcher       $!fetcher;
    has App::Pls::Builder       $!builder;
    has App::Pls::Tester        $!tester;

    method state-of($project) {
        return $!projects.state-of($project);
    }

    method fetch(*@projects --> Result) {
        for @projects -> $project {
            my %*seen-projects;
            return failure
                if self!fetch-helper($project) == failure;
        }
        return success;
    }

    method !fetch-helper($project --> Result) {
        %*seen-projects{$project}++;
        for $!projects.deps-of($project) -> $dep {
            return failure
                if %*seen-projects{$dep};
            return failure
                if self!fetch-helper($dep) == failure;
        }
        if $!projects.reached-state($project, 'fetched') {
            return success;
        }
        elsif $!fetcher.fetch($project) == success {
            $!projects.set-state-of($project, 'fetched');
            return success;
        }
        else {
            return failure;
        }
    }

    method build(*@projects) {
        for @projects -> $project {
            my %*seen-projects;
            return failure
                if self!fetch-helper($project) == failure;
            return failure
                if self!build-helper($project) == failure;
        }
        return success;
    }

    method !build-helper($project --> Result) {
        for $!projects.deps-of($project) -> $dep {
            return failure
                if self!build-helper($dep) == failure;
        }
        if $!projects.reached-state($project, 'built') {
            return success;
        }
        elsif $!builder.build($project) == success {
            $!projects.set-state-of($project, 'built');
            return success;
        }
        else {
            return failure;
        }
    }

    method test(*@projects, Bool :$ignore-deps) {
        for @projects -> $project {
            my %*seen-projects;
            return failure
                if self!fetch-helper($project) == failure;
            return failure
                if self!build-helper($project) == failure;
            # RAKUDO: an unspecified $ignore-deps should be False, is Any
            return failure
                if self!test-helper($project, :ignore-deps(?$ignore-deps))
                    == failure;
        }
        return success;
    }

    method !test-helper($project, Bool :$ignore-deps --> Result) {
        unless $ignore-deps {
            for $!projects.deps-of($project) -> $dep {
                return failure
                    if self!test-helper($dep) == failure;
            }
        }
        if $!projects.reached-state($project, 'tested') {
            return success;
        }
        elsif $!tester.test($project) == success {
            $!projects.set-state-of($project, 'tested');
            return success;
        }
        else {
            return failure;
        }
    }

    method install(*@projects, Bool :$force, Bool :$skip-test) {
        return;
    }
}
