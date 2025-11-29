--Author:		Andrea Gnemmi
--Conference:	Data Saturday Parma 2025
--Date:			29/11/2025	

/*
Using database chinook for testing as there is a script to create it for each RDBMS: 
https://github.com/cwoodruff/ChinookDatabase
Using pgbench for generating traffic, it comes with every PostgreSQL installation:
https://www.postgresql.org/docs/current/pgbench.html

pgbench 
pgbench -U postgres -c 70 -j 3 -T 120 chinook

-U indicates the role which runs all the queries, -c the number of sessions, -j the number of threads 
and -T the time in seconds of the test duration.
*/

--Top 20 slowest queries: pg_stat_statements should be enabled and added to shared preload libraries in postgresql.conf
--shared_preload_libraries = pg_stat_statements	# (change requires restart)
--CREATE EXTENSION pg_stat_statements
SELECT userid::regrole,datname as dbname,  substring(query, 1, 100) AS short_query,
round(total_exec_time::numeric, 2) AS total_exec_time,calls,round(mean_exec_time::numeric, 2) AS mean,
round((100 * total_exec_time /sum(total_exec_time::numeric) OVER ())::numeric, 2) AS percentage_cpu
FROM    pg_stat_statements
inner join pg_database
on dbid=oid
ORDER BY total_exec_time DESC
limit 20;

--Explain option generic_plan
explain (generic_plan) 
UPDATE pgbench_branches 
SET bbalance = bbalance + $1 WHERE bid = $2;

--Explain analyze
EXPLAIN ANALYZE 
SELECT abalance 
FROM pgbench_accounts 
WHERE aid = 10001;

--begin rollback workaround
begin;
explain analyze
UPDATE pgbench_branches 
SET bbalance = bbalance + 1000 
WHERE bid = 10001;
rollback;

--explain analyze option buffers
--Option BUFFERS needs track_io_timing enabled in order to show time spent reading and writing 
--data file blocks, local blocks and temporary file blocks (in milliseconds) beware of the overhead! 
--pg_test_timing tool
alter system set track_io_timing = on;
EXPLAIN (ANALYZE, BUFFERS)
SELECT abalance 
FROM pgbench_accounts 
WHERE aid = 10001;

--explain analyze option wal
explain (analyze, wal)
INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) 
VALUES (1, 2, 3, 4, CURRENT_TIMESTAMP);

--explain analyze option settings
set enable_seqscan = off;
EXPLAIN (analyze, buffers, settings)
SELECT abalance 
FROM pgbench_accounts 
WHERE aid = 10001;

--explain analyze option format
EXPLAIN (ANALYZE, FORMAT XML)
SELECT abalance 
FROM pgbench_accounts 
WHERE aid = 10001;

EXPLAIN (ANALYZE, FORMAT json)
SELECT abalance 
FROM pgbench_accounts 
WHERE aid = 10001;

--more complex query and pgAdmin
select 
   distinct "Genre"."Name", 
   cast(SUM("Quantity") OVER (PARTITION BY "Genre"."Name") /cast(SUM("Quantity") OVER () as decimal (8,3))*100 as decimal (5,3)) as Perc
from "InvoiceLine"
inner join "Track" on "InvoiceLine"."TrackId"="Track"."TrackId"
inner join "Genre" on "Track"."GenreId"="Genre"."GenreId"
order by Perc desc;

--with other options
explain (analyze, buffers, format json)
select 
   distinct "Genre"."Name", 
   cast(SUM("Quantity") OVER (PARTITION BY "Genre"."Name") /cast(SUM("Quantity") OVER () as decimal (8,3))*100 as decimal (5,3)) as Perc
from "InvoiceLine"
inner join "Track" on "InvoiceLine"."TrackId"="Track"."TrackId"
inner join "Genre" on "Track"."GenreId"="Genre"."GenreId"
order by Perc desc;





