select j.name,js.database_name from sysjobs j join sysjobsteps js
on j.job_id = js.job_id