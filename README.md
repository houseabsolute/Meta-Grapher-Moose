# NAME

Meta::Grapher::Moose - Produce a GraphViz graph showing meta-information about classes and roles

# VERSION

version 0.04

# SYNOPSIS

    you@hostname:~$ graph-meta.pl --package Your::Package --output your-package.svg

# DESCRIPTION

This distribution ships an executable, `graph-meta.pl`, that uses
[GraphViz2](https://metacpan.org/pod/GraphViz2) to produce a graph showing information about a package. It always
shows the roles consumed by the package, and the roles those roles consume,
and so on. If given a class name, it will also graph inheritance, but you can
give this tool a role name as well.

**This is still a very early release and there are a lot of improvements that
could be made. Suggestions and pull requests are welcome.**

# SUPPORT

Bugs may be submitted through [the RT bug tracker](http://rt.cpan.org/Public/Dist/Display.html?Name=Meta-Grapher-Moose)
(or [bug-meta-grapher-moose@rt.cpan.org](mailto:bug-meta-grapher-moose@rt.cpan.org)).

I am also usually active on IRC as 'drolsky' on `irc://irc.perl.org`.

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# COPYRIGHT AND LICENCE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
