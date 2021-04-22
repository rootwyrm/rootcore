--------------------------------------------------------------------------------
-- pglogical_autostructure.sql
-- Copyright (C) 2021-* Phillip R. Jaenke
-- Coffeeware licensed
--   Free to use and redistribute. Like it? Love it? Buy me a coffee.
--------------------------------------------------------------------------------

-- This is a function to replicate both tables AND sequences using pglogical
-- in PostgreSQL 12.x and later. 13 is recommended but not strictly necessary.
-- Note that this will replicate sequences BUT WILL NOT NECESSARILY TRIGGER
-- SYNCHRONIZATION! 
-- This function should be installed on primary AND secondary servers (pubs
-- and subs,) even if not performing bi-directional replication.

CREATE OR REPLACE FUNCTION pglogical_assign_repset()
RETURNS event_trigger AS $$
DECLARE obj record;
BEGIN
	FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
	LOOP
		IF obj.object_type = 'table' THEN
			IF obj.schema_name = 'config' THEN
				PERFORM pglogical.replication_set_add_table('configuration', obj.objid);
			ELSIF NOT obj.in_extension THEN
				PERFORM pglogical.replication_set_add_table('default', obj.objid);
			END IF;
		ELSIF obj.object_type = 'sequence' THEN
			PERFORM pglogical.replication_set_add_sequence('default', obj.objid, 'true');
		END IF;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

-- This trigger will actually call the function we just created
CREATE EVENT TRIGGER pglogical_assign_repset_trigger
	ON ddl_command_end
	WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'CREATE SEQUENCE')
	EXECUTE PROCEDURE pglogical_assign_repset();

