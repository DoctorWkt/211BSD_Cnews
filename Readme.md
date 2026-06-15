# Installing C News on a 2.11BSD System

This project holds a tarball and a set of scripts which makes it
easy to install C News on to an existing 2.11BSD system running
under OpenSimH.

I started with Jon Brase's
[CNews-PiDP-11](https://github.com/jwbrase/CNews-PiDP-11) work; he
has tweaked the original C News source so that it can be compiled
under 2.11BSD. He also wrote a
[howto](https://github.com/jwbrase/pdp11-tools/tree/master/howtos)
with a walkthrough on the compilation and installation.

What I've done is do the C News compile and installation on a PDP-11,
then exported the resulting binaries, directories and config files.
Then I wrote some shell scripts to change the configuration for a
new system; you can find these scripts in the [tmp/](tmp) directory.
Finally, I put it all into a tarball, `wktcnews.tar`, which can be
unpacked on a new 2.11BSD system.

## What's in the Tarball

When you unpack `wktcnews.tar` on your 2.11BSD system, this will make:

 + `/etc/news`: The directory that holds the C News configuration files.
 + `/usr/bin`: The C News programs for users go here.
 + `/usr/libexec/news`: Internal C News programs go here.
 + `/usr/local/src/cnews`: The C News source code goes here.
 + `/usr/spool/news`: This directory holds the news articles, as yet
   unprocessed new news and news batches for other systems.
 + `usr/man/cat1`: Man pages for `rn` are added here.

## The Three Scripts

Three scripts will get placed in `/tmp`. You can use `set_hostname` to
set your system's hostname. This will find the default hostname "pdp11"
in `/etc/hosts` and `/etc/netstart`, replace it with the name on the command
line, then run `/etc/netstart` to set the new hostname.

The `config_cnews` script modifies the configuration files in `/etc/news` with
your machine's hostname, then sets up some `cron` entries for the `news`
user. Finally, it unpacks the executables for `rn` and puts them in a
directory for you, either `/usr/local/bin` or `/usr/local`.

The last script, `add_newspeer` adds the details of a peer C News machine
to the configuration files in `/etc/news` and `/etc/uucp`. The IP address
of the machine is added to `/etc/hosts`, and an outgoing news spool
directory is made for this machine in `/usr/spool/news`.

Let's see all of the above in action.

## Doing the Install

I'm assuming that you have a 2.11BSD system already running under
OpenSimH. As this is slightly experimental, I highly recommend that
you __back up__ your existing disk image before you apply the changes
in the `wktcnews.tar` tarball.

For two C News machines to exchange news, at least one of them must
allow incoming TCP connections to the 2.11BSD TCP port 540, as this
is used for UUCP file transfers.

If you want to allow these connections, you will need to add a TCP port
forward command in your OpenSimH "ini" file to allow TCP connections
through to the 2.11BSD TCP port 540. I've included an `example.ini` file
which I've used to test that the C News installation works. The port
forwarding line is this one:

```
att xu nat:tcp=9540:10.0.2.4:540
```

This forwards connection on TCP port 9540 on your real machine to
the 2.11BSD TCP port 540.

The next thing you will need to do with your "ini" file is
to attach the "tap" version of my C News tarball to your
simulated 2.11BSD system:

```
att tq0 wktcnews.tap
```

## Starting up 2.11BSD

You should now be ready to boot your 2.11BSD system
(you _did_ make a disk backup, didn't you?) and log in as `root`.
Once you are logged in, you will need to make the `news` user if they
don't already exist. To do this, use the `vipw` command and add this
to the password file:

```
news:*:67:67::0:0:News System:/etc/news:/bin/csh
```

Then edit the `/etc/group` file and add this:

```
news:*:67:
```

## Unpacking the Tarball

Before you unpack my C News tarball from the simulated tape, you must
set your `umask` to 022:

```
# umask 022
```

If you don't do this, then the installation will __FAIL__ as
several files will get wrong permissions. 

Now unpack the tarball on the tape drive and `cd` into `/tmp`:

```
# tar vxf /dev/rmt0
...
x usr/man/cat1/newsgroups.0, 1357 bytes, 3 tape blocks
x usr/man/cat1/rn.0, 70311 bytes, 138 tape blocks
#
# cd /tmp
```

If you have not yet changed your hostname from its default
(probably _pdp11_), then run the `set_hostname` script:

```
# ./set_hostname gara
About to change hostname to gara in 5 seconds
Assuming NETWORKING system ...
add host gara.home.lan: gateway 127.0.0.1: File exists
add net default: gateway 10.0.2.2: File exists
pool.ntp.org: delay:0.033233 offset:-0.050674  Wed Jun 10 19:15:09 2026
#
```

Now, set a password for the uucp user:

```
# passwd uucp
Changing password for uucp.
New password:
Retype new password:
# 
```

Now you are ready to configure C News for your machine:

```
# ./config_cnews
Unpacking /tmp/local.tar into /usr/local
x newsetup, 3538 bytes, 7 tape blocks
x rn, 124180 bytes, 243 tape blocks
x Pnews, 9866 bytes, 20 tape blocks
x newsgroups, 1385 bytes, 3 tape blocks
x Rnmail, 5626 bytes, 11 tape blocks
#
```

That's it! The script will try to find `/usr/local/bin` before `/usr/local`
for the above binary files.

Now you need to configure one or more remote news peers to connect to.
For each remote peer, you need to know:

 + the peer's news name,
 + the peer's IP address,
 + the TCP port which gets forwarded to the 2.11BSD UUCP port, and
 + the `uucp` password on the peer

Once you have all this information, you can do:

```
# ./add_newspeer munnari 1.2.3.4 8540 uucp1234
Copying ./add_newspeer to /etc/news/bin
Done. If you accept inbound uucp connections, tell the
munnari admin to add your uucp site with their ./add_newspeer script.
At least, tell the munnari admin to add gara to their
/etc/news/sys and /etc/uucp/L.sys files.
```

The `add_newspeer` script gets copied to `/etc/news/bin` so that
you can still run it once the `/tmp` directory gets cleaned out.

## Home Routers and Port Forwarding

It's very likely that you are running your simulated 2.11BSD system on
a machine behind a home router. If you want other C News boxes to be
able to connect to your box, you will need to do some port forwarding
on your home router to make this happen.

I can't tell you how to do this, as each home router does it differently.

However, let's say your 2.11BSD system is running on your Raspberry
Pi. It has the private address 192.168.3.4 and your UUCP `nat` line
(see above) has `tcp=9540` in it.

You would need to tell your home router to forward TCP connections on
port 9540 to local IP address 192.168.3.4 port 9540.

Then you need to tell the other C News machines your 2.11BSD machine's
name, your public IP address, port 9540 and your `uucp` password.

## Testing UUCP

Assuming that you have set your 2.11BSD system up and configured a remote
news peer, you can confirm that UUCP is working to that peer. Let's assume
the peer's name is `munnari`. On your 2.11BSD system, as `root`, you can do:

```
# uucico -r1 -x7 -smunnari
```

This performs a UUCP connection to the `munnari` machine. Your machine
will be the master of the connection (`-r1`) and with a reasonably high
debugging level (`-x7`). You should see something like this:

```
root munnari (6/14-18:38-118) DEBUG (Local Enabled)
finds (munnari) called
getto: call no. munnari for sys munnari
Using TCP to call
bsdtcpopn host munnari, port 8540
login called
wanted "login:"
login:got: that
send "uucp"
wanted "assword:"
 Password:got: that
send "uucp1234"
root munnari (6/14-18:38-118) SUCCEEDED (call to munnari )
TCPIP connection -- ioctl-s disabled
imsg looking for SYNC< \20>
imsg input<Shere=munnari\0>got 13 characters
omsg <Sgara -Q0 -x7>
imsg looking for SYNC<
\20>
imsg input<ROK\0>got 3 characters
msg-ROK
Rmtname munnari, Role MASTER,  Ifn - 5, Loginuser - root
rmesg - 'P' imsg looking for SYNC<\20>
imsg input<Ptg\0>got 3 characters
got Ptg
wmesg 'U' t
omsg <Ut>
Proto started t
protocol t
root munnari (6/14-18:38-118) OK (startup)
*** TOP ***  -  role=MASTER
wmesg 'H' 
rmesg - 'H' got HY
PROCESS: msg - HY
HUP:
wmesg 'H' Y
cntrl - 0
root munnari (6/14-18:38-118) OK (conversation complete)
send OO 0,omsg <OOOOOO>
imsg looking for SYNC<\20>
imsg input<OOOOOO\0>got 6 characters
TCP CLOSE called
closed fd 5
```

If the connection fails, you will need to debug this before you
can proceed to the C News installation. Can you make a Telnet
connection to the news peer using the information provided to you by them?

## Posting Some News

Assuming that you have one or more C News peers ready to accept your
news, it's now time to post some!

Logout as `root` and log back in as an ordinary user. I'm going to
use the `user` account below.

Make sure that your `$EDITOR` environment variable is set to a working
editor, otherwise the news posting software will make you use `ed`.
If your shell is `csh`, do:

```
% setenv EDITOR /usr/ucb/vi
```

If your shell is the Bourne shell, do:

```
$ EDITOR=/usr/ucb/vi; export EDITOR
```

Now run this command and fill in the subject line:

```
$ postnews pidp11.general
Subject: Hello from gara
```

Once you hit _Return_, you will be put into an editor session where you
can write your news article's content. Replace the line that you are
told to replace, and add the content, e.g.

```
Newsgroups: pidp11.general
Subject: Hello from gara

This test message comes from gara.

Cheers, Warren
```

Exit the editor and your article will be saved into the news spool area:

```
$ ls -l /usr/spool/news/in.coming/
total 2
-rw-r--r--  1 news          260 Jun 14 18:51 0.17814882600.t
```

## News Cron Jobs

Logout and log back in as `root`. 

The `news` user has these `cron` jobs:

```
# crontab -l -u news
00,15,30,45 *   1-31 *  0-6     /usr/libexec/news/input/newsrun
40 *            1-31 *  0-6     /usr/libexec/news/batch/sendbatches
59 0            1-31 *  0-6     /usr/libexec/news/expire/doexpire
10 8            1-31 *  0-6     /usr/libexec/news/maint/newsdaily
05,35 * 1-31 *  0-6     /usr/libexec/news/maint/newswatch 3000 300 100
```

The `newsrun` program takes incoming news and moves them into the
per-newsgroup areas in `/usr/spool/news`. The `sendbatches` program
takes any new news and batches it in `/usr/spool/uucp`, ready to send
to your C News peers. Let's run them by hand. Firstly, we are going to
become the `news` user with an `su` command; then we can run the programs:

```
# su - news
% /usr/libexec/news/input/newsrun
% /usr/libexec/news/batch/sendbatches
% <use ctrl-D> to get back to the root shell
#
```

There is a 45 second delay in `newsrun`; you might want to edit that down
to a smaller value like 15 seconds. After the `sendbatches` program finishes,
you should see the batch of news ready to send:

```
# du -a /usr/spool/news
0       /usr/spool/news/out.going/munnari/togo
...
# du -a /usr/spool/uucp
...
1       /usr/spool/uucp/C./C.munnarid3Qh4
```

The `root` user should have a `cron` job for each remote C News peer:

```
# cat /etc/crontab
...
39 * * * *      uucp    /usr/sbin/uucico -r1 -smunnari
```

You could just let this run via `cron`, but of course you can run it by hand:

```
# /usr/sbin/uucico -r1 -x7 -smunnari
...
news munnari (6/14-18:59-437) REQUEST (S D.garaB3Qh2 D.garaS3Qh2 news)
expfile type - 0, wrktype - S
wmesg 'S'  D.garaB3Qh2 D.garaS3Qh2 news - D.garaB3Qh2 0666
...
sent data 284 bytes 0.00 secs
news munnari (6/14-18:59-437) OK (conversation complete)
...
```

Over on `munnari`, once the `newsrun` program gets run, your news article
will become visible to the users there.

## Reading the News

I've added the `rn` program for you to read the news; there is a man
page for it. Logout as `root` and log back in as your user. You can
then read the manpage:

```
$ man rn

RN(1)               UNIX Programmer's Manual                RN(1)

NAME
     rn - new read news program
...
```

Below is an example `rn` session. All I did was hit _Return_ each time I
was prompted.

```
rn
Setting up .newsrc...
Creating .newsrc in /home/user to be used by news programs.
Done.

If you have never used the news system before, you may find the articles
in mod.announce.newuser to be helpful.  There is also a manual entry for rn.

To get rid of newsgroups you aren't interested in, use the 'u' command.
Type h for help at any time while running rn.

New newsgroups:

Add control? [yn] 

Put where? [$^L] 

Add junk? [yn] 

Put where? [$^.L] 

Add news.announce.newusers? [yn] 

Put where? [$^.L] 

Add pidp11.announce? [yn] 

Put where? [$^.L] 

Add pidp11.general? [yn] 

Put where? [$^.L] 

****   1 in pidp11.general--read? [ynq]

Article 1 in pidp11.general:
From: user@gara (Joe User)
Subject: Hello from gara
Message-ID: <tGnH50.5r@gara>
Organization: Sirius Cybernetics, Sirius City branch
Date: Mon, 15 Jun 2026 01:51:00 GMT

This test message comes from gara.

Cheers, Warren

End of article 2 (of 2)--what next? [npq]

End of pidp11.general

**** End--next? [npq] 

**** End--next? [qnp]
```

## Connecting to Munnari

That's about it for the installation of C News on a 2.11BSD system.
I've left a copy of the original "Installing and Operating C News Network
News Software" document in the [Docs](Docs) directory. You can find the
original "troff" version of this on your 2.11BSD system in
`/usr/local/src/cnews/doc`.

I've set up a 2.11BSD C News system, _munnari_, running on an Internet
server. If you want to connect to it, you can use the `add_newspeer`
script to do this:

```
# ./add_newspeer munnari 173.230.156.51 8540 uucp1234
```

I have _munnari_ running behind a firewall, so you will need to e-mail
me your machine's name and your public IP address so that I can let TCP
connections in from your machine. My e-mail address is `wkt` "@" `tuhs.org`.

Note that _munnari_ is __not__ going to make any TCP connections to your
system: you will have to connect to _munnari_. This also means that you
won't need to set up any home router port forwarding.

However, the whole point of C News is that it is a distributed system,
not a hub and spoke system. So I would highly recommend that you work
on building news connections with peers other than _munnari_.
