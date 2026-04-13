ALTER TABLE dbo.ft_saldos_ope_mmed 
    SWITCH PARTITION 1 TO dbo.ft_saldos_ope_mmed_PartSwitch PARTITION 1;

select count(*) from [dwm].ft_saldos_ope_mmed_PartSwitch
go
TRUNCATE TABLE dbo.ft_saldos_ope_mmed_PartSwitch;
go
select count(*) from [dwm].ft_saldos_ope_mmed_PartSwitch
go