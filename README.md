# StupidDB
The Dumbest DB Out There

# The basic idea
A relation-based database built on top of a filesystem, each record is a folder, relations are symlinks, files are key/value (filename/content), arrays and objects are directories. I also implemented a simple index system, you can define keys to track (either by command or by creating a directory named after the key in the index directory.
the DB is configured to work from /img and to hold it's indexes in /img/index.

#Why?
no real reason, I thought about doing it and it seemed like a fun and simple idea to implement, so I did it. 

#Is it a good idea?
Probably not, not sure why but I have a gut feeling it ain't. 

# Command syntax

    "This is [record]" - Creates a new record
    "[record] has (a|an) [attribute], [value] and [value]..." - Set attributes and relations
    "[record] has (number) [attribute], [value] and [value]... - Set array of values
    "track [index]" - Add new index
    "report [index]" - Lists index
    "describe [record]" - displays shallow record
    "forget [record]" - removes all attributes and relations from object
