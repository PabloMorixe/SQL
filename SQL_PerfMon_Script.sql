PerfMon Steps script
====================
Create a folder: D:\PerfMonLogs\ or update the path.
 
1.Configuration CMD: (run it in Command Prompt as Administrator)
 
Default Instance:
Logman create counter msperf -f bin -c "\SQLServer:Buffer Manager\*" "\SQLServer:Memory Node(*)\*" "\SQLServer:Buffer Node(*)\*" "\SQLServer:Locks(*)\*" "\SQLServer:Databases(*)\*" "\SQLServer:Database Replica(*)\*" "\SQLServer:Database Mirroring(*)\*" "\SQLServer:General Statistics\*" "\SQLServer:Latches\*" "\SQLServer:Access Methods\*" "\SQLServer:SQL Statistics\*" "\SQLServer:Memory Manager\*" "\SQLServer:Wait Statistics(*)\*" "\LogicalDisk(*)\*" "\PhysicalDisk(*)\*" "\Processor(*)\*" "\Process(*)\*" "\Memory\*" "\System\*" -si 00:00:05 -o D:\PerfMonLogs\MS_perf_log.blg -cnf 24:00:00 -max 500
  
2.Start CMD:
Logman start msperf (Reproduce this issue/collect for 10 minutes or the necessary time)
 
3.Stop CMD:
Logman stop msperf2


