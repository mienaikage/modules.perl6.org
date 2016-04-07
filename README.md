# modules.perl6.org

These are the scripts to generate the website on http://modules.perl6.org/

## TODOs

Want to help out? Check if any [open Issues](https://github.com/perl6/modules.perl6.org/issues) exist that you might be able to solve. We also have
[a list of TODO ideas](TODO-IDEAS.md) you might be interested in.

## Development

Please use the following steps to aid you in your development:
- Create a token with access to public repositories. To run the scripts, you need a [GitHub token](https://github.com/blog/1509-personal-api-tokens) with rights to query Perl 6 module GitHub repository information.

- Save the token in file named `github-token`

- Install prerequisites for build script:
```
    $ perl Build.PL
    $ ./Build installdeps
```

- Run build script
```
    $ perl bin/build-project-list.pl --limit=<number-of-modules>
```

You can also create file `META.list.local` that contains specific URLs
you may wish to fetch for debug purposes. Use the `--meta-list` argument
to specify the location of that file. See `--help` for all options.

- The build script automatically starts the Mojolicious app that powers the
front end. To disable that behaviour, specify the `--no-app-start` flag:
```bash
    $ perl build-project-list.pl --no-app-start
```

#### Browser Support

We support the current and previous major releases of Chrome, Firefox, Internet Explorer, and Safari. Please test layout changes. Lacking actual browers to test in, you can use [browsershots.org](http://browsershots.org)
or [browserstack.com](http://browserstack.com).

## Front-End App

This is the app that reads the database generated by the
`build-project-list.pl` script and displays web pages.
See [DEPLOYMENT.md file in the mojo-app directory](mojo-app/DEPLOYMENT.md)

## Seeing your changes

Once committed, the production cron job will pick up your changes on the 20th and 50th minutes of every hour. The script can take up to 10 minutes to complete.

```
20,50   *       *       *       *       sh update-modules.perl6.org > log/update.log 2>&1; cp log/update.log /var/www/modules.perl6.org/public/update.log
```

The cron job results can be found [here](http://modules.perl6.org/update.log).

#### Note About Cache

Certain data is cached by the site and is only updated when some event
(like new commits to the dist's repo) happens. This includes travis statuses,
logotypes, and Koality metrics. If your changes require doing so, you can
trigger a full rebuild of the database and refresh of caches by including
`[REBUILD]` as part of the **title** of your commit message.

If you are adding a feature that caches something, it needs to watch for
`FULL_REBUILD` environmental variable and refresh the caches if that variable
is set to a true value.

## Author

Intial version contributed by patrickas++ on #perl6

## License

Artistic License 2.0
