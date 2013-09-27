#!/bin/bash
sqlplus piters@devdb10 @ExtractSchema.sql

cat ExtractedTables.sql|sed 's/"PITERS".//g' > TMP

mv TMP ExtractedTables.sql