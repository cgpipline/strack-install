#!/bin/bash

mysql -uroot -pstrack <<-EOSQL
    CREATE DATABASE strack;
    USE strack;
    SOURCE /opt/sql/strack.sql;
    SOURCE /opt/sql/strack_media_server.sql;
    CREATE DATABASE strack_media;
    USE strack_media;
    SOURCE /opt/sql/strack_media.sql;
EOSQL
