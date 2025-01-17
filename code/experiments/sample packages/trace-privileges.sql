-- demonstrate the privileges a developer needs for tracing


-- You must be SYSDBA to perform the required grants.
connect sys/oracle as sysdba


-- Create role "mrdev", the Method R-endowed application developer.
drop role mrdev;                                            -- Fresh start
create role mrdev;                                          -- The Method R-endowed application developer
   grant execute on mr.dev_trace to mrdev;                  -- Helpful tracing features
   -- grant execute on sys.dbms_session to mrdev;              -- Required to use dbms_session
   -- grant execute on sys.dbms_application_info to mrdev;     -- Required to set Oracle user session handle attributes
   -- grant read on sys.v_$diag_info to mrdev;                 -- Not required, but symmetrical
   -- grant read on sys.v_$diag_trace_file to mrdev;           -- Nice to have, but not used by any tracing-oracle scripts
      grant read on sys.v_$diag_trace_file_contents to mrdev;  -- Required to read trace file content #TODO remove this when mr.dev_trace.get_contents is done
   -- grant alter session to mrdev;                            -- Required to use dbms_session.session_trace_enable (authid current_user)


-- User DEV1 represents an application developer.
drop user dev1 cascade;                                     -- Fresh start
create user dev1 identified by "Y0ur-Password-G0es-Here";   -- An application developer
grant create session to dev1;
grant mrdev to dev1;                                        -- Endow the developer with Method R privileges


-- User DBA1 represents a database administrator.
drop user dba1 cascade;                                     -- Fresh start
create user dba1 identified by "Y0ur-Password-G0es-Here";   -- A database administrator
grant dba to dba1;                                          -- A regular DBA
grant execute on mr.dev_trace to dba1;                      -- The Method R developer kit
grant execute on mr.dba_trace to dba1;                      -- The Method R DBA kit




-- Developer testing
connect dev1/Y0ur-Password-G0es-Here

-- Test the mr.dev_trace.set procedures.
exec mr.dev_trace.set_module('my-module')
exec mr.dev_trace.set_action('my-action')
exec mr.dev_trace.set_client('my-client')

-- Test the mr.dev_trace.get functions.
set autoprint on
var value varchar2(4000)
exec :value := q'[service=']'  || mr.dev_trace.get_service  || q'[']'
exec :value := q'[module=']'   || mr.dev_trace.get_module   || q'[']'
exec :value := q'[action=']'   || mr.dev_trace.get_action   || q'[']'
exec :value := q'[client=']'   || mr.dev_trace.get_client   || q'[']'
exec :value := q'[filename=']' || mr.dev_trace.get_filename || q'[']'
set autoprint off

-- Test tracing.
exec mr.dev_trace.trace_begin
col sd new_value sd
select to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') sd from dual;        -- Unique timestamp to validate trace file content
select q'[The program I'm writing ran at &sd]' message from dual;    -- This is where your application being traced would go
exec mr.dev_trace.trace_end
@my-trace-content                   -- #TODO delete this line when mr.dev_trace.get_content is written
-- exec mr.dev_trace.get_content    -- #TODO not written yet



-- DBA testing
connect dba1/Y0ur-Password-G0es-Here

-- Test trace enablers.
@enabled-traces
exec mr.dba_trace.handle_on(module=>'cary_module', action=>'cary_action');
@enabled-traces
exec mr.dba_trace.handle_off(module=>'cary_module', action=>'cary_action');
@enabled-traces

-- Test tracing.
exec mr.dba_trace.session_on;
col sd new_value sd
select to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') sd from dual;        -- Unique timestamp to validate trace file content
select q'[The program I'm diagnosing ran at &sd]' message from dual; -- This is where your application being traced would go
exec mr.dba_trace.session_off;
@my-trace-content

