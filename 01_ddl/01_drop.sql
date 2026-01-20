-- 01_drop.sql
-- Execute se quiser recriar do zero.

BEGIN
  FOR t IN (SELECT table_name FROM user_tables
            WHERE table_name IN (
              'TB_VENDA_ITEM','TB_VENDA','TB_PRODUTO','TB_CATEGORIA',
              'TB_CLIENTE','TB_VENDEDOR','TB_AUDITORIA_VENDA','TB_CALENDARIO'
            ))
  LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
END;
