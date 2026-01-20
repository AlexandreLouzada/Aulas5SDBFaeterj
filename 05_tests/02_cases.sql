-- 05_tests/02_cases.sql
-- Exemplo: registrar uma venda com 3 itens

DECLARE
  v_id_venda NUMBER;
BEGIN
  pr_registrar_venda(
    p_id_cliente   => 1,
    p_id_vendedor  => 1,
    p_dt_venda     => SYSDATE,
    p_canal        => 'APP',
    p_ids_produto  => SYS.ODCINUMBERLIST(1, 2, 3),
    p_qtds         => SYS.ODCINUMBERLIST(1, 2, 1),
    p_descs_item   => SYS.ODCINUMBERLIST(0, 10, 0),
    p_id_venda_out => v_id_venda
  );

  DBMS_OUTPUT.PUT_LINE('Venda criada: ' || v_id_venda);
  DBMS_OUTPUT.PUT_LINE('Comissão: R$ ' || fn_comissao_vendedor(v_id_venda));
END;
/
-- Ver venda e itens
SELECT * FROM tb_venda WHERE id_venda = (SELECT MAX(id_venda) FROM tb_venda);
SELECT * FROM tb_venda_item WHERE id_venda = (SELECT MAX(id_venda) FROM tb_venda);
