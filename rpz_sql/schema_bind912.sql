-- Schema for RPZ for bind9.12
-- Assumes you are using the default Pg DLZ. Which is the only sane one.
-- Do not make the error of thinking you know any better.

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
-- need this for IDN
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;

-- Create sequences first.
-- rpz_auto__id_seq
CREATE SEQUENCE rpz_auto__id_seq
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;


-- Create our tables...
CREATE TABLE rpz_auto (
	id sequence rpz_auto__id_seq NOT NULL;
	zone text NOT NULL,
	host text NOT NULL,
	ttl integer NOT NULL,
	type text,
	mx_priority integer,
	data text,
	resp_person text,
	serial integer,
	refresh integer,
	retry integer,
	expire integer,
	minimum integer,
	created timestamp(0) WITHOUT time zone NOT NULL,
	modified timestamp(0) WITHOUT time zone NOT NULL
);

ALTER TABLE rpz_auto OWNER TO bindrpz;

