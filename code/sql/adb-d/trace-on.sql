-- enable tracing for my session

alter session set max_dump_file_size=unlimited;
alter session set statistics_level=typical;
exec dbms_monitor.session_trace_enable;


