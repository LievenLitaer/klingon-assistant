#!/bin/bash

# Check for non-interactive mode flag.
if [ "$1" = "--noninteractive" ]
then
    NONINTERACTIVE=true
    shift
fi

# Check for xml-only mode flag (exclusive with "--noninteractive").
if [ "$1" = "--xmlonly" ]
then
    XMLONLY=true
    shift
fi

# Concatenate data into one xml file.
cat mem-00-header.xml mem-01-b.xml mem-02-ch.xml mem-03-D.xml mem-04-gh.xml mem-05-H.xml mem-06-j.xml mem-07-l.xml mem-08-m.xml mem-09-n.xml mem-10-ng.xml mem-11-p.xml mem-12-q.xml mem-13-Q.xml mem-14-r.xml mem-15-S.xml mem-16-t.xml mem-17-tlh.xml mem-18-v.xml mem-19-w.xml mem-20-y.xml mem-21-a.xml mem-22-e.xml mem-23-I.xml mem-24-o.xml mem-25-u.xml mem-26-footer.xml > mem.xml

if [ $XMLONLY ]
then
    exit
fi

# Write database version number.
VERSION=$(cat VERSION)
echo Writing database version $VERSION...
sed -i "s/\[\[VERSION\]\]/$VERSION/" mem.xml

# Convert from xml to sql instructions.
./xml2sql.pl > mem.sql
sed -i 's/INSERT INTO "mem"/INSERT INTO mem/g' mem.sql

# Print any entries with duplicate columns.
grep "ARRAY" mem.sql

# Create db binary.
git checkout ../assets/qawHaq.db
if [ -f ../assets/qawHaq.db ];
then
    if [ ! $NONINTERACTIVE ]
    then
        # If the db already exists, show a diff.
        sqlite3 ../assets/qawHaq.db .dump > old-mem.sql
        sed -i 's/INSERT INTO "mem"/INSERT INTO mem/g' old-mem.sql
        vimdiff old-mem.sql mem.sql
        read -n1 -r -p "Press any key to generate new db..."
        echo
    fi
    mv ../assets/qawHaq.db ../assets/qawHaq.db~
fi
sqlite3 ../assets/qawHaq.db < mem.sql

# Sanity check.
sqlite3 ../assets/qawHaq.db .dump > sanity.sql
sed -i 's/INSERT INTO "mem"/INSERT INTO mem/g' sanity.sql
diff mem.sql sanity.sql

# Pause (in case of error).
if [ ! $NONINTERACTIVE ]
then
    read -n1 -r -p "Press any key to delete temporary files..."
    echo
fi

# Clean up temporary files.
rm mem.xml
rm mem.sql
rm sanity.sql
rm -f old-mem.sql
rm -f ../assets/qawHaq.db~
