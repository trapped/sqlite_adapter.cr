#!/usr/bin/env bash

SQLITE_DB=${SQLITE_DB:-data.db}

sqlite3 $SQLITE_DB "drop table if exists people; create table people( id integer primary key autoincrement not null, last_name varchar(50), first_name varchar(50), number_of_dependents int, special_tax_group boolean )"
sqlite3 $SQLITE_DB "drop table if exists something_else; create table something_else( id integer primary key autoincrement not null, name varchar(50) )"
sqlite3 $SQLITE_DB "drop table if exists posts; create table posts( id integer primary key autoincrement not null, title varchar(50), content varchar(50), created_at datetime default current_timestamp )"
