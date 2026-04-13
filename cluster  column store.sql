USE [Tableros]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dwm].[mcl_cliente_producto_PNB_CCS](
	[id_tie_mes] [int] NULL,
	[desc_tie_mes] [varchar](50) NULL,
	[dias_trasncurridos] [int] NULL,
	[dias_anio] [int] NULL,
	[id_cli_persona] [int] NULL,
	[desc_cli_persona] [varchar](100) NULL,
	[desc_cli_numero_cuit] [varchar](12) NULL,
	[id_ban_banca_persona] [tinyint] NULL,
	[desc_ban_banca_persona] [varchar](50) NULL,
	[id_ban_banca_cuenta] [tinyint] NULL,
	[desc_ban_banca_cuenta] [varchar](50) NULL,
	[id_ban_grp_banca] [smallint] NULL,
	[desc_ban_grp_banca] [varchar](50) NULL,
	[id_cli_cuenta] [int] NULL,
	[desc_cli_cuenta] [varchar](100) NULL,
	[id_ofi_oficial] [int] NULL,
	[Desc_ofi_oficial] [varchar](50) NULL,
	[id_ofi_oficial_cta] [int] NULL,
	[desc_ofi_oficial_cuenta] [varchar](50) NULL,
	[id_ofi_oficial_persona] [int] NULL,
	[desc_ofi_oficial_persona] [varchar](50) NULL,
	[id_suc_sucursal] [smallint] NULL,
	[Desc_suc_sucursal] [varchar](50) NULL,
	[desc_suc_cod_sucursal] [int] NULL,
	[id_suc_tipo] [smallint] NULL,
	[Desc_suc_tipo] [varchar](50) NULL,
	[id_suc_sucursal_persona] [smallint] NULL,
	[desc_suc_sucursal_persona] [varchar](50) NULL,
	[id_con_tipo_moneda] [tinyint] NULL,
	[desc_con_tipo_moneda] [varchar](50) NULL,
	[id_ope_subtipo_prod] [smallint] NULL,
	[desc_ope_subtipo_prod] [varchar](50) NULL,
	[id_ope_subflia_prod] [smallint] NULL,
	[desc_ope_subflia_prod] [varchar](50) NULL,
	[id_ope_flia_prod] [smallint] NULL,
	[desc_ope_flia_prod] [varchar](50) NULL,
	[id_ope_grp_prod] [smallint] NULL,
	[desc_ope_grp_prod] [varchar](50) NULL,
	[id_ope_tipo_prod] [tinyint] NULL,
	[desc_ope_tipo_prod] [varchar](50) NULL,
	[id_ope_subgrp_prod] [smallint] NULL,
	[desc_ope_subgrp_prod] [varchar](50) NULL,
	[id_ope_prod] [int] NULL,
	[desc_ope_prod] [varchar](50) NULL,
	[desc_ope_codigo_prod] [varchar](15) NULL,
	[Tasa_Cliente] [numeric](38, 6) NULL,
	[tasa_cf] [numeric](38, 6) NULL,
	[tasa_margen_ope] [numeric](38, 6) NULL,
	[id_cli_renta] [smallint] NULL,
	[desc_cli_renta] [varchar](30) NULL,
	[id_beneficiario] [smallint] NULL,
	[desc_beneficiario] [varchar](30) NULL,
	[id_cli_comercio] [smallint] NULL,
	[desc_cli_comercio] [varchar](30) NULL,
	[id_cli_seg_comercial_mkt] [smallint] NULL,
	[intereses_cliente] [numeric](38, 6) NULL,
	[intereses_tt_ope] [numeric](38, 6) NULL,
	[comisiones] [numeric](38, 6) NULL,
	[VP_Capital_OPE] [numeric](38, 6) NULL,
	[VP_Resultado_Ope] [numeric](38, 6) NULL,
	[Diversos] [numeric](38, 6) NULL,
	[VP_Total_OPE] [numeric](38, 6) NULL,
	[VP_Int_Cob_Pag_Ope] [numeric](38, 6) NULL,
	[Cargos_ope] [numeric](38, 6) NULL,
	[Recu_y_desaf_ope] [numeric](38, 6) NULL,
	[saldo_capital_ope] [numeric](38, 6) NULL,
	[saldo_ope] [numeric](38, 6) NULL,
	[margen] [numeric](38, 6) NULL,
	[pnb_de_gestion] [numeric](38, 6) NULL,
	[per_id_pais] [smallint] NULL,
	[per_id_tipo_doc] [smallint] NULL,
	[per_nro_documento] [varchar](12) NULL,
	[per_flg_activo] [tinyint] NULL,
	[per_flg_titular] [tinyint] NULL,
	[per_fec_carga] [int] NULL,
	[pnb_nominal] [numeric](38, 6) NULL,
	[fecha_procesamiento] [int] NULL
) ON [DBOFilegroup]
GO


CREATE CLUSTERED COLUMNSTORE INDEX [CCI_DWM_mcl_cliente_producto_PNB_CCS] ON [dwm].[mcl_cliente_producto_PNB_CCS]
WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0) ON [DBOFilegroup]
GO


--Copiar los datos del año 2018. 

ALTER TABLE [dwm].[mcl_cliente_producto_PNB_CCS] ADD  CONSTRAINT [PK] unique nonCLUSTERED 
(
	[id_tie_mes] ASC,
	[id_cli_persona] ASC,
	[id_ban_grp_banca] ASC,
	[id_cli_cuenta] ASC,
	[id_ofi_oficial] ASC,
	[id_suc_sucursal] ASC,
	[id_con_tipo_moneda] ASC,
	[id_ope_prod] ASC
)ON [DBOFilegroup]
GO

--borrar datos de la tabla dwm que fueron copiados al schema dbo. 