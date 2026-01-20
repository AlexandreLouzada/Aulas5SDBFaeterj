-- 04_plsql/01_functions.sql

CREATE OR REPLACE FUNCTION fn_valor_venda (p_id_venda IN NUMBER)
RETURN NUMBER
IS
  v_total NUMBER(14,2);
BEGIN
  SELECT NVL(SUM(valor_total), 0)
    INTO v_total
    FROM tb_venda_item
   WHERE id_venda = p_id_venda;

  RETURN v_total;
END;
/
SHOW ERRORS;

-- Comissão didática:
-- 2% padrão; 3% se canal = 'APP' ou 'SITE';
-- 1% se canal = 'TELEFONE'; 0% se venda não estiver FECHADA.
CREATE OR REPLACE FUNCTION fn_comissao_vendedor (
  p_id_venda IN NUMBER
) RETURN NUMBER
IS
  v_status tb_venda.status%TYPE;
  v_canal  tb_venda.canal%TYPE;
  v_valor  tb_venda.valor_liquido%TYPE;
  v_pct    NUMBER(5,4);
BEGIN
  SELECT status, canal, valor_liquido
    INTO v_status, v_canal, v_valor
    FROM tb_venda
   WHERE id_venda = p_id_venda;

  IF v_status <> 'FECHADA' THEN
    RETURN 0;
  END IF;

  v_pct :=
    CASE v_canal
      WHEN 'APP'  THEN 0.03
      WHEN 'SITE' THEN 0.03
      WHEN 'LOJA' THEN 0.02
      ELSE 0.01
    END;

  RETURN ROUND(v_valor * v_pct, 2);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0;
END;
/
SHOW ERRORS;
