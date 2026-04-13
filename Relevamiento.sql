sp_whoisactive
    @delta_interval = 60 
	,@get_outer_command = 1
	,@get_plans = 1
	,@Sort_order =

/*
select c.fec_carga, c.ingre_fecha, c.ingre_hora, c.ingre_minuto, c.cuil, c.sucursal, c.ape_nom, c.entidad, c.lte_visa_prest, 
		c.lte_visa_compra, c.grupo_afinidad, c.producto, c.tipo_doc, c.nro_doc, c.suc_db, c.tipo_cta_db, c.cta_db,
		 case c.campa_cod when '' then 0 else c.campa_cod end campa_cod, c.respuesta, c.resp_descri, c.resp_fecha
		into  #PREEMBOZADO_ARCHIVO
		--select max(fec_carga)
		from dwd.dtc_PREEMBOZADO_ARCHIVO c inner join 
		(select max(a.fec_carga) fec_carga, a.cuil		
			from #CUIL_FECHA b inner join dwd.dtc_PREEMBOZADO_ARCHIVO a
			on (convert(varchar(8), a.ingre_fecha) + convert(varchar(2), a.ingre_hora) + convert(varchar(2), a.ingre_minuto)) = b.txt_ingre_fecha --and  a.ingre_hora = b.txt_ingre_hora 
			--and a.ingre_minuto = b.txt_ingre_minuto 
			and a.cuil = b.cuil and a.campa_cod = b.campa_cod
			where  b.campa_cod = 164 
			group by a.cuil) as d
		on c.fec_carga = d.fec_carga and c.cuil = d.cuil




-- exec Tableros.dbo.LDR_DRI_SALDOS_OPERATIVOS_LIQUIDEZ 20190816, 20190816, 'D'

insert into dwd.dri_saldos_operativos_liquidez (
ope_fec_carga,
ope_id_empresa,
ope_id_sucursal,
ope_rubro,
ope_id_moneda,
ope_id_papel,
cta_numero,
ope_operacion,
ope_sub_operacion,
ope_id_tipo_operacion,
ope_id_modulo,
ope_fec_valor,
ope_fec_venci,
ope_Tasa,
ope_Saldo_ori,
ope_Saldo)

select  bcfec, bcemp, bcsuc, bcrubr, bcmda, bcpap, bccta, bcoper, bcsbop, bctop, bcmod, bcfval, bcfvto, bctasa, bcsdmo, bcsdmn 
from	sta.sta_saldos_ope_diarios inner join dwabm.dbo.elemento on 
			atr_id = @atributo 
			and substring(convert(varchar(9), bcrubr), 1, len(ele_cod_ori)) = ele_cod_ori
where bcsdmn <> 0 


		




exec UPD_MART_INT_SALDOS_OPE_E4	20190801,	20190815;
exec UPD_MPP_INT_COMPENSATORIO	20190801,	20190815;
exec LDR_MART_INT_SALDOS_OPE_E5	20190801,	20190815;
exec UPD_DTC_TARJETA_CREDITO_DEUDA	20190801,	20190815;
exec UPD_MTC_TARJETA_CREDITO_DEUDA	20190801,	20190815;
exec RUN_SALDOS_CONTABLES_PRESUP	20190801,	20190815;
exec LDR_FT_SALDOS_OPE_MMED	20190801,	20190815;
exec UPD_FT_SALDOS_OPE_MMED_TC	20190801,	20190815;
exec FIX_FT_SALDOS_OPE_MMED_311	20190801,	20190815;
exec INS_FT_SALDOS_OPE_MMED_CF	20190801,	20190815;
exec LDR_AT_SALDOS_OPE_MMED_DIA	20190801,	20190815;




<?query --
INSERT INTO SALDOS_PR0p_TMP (                          
  id_tie_mes, id_cia_compania, id_con_cta, id_suc_sucursal, id_cos_ctro,                           
  id_ope_prod, id_int_interfaz, id_mon_moneda, id_ban_banca,                           
  id_seg_segmento_cdg, id_ofi_oficial, id_ofi_equipo_hist,                           
  id_ofi_gerente_hist, id_ofi_lider_hist,                           
  id_med_medida, id_cli_persona_hist, id_cli_cuenta,                          
  fc_mmed_dias_mes,                          
  fc_mmed_saldo, fc_mmed_saldo_ars, fc_mmed_promedio, fc_mmed_promedio_ars,                           
  fc_mmed_numeral, fc_mmed_numeral_ars, fc_mmed_variacion,                   
  fc_mmed_variacion_ars,                          
  fc_mmed_tasa_trans,                   
  fc_mmed_interes_tt,                   
  fc_mmed_interes_tt_ars,                   
  id_ope_origen_tt,    
  id_suc_sucursal_ori,                
  fc_mmed_interes_tt_teorico,                   
  fc_mmed_interes_tt_teorico_ars                  
       )                          
 SELECT id_tie_mes, id_cia_compania, isnull(ct.id_con_cta,0), isnull(su.id_suc_sucursal,0),                           
 isnull(cc.id_cos_ctro,0), isnull(pr.id_ope_prod, 0), id_int_interfaz,                           
 isnull(mo.id_mon_moneda,0), isnull(ba.id_ban_banca, 0),                          
 id_seg_segmento_cdg, id_ofi_oficial, id_ofi_equipo_hist,                           
 id_ofi_gerente_hist, id_ofi_lider_hist,                          
 isnull(ele.ele_pad_id,0), 0 id_cli_persona_hist, isnull(cl.id_cli_cuenta,0),                          
 max(fc_mmed_dias_mes),                          
 sum(fc_mmed_saldo), sum(fc_mmed_saldo_ars), sum(fc_mmed_promedio), sum(fc_mmed_promedio_ars),                           
 sum(fc_mmed_numeral), sum(fc_mmed_numeral_ars), sum(fc_mmed_variacion),                   
 sum(fc_mmed_variacion_ars),                  
 0  as fc_mmed_tasa_trans,                          
 sum(fc_mmed_interes_tt),                  
 sum(fc_mmed_interes_tt_ars),                   
 isnull(id_ope_origen_tt,2),     
 isnull(SUO.id_suc_sucursal_ori,0),               
 sum(fc_mmed_interes_tt_teorico),                   
 sum(fc_mmed_interes_tt_teorico_ars)                          
 FROM SALDOS_TMP S                          
  LEFT OUTER JOIN tableros.dbo.LK_CON_CTA CT                          
   ON ct.id_con_cta = s.id_con_cta                          
  LEFT OUTER JOIN tableros.dbo.LK_CLI_CUENTA CL                          
   ON cl.id_cli_cuenta = s.id_cli_cuenta                          
  LEFT OUTER JOIN tableros.dbo.LK_SUC_SUCURSAL SU                          
   ON su.id_suc_sucursal = s.id_suc_sucursal                          
  LEFT OUTER JOIN tableros.dbo.LK_COS_CTRO CC                          
   ON cc.id_cos_ctro = s.id_cos_ctro                          
  LEFT OUTER JOIN DWABM.DBO.REL_CTACONT_PROD P                          
   ON P.CtaCont_id = isnull(ct.id_con_cta,0)                          
    and S.id_tie_mes BETWEEN  RelCP_Desde AND RelCP_Hasta                          
  LEFT OUTER JOIN tableros.dbo.LK_OPE_PROD PR                          
   ON pr.id_ope_prod = isnull(p.Prod_Id, 0)                          
  LEFT OUTER JOIN tableros.dbo.LK_MON_MONEDA MO             
   ON mo.id_mon_moneda = s.id_mon_moneda                          
  LEFT OUTER JOIN tableros.dbo.LK_BAN_BANCA BA                          
   ON ba.id_ban_banca = s.id_ban_banca                          
  LEFT OUTER JOIN DWABM.dbo.ELEMENTO_RELACION ELE                          
   ON ELE.ATR_PAD_ID = @AtrId_Medida                          
    AND ELE.ATR_HIJ_ID = @AtrId_ImpCta                           
    AND ELE.ELE_HIJ_ID = CT.ID_CON_IMPUT_CTA   
  LEFT OUTER JOIN lkv_suc_sucursal_origen SUO      
 ON       s.id_suc_sucursal_ori = SUO.id_suc_sucursal_ori               
 group by id_tie_mes, id_cia_compania, isnull(ct.id_con_cta,0), isnull(su.id_suc_sucursal,0),                           
   isnull(cc.id_cos_ctro,0), isnull(pr.id_ope_prod, 0), id_int_interfaz,                           
   isnull(mo.id_mon_moneda,0), isnull(ba.id_ban_banca, 0),                          
   id_seg_segmento_cdg, id_ofi_oficial, id_ofi_equipo_hist,                           
   id_ofi_gerente_hist, id_ofi_lider_hist,                           
   isnull(ele.ele_pad_id,0), isnull(cl.id_cli_cuenta,0), id_ope_origen_tt,isnull(SUO.id_suc_sucursal_ori,0);                          
                          

    
--?>

--------------------------------------------------------------------------------

Plan 3

--------------------------------------------------------------------------------
<?query --
exec Tableros.Dbo.TRX_CALC_SALDOS_CONT 20190801, 20190816, 0, 0, 'B'
--?>

<?query --
select Fecha, 0 FechaAnt, CuentaCod, CompaniaId , SucCod, CtroImpCod, MonedaId      
  into #SaldosContFaltantes      
  from marts.mart_saldos_contables (nolock) m      
  where Fecha between @Dia_Dde and @Dia_Hta      
  AND  (M.CompaniaId = @compania OR @compania = 0)      
  and not exists (      
   select 'existe'      
   from marts.mart_saldos_contables (nolock) m2      
   where m2.CuentaCod = m.CuentaCod      
   and  m2.CompaniaId = m.CompaniaId      
   and  m2.SucCod = m.SucCod      
   and  m2.CtroImpCod = m.CtroImpCod      
   and  m2.MonedaId = m.MonedaId      
   and  m2.Fecha = m.FechaAnt)      
  and not exists (      
   select 'existe'      
   from marts.mart_saldos_contables_Aux (nolock) m3      
   where m3.CuentaCod = m.CuentaCod      
   and  m3.CompaniaId = m.CompaniaId      
   and  m3.SucCod = m.SucCod      
   and  m3.CtroImpCod = m.CtroImpCod      
   and  m3.MonedaId = m.MonedaId      
   and  m3.Fecha = m.FechaAnt)      
      
  
--?>
*/


