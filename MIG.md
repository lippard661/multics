# The Multics Informational Guide

### An introduction to Multics by Mark Davis (Explorer Post 414, Phoenix, 1980–1983), edited for the simulator age

> **About this edition.** Mark Davis wrote this guide for new members of
> Explorer Post 414. The post's Multics accounts were under the project
> `Scouting` on Honeywell's System M in Phoenix. His guide survives in three
> printouts kept by Jim Lippard (Lippard.Scouting):
>
> * a 1980 single-document **"Multics Introductory Guide"** (line-printer
>   listing of `>udd>Scouting>MDavis>t>MIG`, printed 3 January 1983, with some
>   pages printed on a terminal-room printer);
> * the 1982–83 **"Multics Informational Guide"** (MIG) series of short numbered
>   guides (listing of `>udd>Scouting>MDavis>t>tutorial`, printed 25 January
>   1983);
> * a later table of contents for the series.
>
> This edition combines the three into one guide, converted from `compose`
> output to Markdown. Where both versions cover the same topic, it uses the
> fuller one and includes anything only the other has. Mark's examples,
> user names and dates are kept as he wrote them. Spelling is corrected, and
> a few sentences are lightly smoothed where the two versions are joined.
>
> Notes marked **Today** were added in 2026 for people meeting Multics on a
> simulator (DPS8M) rather than a 1980s Honeywell mainframe. They were not
> part of Mark's guide. They describe current releases (MR12.x) as best we
> know them (checked against a current system in October 2026).

---

## Contents

1. [Introduction](#1-introduction)
2. [How to read this guide](#2-how-to-read-this-guide)
3. [Common Multics concepts](#3-common-multics-concepts)
4. [Accessing Multics](#4-accessing-multics)
5. [Getting started](#5-getting-started)
6. [The mail system](#6-the-mail-system)
7. [Getting help](#7-getting-help)
8. [Abbreviations](#8-abbreviations)
9. [Start_ups](#9-start_ups)
10. [The ted editor](#10-the-ted-editor)
11. [Other commands](#11-other-commands)
12. [Where the MIG was headed](#12-where-the-mig-was-headed)
13. [Sources and editorial notes](#13-sources-and-editorial-notes)

---

## 1. Introduction

This series of informational guides to the Multics system was put together
by Mark Davis with help from various Multics users. It is for new Post
members who know a little about computers but do not know how to use
Multics.

It is recommended that you read this entire guide first, and then review it
during a session on the terminal, trying each command and observing the
results. Please be sure to read the guide once thoroughly before attempting
access to Multics.

> **Today:** "The terminal" is now a telnet session to a Multics running under
> the DPS8M simulator, either one you run yourself or a public system that
> gives out accounts. Everything in this guide can still be tried there.

## 2. How to read this guide

### Special MIG notation: the bang (!)

As an aid to understanding Multics, a special way of distinguishing user
input from Multics output (what you type as opposed to what the computer
prints out) was developed. It is used most often in tutorial guides like
this one, and to describe test cases when reporting problems with the
system.

The notation has only one character, the exclamation point (`!`). When an
exchange between user and computer is shown, the exclamation point (also
called a "bang") is placed in front of user input. Lines without a bang are
what the computer printed on its own.

For example, suppose these five commands

    alpha       beta       gamma       delta       epsilon

each print the Latin-alphabet letter for the Greek word (alpha=A, beta=B,
gamma=C, delta=D, epsilon=E) ten times. Then:

    ! alpha
    AAAAAAAAAA
    ! beta
    BBBBBBBBBB
    ! delta
    DDDDDDDDDD
    ! gamma
    CCCCCCCCCC
    ! epsilon
    EEEEEEEEEE

From that you can tell that the user typed "alpha," then "beta," then
"delta," then "gamma," and then "epsilon," and the computer printed the
proper response below each command. So if you saw this:

    What is your name?  !  Claw
    Hello Claw!

you would know that the only thing the user typed was "Claw". Never type
the bang itself.

### Braces

In command descriptions, words in braces stand for something you supply.
`sm {Person}.{Project} {message}` means you type `sm`, then a user id, then
your message, without the braces.

### Control arguments

A typical guide is centered on one major topic. Related information usually
comes in the form of **control arguments**. A control argument (also
written "ctl_arg") is something you add to the end of a Multics command to
change the way it works.

A control argument is very similar to an ice cream sundae. You start with a
scoop of ice cream. If you add chocolate syrup, the taste changes. If you
add whipped cream, the taste changes. And if you combine the two, the taste
is different still. Control arguments work the same way: every ctl_arg you
add changes the way the basic command works. Once you learn the typical
ones, you can tailor each command to fit your needs.

To show how this guide describes control arguments, here is a pretend
command called `sandwich`, which makes imaginary sandwich recipes. Typed by
itself, it simply puts two slices of plain white bread on a plate. That's
not an exciting sandwich, so we'll change it with control arguments. They
are described like this:

    -bread bread_type
         Changes the sandwich bread to bread_type.
    -cheese_on
         Specifies that the sandwich should have cheese on it.
    -cheese_off
         Specifies that the sandwich should not have cheese on it. (Default)

`-bread` is the control argument; `bread_type` is an **additional
argument**, which goes right after it. "Default" means the mode assumed if
no instructions are given. It's like a light switch in your home: it's
usually off unless you turn it on. For `-bread`, the default is plain white
bread.

At command level you would type:

    sandwich -bread pumpernickel -cheese_on

and get a cheese sandwich on pumpernickel. To change only the bread, leave
out `-cheese_on`. One common mistake is forgetting the additional argument,
so don't forget to supply it!

---

## 3. Common Multics concepts

### Person.Project

Person.Project is the name of an ID on the system. It is sometimes called a
userid, account number or charge number, but mostly an ID. An ID has two
parts, a **Person_id** and a **Project_id**. Together they name a single
unique ID on the system. Some examples:

    Carlin.VidTech                     JDoe.Commute
    Cheetah.SYSJump                    SctAdmin.Scouting

Each consists of a Person_id (Carlin, Cheetah, JDoe, SctAdmin), a period
(sometimes called a dot), and a Project_id (VidTech, SYSJump, Commute,
Scouting). Usually the Person_id comes from the user's name ("Carlin" could
be Albert Carlin). "SctAdmin," however, is probably not a person's name but
a position or job on the system. The Project_id is most often the name of a
group the user belongs to, such as a work group or a club.

To create a Person_id, the System Administrator (SA) tries to make a unique
name from yours. It can be just your last name, but usually it combines
your initials and last name. If your name is Richard Matthew Caldwell, the
SA could create any of these:

    Caldwell             RCaldwell             RMCaldwell

He probably won't choose the first, because there may be another Caldwell
on the system. For the Scouting Post, the name with all three initials and
the full last name was usually chosen, so Richard's Person_id would be
"RMCaldwell."

The Project_id for a group is also chosen by the SA, after talking it over
with a person in charge of the group. A few years earlier, one of the Post's
advisors and the System Administrator came up with "Scouting" for the Post.
Combining the two gives:

    RMCaldwell.Scouting

What does this relationship mean? RMCaldwell is a small part of the large
group called Scouting, and Scouting is a small part of the vast group
called Multics. Another way to put it:

> Multics is a continent, Scouting is one country on that continent, and
> RMCaldwell is one state in that country.

(This picture comes back later, when we talk about directories.) Asked for
his person_id, Richard would say "RMCaldwell"; for his project_id,
"Scouting"; for his userid, "RMCaldwell.Scouting," pronounced "RMCaldwell
dot Scouting."

Throughout this guide the examples use ids such as **Bengal.Scouting**,
**Cheetah.Scouting** and **Panther.Scouting**. When you are told to use your
person_id, use the name you were actually given.

> **Today:** On a hobbyist system your project is whatever the administrator
> set up (often a general project for public users). If you run your own
> simulator, *you* are the System Administrator and choose the names
> yourself.

### Carriage return and linefeed

To send a command to the computer, you hit the Return key. On Multics,
though, Return sometimes isn't as quick as a different key, the
**Linefeed** (LF) key. Multics prefers linefeeds in some cases and returns
in others. Use Return first, and if nothing happens, try LF once. One place
LF works faster is when logging in; in a few subsystems, Return works
better. You'll get used to these situations.

> **Today:** Modern keyboards have no Linefeed key. Ctrl-J sends a linefeed
> if you ever need one; over telnet, Return almost always works.

### Uppercase and lowercase

On most microcomputers of the day, uppercase letters were used. On Multics,
lowercase letters are used. You can type capitals, but most commands work
only in lowercase. **Case matters.** Uppercase is used mostly in person_ids
and project_ids, and in the names of files and other things on the system.

### Breaks, quits and interruptions

If you start something you don't want to finish, such as a large printout or
listing, you can usually stop it with the key marked **Break** (sometimes
Interrupt or Quit). The word `QUIT` appears and you are returned to command
level. Depending on what you were doing, you can often get back to it:

* If you were running a BASIC program, type `start` (or `sr`) to carry on
  practically where you left off.
* If you were in a **subsystem** (a command that accepts its own commands,
  such as send_mail), type `program_interrupt` (or `pi`) to get back to
  where you were.

Each Break also raises your "level," which shows in the ready message; see
`general_ready` and `release` in [§11](#general_ready-gr).

> **Today:** There's no Break key on a telnet session. DPS8M treats the
> telnet BREAK command as a quit: in most telnet clients, press the escape
> character (usually Ctrl-]) and type `send brk`.

### Mistakes and typos

There is no such thing as a perfect typist. Line noise can also put stray
"static" characters on the terminal. Either way, Multics gives you two
special characters for corrections:

| Character | Effect |
|---|---|
| `#` (number sign, pound sign) | deletes the character immediately to its left |
| `@` (at sign) | deletes everything to its left, back to the beginning of the line |

Suppose I want to say "foobar" but type `foobairr`. To delete "airr" and
replace it with "ar":

    foobair###r

which is read as "foobar." If I decide not to type it at all:

    foobair###r@

and the whole line, from the `@` back to the "f," is deleted.

A longer example: I meant "Hello everybody." but typed `Hello evertbody.`
Five `#`s delete the period, y, d, o and b, and a sixth deletes the t. Then
I retype the rest:

    Hello evertbody.######ybody.

and the line reads "Hello everybody." If I then decide I have no reason to
type it at all:

    Hello evertbody.######ybody.@

and the line is gone.

> **Today:** `#` and `@` still work exactly this way on a plain telnet
> connection. Your terminal's Backspace may only move the cursor or print a
> control character. If you want modern in-line editing, the video system
> (`window_call invoke`) gives you an Emacs-style line editor.

### A short glossary

Mark planned a glossary (MIG 3c) but listed only the terms. Brief
definitions are supplied here (2026):

| Term | Meaning |
|---|---|
| absentee | a job run in the background, with no terminal attached |
| banner | the greeting Multics prints when you connect (see §4) |
| coupler | the acoustic modem a telephone handset was pushed into |
| crash | an unplanned stop of the whole system |
| default | what a command does when you don't tell it otherwise |
| directory | a container of segments, links and other directories (§11) |
| dprint | the command to print a file on the line printer |
| login | starting a session on Multics (§4) |
| obsolete | a command still present but replaced by a newer one |
| person_id | the first half of your user id |
| process | your running session: everything Multics is doing for you |
| project_id | the second half of your user id |
| segment | a Multics file |
| syntax | the form in which a command must be typed |
| terminal | the device you type on: a printing terminal or a video display |

---

## 4. Accessing Multics

### Logging in

To use Multics you must **log in**. This is the first thing a Multics user
must know how to do. In 1980 there were ten steps:

1. **Turn on the terminal and acoustic coupler.** The terminal's switch is
   usually on the back, the coupler's on the front. Make sure the terminal
   is in "line" mode, not "local," or it cannot talk to Multics.
2. **Dial 249-7501.** This was Multics' main line, a rotary: if the number
   was busy, it switched you to another. `help phones` listed others.
3. **Put the receiver into the coupler**, cord at the correct end. In a few
   seconds the carrier light should come on, meaning Multics has answered.
   If it doesn't, you may have dialed wrong, the line may be busy, or
   Multics may be down. Redial.
4. *(Optional.)* Type two spaces and `tXXXX`, where XXXX is up to four
   characters to identify your terminal (initials, your name, an
   abbreviation of your city; profanity not allowed). This is your
   **terminal_id**.
5. **Hit LF.** Multics greets you with a two- or three-line **banner**:

        System will shut down for two hours at 2200 for Hardware Testing.
        Multics MR10.0: Honeywell LISD Phoenix, System M
        Load 38.0 out of 125.0 units; users = 31, 07/04/80  1926.3 mst Tue

   * The first line is the **login message**, telling you of the system
     status. It isn't always present.
   * **Multics** is the system's name: "MULTiplexed Information and
     Computing Service."
   * **MR10.0** is the Multics Release number.
   * **Honeywell LISD Phoenix, System M**: the company and its Large
     Information Systems Division, the city, and the name given to the
     system.
   * **Load 38.0 out of 125.0 units**: how much of the system's maximum load
     is in use. It's high in prime shift (midday), low at other times.
   * **users = 31**: how many people are using the system.
   * **07/04/80 1926.3 mst Tue**: the date and time.

     | Part | Meaning |
     |---|---|
     | `07/04/80` | month, day, year: July 4th, 1980 |
     | `1926.3` | 19:26 (7:26 pm) plus tenths of a minute (.3 = 18 seconds) |
     | `mst` | Mountain Standard Time |
     | `Tue` | the day of the week |

6. *(Optional.)* **Set your terminal type**, if you know it:

        ttp VIP7801

7. **Log in.** Type this, replacing Cheetah with your person_id:

        login Cheetah

   (`l Cheetah` works too.)
8. Multics responds:

        Password:

   followed by a **mask**: three strings of letters typed on top of each
   other, so that nobody reading your printout can see your password. (The
   mask isn't always present.)
9. **Type your password.** The first time, use the one the advisor gave you.
   First passwords were often guessable, so change yours right away (see
   below).
10. Multics responds with up to three lines:

        You are protected from preemption until 1956.
        Cheetah Scouting logged in 07/04/80  1926.8 mst Tue from VIP7801 terminal "Leo2".
        Last login 07/02/80  1234.5 mst Sun from ROSY terminal "Lion".

    The first means that if the system suddenly fills up, you can't be
    "preempted" (bumped off) until 7:56 pm. The second says who logged in,
    when, and from what terminal. The third, absent on your very first login,
    says when and from where you last logged in.

And now you are officially logged in to Multics. Be sure to save the
hardcopy of your first login: it is rather sentimental to many.

> **Today:** Steps 1–4 become one: `telnet` to the simulator's host and
> terminal port (usually 6180, the standard DPS8M terminal port). You'll see the banner, then type `l Person` (or
> `l Person Project` if you have more than one project) and your password.
> The banner now names the release (MR12.x) and your site. Step 6 still
> applies: `help set_tty` explains terminal types, and your administrator
> can tell you which suits a modern terminal emulator.

### Logging out

To log out, type `logout` at command level. Multics says something like:

    ! logout
    Personid.Projectid logged out 07/04/82  1234.5 mst Tue
    CPU Usage 248.8 sec, memory usage 38 units, cost $2.28.
    hangup

Control arguments change this:

| Command | Effect |
|---|---|
| `logout -hd` | "hold": log out, then print the greeting banner again, so someone else can log in without redialing |
| `logout -bf` | "brief": don't print the logout information; just "hangup" |
| `logout -bf -hd` | print nothing; skip a line and wait for the next login |

### Changing your password

To change your password you must log in again. Suppose Tigerone.Scouting
must change his password because he told his girlfriend and she blabbed it
to his Multics-using friends. His password is "copper," and he wants
"zinc." If he's on Multics, he types `logout -hd` to get the banner back.
Then he adds the `-cpw` (Change PassWord) control argument to the login
command:

    ! login Tigerone -cpw
    Password:
    ! copper
    New Password:
    ! zinc
    New Password Again:
    ! zinc
    Password changed.

and login continues normally. "New Password Again" is a safety check: if the
two don't match, the password is not changed.

Now, if you are as foolish as Tigerone and tell someone your password, you
take the risk that they, or someone they tell, will log in as you. Change
your password whenever you know someone knows it, and remember it: getting
it back is very bothersome to System Maintenance people. So don't forget it,
and don't let anyone else know it.

---

## 5. Getting started

When Multics prints something like

    r 19:15 4.439 204

it is ready for your next command. This is the **ready message**. If you
don't like the "meaningless numbers," you can change it with the
`general_ready` command ([§11](#general_ready-gr)).

> **Today:** The numbers are the time of day, the CPU seconds used since the
> last ready message, and the number of page faults. They mean something
> after all.

Your new id may already have some things in it. Look through these files
and decide whether to dispose of them or hang on to them.

---

## 6. The mail system

### Introduction

Probably the most important single subsystem on Multics is the **mail
system**, a way of communicating between two places, whether a few feet
apart (as in the terminal room) or a few thousand miles apart.

Multics mail is very like the post office. You write something on a piece of
paper, seal it in an envelope, address it, and put it in your mailbox. A
postman takes it and delivers it, and the addressee opens and reads it.

On Multics, you invoke the mail-sending command, `send_mail` (or `sdm`), and
tell it what your letter is about, who it's to, and what it says. You, the
**sender**, send it to the **recipient**, who reads it with the mail-reading
command, `read_mail` (or `rdm`). He may then reply to it, get rid of it, or
save it in a file.

### Messages and mail

There are two kinds of communication:

* **Mail** is the preferred way of communicating. It is used for formal
  communications, informational briefings, and anything more convenient to
  receive all at once.
* **Messages** are for chats, or simple questions like "What time are you
  leaving?" or "Did you finish that program?" They are most often used to
  talk to someone who is on Multics at the moment, while mail reaches people
  whether or not they are logged in.

Mail is preferred because, in the long run, it is easier to read and
process. Messages are short and simple, but cumbersome when important
information is concerned.

### Mailboxes

To send and receive mail you need a special segment (Multics' word for a
file) called a **mailbox**. When you send mail or messages, you actually
send them to a mailbox, and the person who owns it reads what you put
there.

Mailboxes are unlike any other segment. You can't access them like a normal
segment, and they have their own kind of access control (see [Mailbox
access](#mailbox-access) below).

In 1980, a new user created a mailbox by typing:

    ml

which created the mailbox (if there wasn't one already) and said you had no
mail.

> **Today:** `accept_messages` (below) creates your default mailbox,
> `>udd>Project>Person>Person.mbx`, if you don't have one, so `ml` is no
> longer needed for that. `mail` still exists, alongside the newer
> `print_mail` (prm) and `read_mail` (rdm).

Two commands control whether you are told about arriving messages:

* `accept_messages` (`am`) accepts messages into your mailbox and tells you
  about them as soon as they arrive. The receiver must have typed `am`, or he
  will not be informed of your message when it arrives. `am -sh -hd`
  (short format, and hold the setting) is a common form.
* `defer_messages` (`dm`) stops Multics from notifying you. Mail still goes
  into your mailbox; dm simply reverses am. It has no arguments. Use it
  only when you don't wish to be disturbed, and don't forget to turn
  messages back on with `am`, or you'll miss important or urgent
  notifications.

### Sending mail (send_mail, sdm)

`send_mail` (`sdm`) sends mail to one user, ten users or a hundred users.
Your mail can be one line or a hundred. And you can spend one minute sending
it, or ten hours, depending on how well you understand the command.

When you type `send_mail`, Multics asks for a **subject**:

    ! send_mail
    Subject:

Use a subject that describes your topic distinctly. If you're writing about
something stupid your cat did today, `My Cat` could cover anything;
`My Stupid Cat` is better. Many beginners get so stuck on being explicit
that they type their whole message as the subject! Don't: it tells every
experienced Multics user that you don't know what you're doing.

Next send_mail says `Message:` and waits on the next line for your text.
When you are done, type a **period alone on a line**:

    ! sdm
      Subject:  !My Stupid Cat
      Message:
    ! You're not going to believe this, but today, my cat was
    ! running down the hall, and he rounded a corner and slammed
    ! right into the arcadia door.  It was so funny, he just
    ! hit his face dead center in the middle of the glass door.
    ! Boy, he's so stupid.
    ! .
      send_mail (send):  No destinations specified for this message.

This error may be frightening, but it's simple. "send_mail (send)" before
the colon says you were using the `send` request inside the send_mail
subsystem. The sentence after the colon says what went wrong: you didn't
say where to deliver the mail. You'll see this format in a great many
Multics error messages.

send_mail now waits for requests at its **prompt**:

    send_mail:

(At command level the prompt is invisible: Multics just stops and waits.)
Use the `to` request to address the mail, here to Furrball.SysAdmin:

    send_mail:  !to Furrball.SysAdmin

Use `print` to see what the recipient will get:

    send_mail:  !print
    (5 lines in text):
    Subject:  My Stupid Cat
    To:  Furrball.SysAdmin

    You're not going to believe this, but today, my cat was
    ...
    send_mail:

The period that ended your text doesn't appear: it only told send_mail you
were done. Requests take control arguments too. `print -header` (`-he`)
also shows the date and your user id:

    send_mail:  !print -he
    (5 lines in text):
    Date:  4 July 1980 12:34 mst
    From:  Yourname.HERE
    Subject:  My Stupid Cat
    To:  Furrball.SysAdmin
    ...

Finally, deliver it with `send`:

    send_mail:  !send
    Mail delivered to Furrball.SysAdmin.

The earlier error mentioned "send" because send_mail tries to send as soon
as you finish the text. So give the address on the command line and it
will:

    ! send_mail Furrball.SysAdmin
      Subject:  !My Stupid Cat
      Message:
    ! You're not going to believe this, ...
    ! Boy, he's so stupid.
    ! .
      Mail delivered to Furrball.SysAdmin.

> **Today:** `quit` (`q`) leaves send_mail without sending. Typing `?` at
> the `send_mail:` prompt lists all its requests.

### Sending messages (send_message, sm)

The other way of communicating is `send_message`, or its shorter name (an
**add_name**) `sm`. Suppose it's Monday, July 4th, 1983, 8:45 pm. You are
Bengal.Scouting and want to tell Panther.Scouting "I am hungry.":

    ! send_message Panther.Scouting
      Input:
    ! I am hungry.
    ! .

Panther suddenly receives this at his terminal:

    Message from Bengal.Scouting 07/04/83  2045.4 mst Mon:
    I am hungry.

The header gives who sent it, then the date, time, time zone and day
(MM/DD/YY hhmm.s zzz ddd). For a one-line message you can skip the `Input:`
step and put the message on the command line:

    sm Panther.Scouting How are you?

### Reading mail

*(Mark's 1980 version had a page here that has not survived; his 1983 guides
on reading mail and messages, MIG 5f and 5g, were planned but not yet in the
printout.)*

If you just type `mail` at command level, all the mail in your mailbox is
printed, and then it asks `mail: Delete?` and waits for your answer. If
there's nothing there, it says `No mail.`

The `read_mail` (`rdm`) command lets you process each message in your
mailbox one at a time, individually, typing requests that tell the computer
what to do with each one. You can print, delete, reply to, or even forward
the message to someone else, each with a single request. For more
information on read_mail, type a question mark at its prompt, just as in
send_mail.

> **Today:** `mail` and `read_mail` still work as described. `print_mail`
> (`prm`) is a newer command that prints your mail and offers to delete it.

### Mailbox access

There are seven kinds of access you can set on a mailbox. You set it with
the `mbx_set_acl` command (`mbsa`); ACL stands for **Access Control List**.

| Mode | Name | Meaning |
|---|---|---|
| a | add | process can add a message |
| d | delete | process can delete a message |
| r | read | process can read any message |
| o | own | process can read or delete its own messages |
| s | status | process can find out how many messages are in the segment |
| w | wakeup | process can send a normal-priority wakeup (notify you) |
| n | null | process cannot access the segment in any way |

The default extended access for a mailbox is:

    adrosw         User.*
    aow            *.SysDaemon.*
    aow            *.*.*

That is, the owner can do everything, and everyone else can add messages,
see their own, and wake the owner up. (Access names are explained in
[§11](#set_acl-sa).)

---

## 7. Getting help

There are many other message-system commands. If you're not sure of a
command's name, type `list_help` (or `lh`) followed by a topic, and it lists
the information segments ("info segs") whose names contain those
characters:

    list_help foo

lists every info seg with "foo" in its name. Whenever you need information
on a subject, type `help {topic}`. To learn about help itself, type `help`
or `help help`.

---

## 8. Abbreviations

Abbreviations are about as simple as they sound. If a command is long and
you don't want to type it every time, you can assign a short string of
characters to it, and from then on the system interprets those characters as
the long command.

Bengal.Scouting doesn't want to type "Panther.Scouting" every time he sends
him mail, so he assigns "pnth" to it:

    .a {what you want it to be} {what it is}
    .a pnth Panther.Scouting

From now on he just types:

    sm pnth {message}

It's as simple as that. (Abbreviations must be turned on first by typing
`ab`, short for `abbrev`; see the start_up in [§9](#9-start_ups).)

All abbreviation-related requests start with a dot:

| Request | Effect |
|---|---|
| `.a {abbrev} {expansion}` | add an abbreviation |
| `.ab {abbrev} {expansion}` | add one that expands only at the beginning of a line |
| `.l` | list all abbreviations |
| `.la {letter}` | list all abbreviations starting with {letter} |
| `.l {abbrev}` | list the abbreviation {abbrev} |
| `.d {abbrev}` | delete an abbreviation |

### A pitfall, and .ab

Suppose Bengal makes this abbreviation, so he can type "foot" to accept
messages:

    .a foot am -sh -hd

Later he sends Panther a message:

    sm pnth My foot hurts.

and Panther receives:

    Message from Bengal.Scouting 03/27/83  1506.7 mst Sat:
    My am -sh -hd hurts.

An abbreviation is expanded **wherever** it is typed. To avoid this, add it
with `.ab` instead:

    .ab foot am -sh -hd

This means "add an abbreviation, and make sure it is only expanded at the
**B**eginning of a line or after a semicolon." A semicolon works like a new
line, so you can put several commands on one line:

    foot;ml

Now `.l` shows:

    b foot        am -sh -hd
      pnth        Panther.Scouting

The "b" means foot is expanded only at the beginning of a line or after a
semicolon. If Bengal no longer wants pnth:

    .d pnth

and it's deleted in a snap.

---

## 9. Start_ups

Every time you log in, it's a bother to type accept_messages, mail, abbrev,
and everything else you want. Instead, you can write a **start_up**, a
program that runs every time you log in. (When you first logged in, the
system ran its own standard start_up, which printed the information you
saw.)

A start_up is usually written in **exec_com** ("ec"), a language of commands
that does whatever it is told. Here is a start_up Bengal might use, with an
explanation of each line:

| Line | What it does |
|---|---|
| `&command_line off` | Don't print each command before running it. (The default is "on.") |
| `ab` | No `&` in front, so it's an ordinary command: it turns on abbrev. |
| `am -sh -hd` | An ordinary command: accept messages. |
| `&if [have_mail] &then &goto have &else &goto none` | Just as it sounds: if there is mail, go to the line labelled "have"; otherwise to "none". The brackets mark an **active function**, a command that returns a value. |
| `&label have` | The line marked "have". |
| `mail` | An ordinary command: print your mail. |
| `&label none` | The line marked "none". |
| `gr -string Ready: -tm -set` | Set the ready message, so it prints like `Ready: 1503.6` (the time). See `general_ready` in [§11](#general_ready-gr). |
| `&quit` | Stop. |

Without the explanations, the file `start_up.ec` reads:

    &command_line off
    ab
    am -sh -hd
    &if [have_mail] &then &goto have &else &goto none
    &label have
    mail
    &label none
    gr -string Ready: -tm -set
    &quit

To create one, you need an **editor**: the next section shows how, using
this start_up as the example.

> **Today:** Multics still runs `start_up.ec` from your home directory at
> login (`login Person -no_start_up` skips it). This old-style exec_com
> still works, and so does every command in Bengal's start_up, including
> `mail` and `general_ready`.

---

## 10. The ted editor

An editor is a program for entering text into the computer. Many are
available, such as emacs, teco, qedx, edm and a few others. Here you'll
learn the editor called **ted**. Ted is a simple editor, with a handful of
commands you'll use over and over.

> **Today:** ted is still installed on current Multics, alongside emacs
> and qedx, so this lesson works as written. Its basic requests (`a`, `i`,
> `p`, `s`, `d`, `w`, `r`, `q` and `\f`) are much the same in qedx.

### Starting out

To invoke ted, type at command level:

    ted

The terminal just sits there, which means ted is ready for you.

You start out in what's called a **buffer**, a large series of empty lines.
The buffer stays empty until you type something into it. Since it's empty,
the current line is both the first line and the last line, so you can't
insert before it; you can only append after it.

### Entering text: a and \f

To start entering text, type:

    a

This stands for **append**: put text After the current line. Now type in the
start_up from [§9](#9-start_ups) (the plain version, without explanations or
blank lines). If you make a mistake and don't notice until after you've hit
Return, don't worry: ted has a correction system of its own. At the very
end, after the `&quit` line, add the line:

    Danny eats paper clips.

To leave text-entry mode, type:

    \f

### Printing and substituting: p, ., s

You're now at ted command level, on the last line. Type `p` (**print**) to
print the current line:

    Danny eats paper clips.

Typing a dot (`.`) also prints the current line. To change "paper clips" to
"lead pencils", type:

    s/paper clips/lead pencils/

which means "substitute, on this line, 'lead pencils' for every occurrence
of 'paper clips'." The slashes separate the two **fields** of the
substitute request. A field is a part of what you type that can contain
different characters. Here the fields are "paper clips" and "lead pencils."
The slashes around them are called **delimiters**. The `s` isn't a field,
because nothing else can go in its place.

Type `p` again:

    Danny eats lead pencils.

To get rid of "lead":

    s/lead pencils/pencils/

and `p` prints:

    Danny eats pencils.

### Line numbers: P and =

To see the line number along with the line, type a capital `P`:

       10   Danny eats pencils.

10 is the number of the line you're on.

### Inserting: i

To insert a line **before** "Danny eats pencils.", type:

    i

and you're back in text-entry mode. The `i` stands for insert, or In front
of. Type the line:

    Guess what?

then `\f`. Now the current line is "Guess what?".

### Searching: /string/

To go back to the "Danny eats pencils." line, type:

    /Danny/

This is the **search** request. It looks from the current line for the first
line containing the string between the slashes, and prints it:

    Danny eats pencils.

To go back to "Guess what?":

    /Guess/

### Deleting and moving by number: d, =, N, $

"Guess what?" has nothing to do with your start_up, so delete it:

    d

This deletes the current line and moves the **pointer** (the current-line
marker) to the line after it, so the current line is "Danny eats pencils."
again. Now type:

    =

This prints `9`, the number of the line you're on. Type `1` and ted prints
the first line, `&command_line off`. Type `9` and it prints `Danny eats
pencils.`

Type `3` to go to the third line. Type `$` to go to the last line: `$` always
means the last line of the buffer. Now type `d`. You have just deleted the
last line, "Danny eats pencils."

### Ranges: N1,N2

Now type:

    1,$p

This prints the entire file, from line 1 to `$`, the last line. The comma
joins the two line numbers into a range: "from line 1 to the last line,
execute the request `p`." Likewise, `4,7d` would delete lines four through
seven, and

    1,$s/foo/bar/

would substitute "bar" for "foo" from the first line to the last. Since
there is no "foo" in this file, ted says `Substitute failed.`

### Moving relatively: +N, .N, -N

Type `4` to go to the fourth line. Then:

    +1

moves you one line ahead, to the fifth. `.1` does the same. `-1` puts you back
at the fourth line. `+20` and `-20` move you twenty lines forward or back.

### The global requests: gP, g=, gd

Now suppose you made a mistake: you typed

    am -sh -hn

instead of

    am -sh -hd

and you don't know which line it's on. You could search for it, but here's
something new: the **global** request. It prints, deletes, or gives the line
numbers of every line containing a string. To print every line containing
"am -", with its line number, type:

    gP/am -/

This means: "`g` means global, so look through the whole file and do the
request right after the g. That's a `P`, so print, with line numbers, every
line containing the string between the `/` delimiters, `am -`." The
terminal prints:

       3   am -sh -hn

Now type

    3s/hn/hd/p

which changes "hn" to "hd" and prints the fixed line. This is really three
requests run together, `3`, `s/hn/hd/` and `p`, and they still work.

To print just the line numbers of every line containing "ma":

    g=/ma/

and to delete every line containing "qwerty":

    gd/qwerty/

The terminal just skips to the next line, meaning it has done what you told
it. Since there are no lines with "qwerty" in this buffer, it did nothing.

### Writing, reading and quitting: w, r, q

By now you're probably tired of playing with the file, so type:

    w start_up.ec

This **writes** the buffer to the pathname (file name) `start_up.ec`. From
now on, when you log in, Multics runs start_up.ec. The `.ec` suffix says
what language the file is in. Whenever you save a new file, give it the
suffix of its language, as in `start_up.ec`.

If you later find that your start_up is goofed up, type `ted` again, and
then:

    r start_up.ec

This **reads** the file into the buffer, and the pointer is put on the last
line. When you're done editing, type just `w` to save it again. A plain `w`
writes to the **trusted pathname**, the last path you named with `r` or
`w`. Finally, type `q` to **quit**.

### Review of ted requests

N stands for a number.

| Request | Effect |
|---|---|
| `.` | print the current line |
| `p` | print the current line |
| `P` | print the current line number and the line |
| `N` | go to line N |
| `+N` or `.N` | move forward N lines |
| `-N` | move backward N lines |
| `$` | go to the last line |
| `=` | print the line number of the current line |
| `a` | append the text that follows after the current line |
| `i` | insert the text that follows in front of the current line |
| `\f` | leave text-entry mode (`a` or `i`) |
| `d` | delete the current line |
| `s/a/b/` | substitute string b for every occurrence of string a on this line |
| `N1,N2{request}` | do {request} on lines N1 through N2 |
| `/STR/` | search for and print the next line containing STR |
| `gP/STR/` | print every line in the buffer containing STR, with line numbers |
| `g=/STR/` | print the line numbers of every line containing STR |
| `gd/STR/` | delete every line containing STR |
| `r {pathname}` | read the contents of {pathname} into the buffer |
| `w {pathname}` | write the buffer to {pathname} |
| `w` | write the buffer to the last-named path |
| `q` | quit the editor |

There are other ted requests, but most are too complicated or confusing to
explain now. For more help on ted, type:

    help ted

---

## 11. Other commands

Now we get into the commands of the system. There are many, so they can't
all be covered here, but this guide covers the important ones. Each is
described like this:

    {command}, {shorter name}            {syntax}
              {brief summary}

**Syntax** is how a command is used at command level. Usually it's:

    {command} {arguments} {control_arguments} {optional_arguments}

To get more information on any command, type `help {the command}`.

### list, ls

    ls {optional_names} {ctl_args}

The list command lists the files in your directory. Give file names to list
only certain files. Control arguments `-directories` and `-links` list only
directories or only links. `ls -all` lists segments, directories and links
all at once. A listing looks like this:

    Segments = 4, Lengths = 4

    rew  1  start_up.ec
    r w  2  Bengal.profile
         0  Bengal.mbx
    r w  1  Bengal.memo

"Segments" is how many files there are. "Lengths" is the total of the
numbers in the second column, which give how many pages (units of storage)
each file takes up. Then comes the file's name. On the far left are from
zero to three letters, r, e or w: your **access** to the file.

### Access

Each file has a set of instructions saying who gets what kind of permission
to use it. This is the **access control list**, ACL (pronounced
"ack-uhl"). You can set the ACL for particular ids on the system. (There are
two other parts of Multics access, AIM and ring brackets, which you'll come
to understand as you learn more.) The ACL modes for a segment are:

| Mode | Name | Meaning |
|---|---|---|
| r | read | the person can examine the contents of the file |
| e | execute | the person can run the contents of the file |
| w | write | the person can modify the contents of the file in any way |

There's no access shown for `Bengal.mbx` because a mailbox is a special
file: it has its own kind of access list (see [Mailbox
access](#mailbox-access)).

### set_acl, sa

    sa {path} {modes} {Person.Project}

set_acl changes the ACL of a pathname. (A **pathname** is the full
"address" of a file; see cwd below.) To give Cheetah.Scouting read, execute
and write permission on a file called "foobar":

    sa foobar rew Cheetah.Scouting

Now Cheetah can do anything he wants to the contents of that file. To give
Panther.Scouting read access:

    sa foobar r Panther.Scouting

To give everyone on Multics read access:

    sa foobar r *.*.*

`*.*.*` is the **access name** of the recipient. The first `*` stands for
the Person_id: `*` means all Person_ids. The second is the Project_id: all
projects. The third is a **tag**, which is rarely important. Some
combinations:

| Access recipient | Access name |
|---|---|
| all ids on the system | `*.*.*` |
| all ids with Person_id Bengal | `Bengal.*.*` |
| all of Scouting | `*.Scouting.*` |
| Panther.Scouting | `Panther.Scouting.*` |

> **Today:** The tag tells what kind of process is involved: `a` for an
> interactive user, `m` for an absentee job, `z` for a system daemon. `*`
> covers them all. `list_acl` (`la`) shows an ACL and `delete_acl` (`da`)
> removes entries; these were planned as MIG 6f.

### change_working_directory, cwd

    cwd {directory}

cwd lets you change the area you're working in. A **directory** is where
segments are kept. Recall the picture: Multics is a continent, Scouting is a
country on that continent, and Bengal is a state in that country. Panther
and Cheetah are also states in that country.

Here is how you specify where you want to go (the address). When you log
in, you are in your state. If your name is Bengal, the true address of your
directory is:

    >user_dir_dir>Scouting>Bengal

The greater-than signs (`>`) mean that Bengal is "in" Scouting, which is
"in" user_dir_dir, a region on the continent. So, to go to Panther's
directory:

    cwd >user_dir_dir>Scouting>Panther

To Cheetah's:

    cwd >user_dir_dir>Scouting>Cheetah

And back to yours:

    cwd >user_dir_dir>Scouting>Bengal

Now for the shortcuts. Bengal and Cheetah are at the same level, two states
in one country, so from Bengal's directory you can just say:

    cwd <Cheetah

The `<` means "go up one level, then down into Cheetah". From there,
`cwd <Panther` takes you to Panther's.

And the best shortcut: when you log in, Multics puts you in your own
directory and makes it your **default** (home) directory. Typing `cwd`
alone takes you back there.

Another shortcut: some directories have shorter names added to them.
Scouting also has the name `sct`, and user_dir_dir has `udd`. So instead of

    cwd >user_dir_dir>Scouting>Panther

you can say

    cwd >udd>sct>Panther

(You'll learn about added names below.) If you still have trouble with
cwd, examine this picture:

                                  MULTICS (>)
                                 /    |    \
              library_dir_dir         |     process_dir_dir
                                user_dir_dir
                                /          \
                               /            \
                         Scouting          SysMaint
                        /    |    \          |    \
                  Bengal     |    Cheetah    |     GDixon
                          Panther        Martinson

These are **not** the only directories on the system, not at all! This is
just a small piece of a **subtree**, a kind of family tree of directories,
segments and links.

> **Today:** `pwd` (print_wdir) shows where you are. Your home directory is
> `>udd>Project>Person`.

### create_directory, cd

    cd {name}

create_directory creates a new directory inside the one you're in. If you
have a whole bunch of picture segments and want them all in one place, type
`cwd` (to go home) and then:

    cd pictures

Now your directory contains a subdirectory called "pictures". It's empty
for now. Continuing the picture: Multics is a continent, user_dir_dir is a
region on that continent, Scouting is a country in that region, Bengal is a
state in that country, and pictures is a city in that state. To go there:

    cwd >udd>sct>Bengal>pictures

or, if you're already in Bengal, just

    cwd pictures

because pictures is "in" Bengal. Now you can go into ted and make a file.
To list your directories, type `ls -d`:

    Directories = 1

    sma  pictures
           pic

The `sma` is like `rew` for segments; these are the access modes for a
directory:

| Mode | Name | Meaning |
|---|---|---|
| s | status | look in the directory (list it) |
| m | modify | change the directory: its names, ACLs and contents |
| a | append | add files to the directory |

You set a directory's ACL with `sa`, just as for segments:

    sa {directory} {modes} {access_name}

Obviously, you don't want to type "pictures" every time you use that
directory... so there is the add_name command.

### add_name, an

    an {original_name} {new_names}

add_name gives segments, directories and links additional (usually shorter)
names:

    an pictures pic

Now you can say "pic" instead of "pictures", and get to
`>user_dir_dir>Scouting>Bengal>pictures` with:

    cwd >udd>sct>Bengal>pic

This saves a lot of time. (That's why the listing above shows "pic" under
"pictures".)

### rename, rn

    rn {original_name} {new_name}

rename gives a segment, directory or link a new name in place of an old
one. To rename "pictures" to "artwork":

    rn pictures artwork

### delete_name, dn

    dn {name}

delete_name removes one name from a segment, directory or link that has
more than one. If you no longer want "pic" on the directory "artwork":

    dn pic

### delete_dir, dd

    dd {directory_name}

delete_dir deletes a directory **and everything in it**:

    dd pictures

To delete a directory you must be in the directory above it (here,
`>udd>sct>Bengal`). Think of a family tree: grandchildren are below
children, who are below parents, who are below grandparents.

### move, mv

    move {pathname} {new_pathname}

move takes a file from one directory and puts it in another. Suppose you
have a file "bird" in your home directory (`>udd>sct>Bengal`) and want it in
"pictures":

    move bird >udd>sct>Bengal>pic>bird

or, more simply:

    mv bird pic>bird

The "bird" at the end of the second pathname is the name it will have in the
new place. You could make it "tweeter," but it will still have the name
"bird" on it too; delete that with `dn` if you like.

> **Today:** `pic>bird`, with no leading `>`, is a **relative pathname**: it
> starts from the directory you're in.

### link, lk

    lk {pathname}

The link command works like a system abbreviation for a file. Suppose you
use a file called foobar in `>udd>sct>Panther>my_junk`. You don't want to
type `>udd>sct>Panther>my_junk>foobar` every time, and you can't add a name
to a file you don't have modify access to. So what is to be done? The link
command:

    link >udd>sct>Panther>my_junk>foobar

From now on, "foobar" in your directory means
`>udd>sct>Panther>my_junk>foobar`. Simple as that. To list your links, type
`list -links`:

    Links = 1

    foobar                     >udd>Scouting>Panther>my_junk>foobar

The first column is the name you type, and the second is what it stands
for.

### unlink, ul

    ul {link_name}

unlink disposes of a link. If you no longer use "foobar":

    ul foobar

### general_ready, gr

    gr {control_arguments}

general_ready sets what is printed at command level when Multics is ready
for your next command (the ready message). For example:

    gr -string "Ready Bengal!" -time -date -level -set

`-string` puts "Ready Bengal!" at the beginning, followed by the time and
the date.

`-level` has to do with the Break key. When you hit Break, the command
processor puts you at a new command level, one higher than before. Each time
you hit Break the level climbs, and when it gets to around 60, you are
logged in again. To get rid of levels, type `rl` (`release`), which releases
one level. `rl -a` releases them all. `-level` puts the level in the ready
message so you can see it.

`-set` establishes this as your ready message until you log out or change
it.

This ready message prints like this:

    Ready Bengal! hhmm.s MM/DD/YY level N, n

for example:

    Ready Bengal! 1234.5 10/12/81 level 2, 9

> **Today:** `general_ready` still exists and works as described. If you
> keep the standard ready message instead, a "level" at its end
> (`r 12:34 0.123 45 level 2`) tells you that you have a suspended
> program; `release` or `start` deals with it.

---

Now that we have gone over the essential commands of Multics, you can be
left on your own. If you had any problems, suggestions or questions about
Multics or this guide, you asked Mark Davis, or sent mail to
MDavis.Scouting. Remember to hang on to this guide until you have fully
comprehended Multics.

---

## 12. Where the MIG was headed

By early 1983 Mark had split the guide into a series of short numbered
guides, kept in the Post's filing cabinet and in an archive in the Multics
Tutor directory. His last surviving table of contents shows the plan.
Status is as he marked it: ✔ complete, ½ nearly complete, … started, ☐ not
started. Where a topic is covered in this edition, the section is given.

| No. | Subject | Status | Here |
|---|---|---|---|
| 1a | Introduction to MIG | ✔ | §1 |
| 2a | List of MIG Guides | ½ | §12 |
| 2b | Special MIG Notation (!) | ✔ | §2 |
| 3a | Common Multics Concepts A (Person.Project) | ✔ | §3 |
| 3b | Common Multics Concepts B (CR/LF, UC/LC, BREAK/QUIT, #/@) | ✔ | §3 |
| 3c | Common Multics Concepts C (MIG Glossary) | … | §3 |
| 3d | Common Multics Concepts D (Control Arguments) | ✔ | §2 |
| 3e | Common Multics Concepts E (Parentheses Notation) | ✔ | |
| 3f | Common Multics Concepts F (Hierarchies) | ✔ | §11 (cwd) |
| 3g | Common Multics Concepts G (Significance of Person.Project) | ✔ | |
| 3h | Common Multics Concepts H (\c) | ✔ | |
| 3i | Common Multics Concepts I (*,= as Fields) | ☐ | |
| 4a | Accessing Multics | ✔ | §4 |
| 4b | Logging Out From Multics | ✔ | §4 |
| 4c | Changing Your Password | ✔ | §4 |
| 5a | Introduction to the Mail System | ✔ | §6 |
| 5b | Distinguishing messages and mail | ✔ | §6 |
| 5c | Mailboxes | ✔ | §6 |
| 5d | Sending mail (sdm) | ✔ | §6 |
| 5e | Sending messages (sm) | ✔ | §6 |
| 5f | Reading mail (rdm) | ✔ | |
| 5g | Reading messages (ml) | ✔ | |
| 6a | Introduction to Multics Security | ✔ | |
| 6b | AIM | ✔ | |
| 6c | Ring Brackets | ✔ | |
| 6d | ACL (the term) | ✔ | §11 |
| 6e | Setting ACL (sa) | ✔ | §11 |
| 6f | Listing and Deleting ACL (la, da) | ✔ | |
| 6g | Mailbox Access | ✔ | §6 |
| 7a | Text Editors | ✔ | §10 |
| 7b | Introduction to Ted (buffers,=,+,-) | ✔ | §10 |
| 7c | Ted Read Commands (r) | ½ | §10 |
| 7d | Basic Ted Commands (a,p,d,i,.) | ☐ | §10 |
| 7e | Ted Search and Substitute Commands (s,//,^,$) | ☐ | §10 |
| 7f | Ted Write Commands (w) | ☐ | §10 |
| 7g | Advanced Ted Commands (e,g) | ☐ | §10 |
| 7h | Ted Buffer Commands And Other Ted Commands (m,\b) | ☐ | |
| 7i | Summary of Ted Commands | ☐ | §10 |
| 8a | Abbreviations | ☐ | §8 |
| 8b | Setting And Manipulating Abbreviations | ☐ | §8 |
| 8c | Changing, Copying, and Deleting Abbreviations | ☐ | §8 |
| 8d | Abbreviation Listing Commands | ☐ | §8 |
| 8e | Other Abbreviation Commands | ☐ | |
| 9a | Start_ups | ☐ | §9 |
| 9b | Search Rules and Search Paths | ☐ | |
| 10a | Introduction to Forum | ☐ | |

The guides marked complete but not covered here (3e–3h, 5f, 5g, 6a–6c, 6f)
were written after the January 1983 printout and have not survived, as far
as we know. If you have a copy, please get in touch.

---

## 13. Sources and editorial notes

**Author.** Mark Davis (MDavis.Scouting), Explorer Post 414, Phoenix,
Arizona, with help from "various Multics users." The Post used Honeywell's
System M (Honeywell LISD Phoenix).

**Sources** (from the papers of Jim Lippard, transcribed in October 2026):

1. *Explorers Post 414 / Multics Introductory Guide.* A line-printer listing
   of `>udd>Scouting>MDavis>t>MIG` (request 850124, printed 3 January 1983;
   19 pages), partly replaced by three sheets printed on a terminal-room
   printer (Rosy). One page, on reading mail, is missing. The text dates from
   about 1980–81; its examples are dated 1980, one 1981 and one 1983.
2. *Multics Informational Guide,* guides 0a–6g. A line-printer listing of the
   archive `>user_dir_dir>Scouting>MDavis>t>tutorial` (request 460026,
   printed 25 January 1983; 40 pages, of which 28 were photographed).
   Components dated June 1982 to January 1983.
3. *Table of contents* of the Multics Informational Guide, a single
   terminal-printed sheet, later than source 2.

Faithful transcriptions of all three, keeping Mark's spelling, line
layout and printer details, are kept separately from this edition.

**How this edition was put together.**

* §2–§4 and most of §6 follow the 1983 guides (source 2), with the 1980
  guide's foobar example and other details added.
* §5 and §7–§11 follow the 1980 guide (source 1). In §10 the Rosy sheets and
  the line-printer pages are the same text with small differences. The
  review table uses `gP`, as in the text.
* The 1980 page on reading mail is lost. §6 "Reading mail" joins the
  surviving fragments.
* Mark's examples, user names (Bengal, Cheetah, Panther, Tigerone,
  Furrball and the rest), dates and the 1980 phone number are kept as
  history.
* Spelling is corrected ("occurrences," "delimiters"). Long explanations
  inside ted's example blocks were moved into the text, and the start_up
  explanations into a table.
* Glossary definitions (§3), "Today" notes and §12's cross-references were
  added in 2026 and are not Mark's.

**Edited** by Claude Opus 5.5 (Anthropic) for Jim Lippard, October 2026.
