 alter table dwm.mcl_clientes  --1 a 48part
 switch  partition 48 to [dwm].PartSwitch_Mcl_clientes
 go


 select count(*) from [dwm].PartSwitch_Mcl_clientes
 go

 truncate table [dwm].PartSwitch_Mcl_clientes
 go

  select count(*) from [dwm].PartSwitch_Mcl_clientes
 go
