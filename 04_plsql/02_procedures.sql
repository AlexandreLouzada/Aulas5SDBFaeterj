-- 04_plsql/02_procedures.sql

CREATE OR REPLACE PROCEDURE pr_registrar_venda (
  p_id_cliente   IN NUMBER,
  p_id_vendedor  IN NUMBER,
  p_dt_venda     IN DATE,
  p_canal        IN VARCHAR2,
  p_ids_produto  IN SYS.ODCINUMBERLIST,
  p_qtds         IN SYS.ODCINUMBERLIST,
  p_descs_item   IN SYS.ODCINUMBERLIST, -- pode passar NULL; assume 0
  p_id_venda_out OUT NUMBER
)
IS
  v_id_venda      NUMBER;
  v_status        VARCHAR2(20) := 'ABERTA';

  v_preco         NUMBER(12,2);
  v_desc          NUMBER(12,2);
  v_total_item    NUMBER(14,2);

  v_bruto         NUMBER(14,2) := 0;
  v_desc_total    NUMBER(14,2) := 0;
  v_liquido       NUMBER(14,2) := 0;

  v_count         NUMBER;

  PROCEDURE valida_basico IS
  BEGIN
    -- Cliente existe e ativo?
    SELECT COUNT(*) INTO v_count
      FROM tb_cliente
     WHERE id_cliente = p_id_cliente
       AND ativo = 'S';
    IF v_count = 0 THEN
      RAISE_APPLICATION_ERROR(-20001, 'Cliente inexistente ou inativo.');
    END IF;

    -- Vendedor existe e ativo?
    SELECT COUNT(*) INTO v_count
      FROM tb_vendedor
     WHERE id_vendedor = p_id_vendedor
       AND ativo = 'S';
    IF v_count = 0 THEN
      RAISE_APPLICATION_ERROR(-20002, 'Vendedor inexistente ou inativo.');
    END IF;

    -- Canal válido?
    IF p_canal NOT IN ('LOJA','APP','SITE','TELEFONE') THEN
      RAISE_APPLICATION_ERROR(-20003, 'Canal inválido: ' || p_canal);
    END IF;

    -- Arrays consistentes
    IF p_ids_produto.COUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20004, 'Lista de produtos vazia.');
    END IF;

    IF p_ids_produto.COUNT <> p_qtds.COUNT THEN
      RAISE_APPLICATION_ERROR(-20005, 'Produtos e quantidades com tamanhos diferentes.');
    END IF;

    IF p_descs_item IS NOT NULL AND p_descs_item.COUNT <> p_ids_produto.COUNT THEN
      RAISE_APPLICATION_ERROR(-20006, 'Produtos e descontos com tamanhos diferentes.');
    END IF;
  END;
BEGIN
  valida_basico;

  INSERT INTO tb_venda (id_cliente, id_vendedor, dt_venda, status, canal,
                        valor_bruto, desconto_total, valor_liquido)
  VALUES (p_id_cliente, p_id_vendedor, NVL(p_dt_venda, SYSDATE), v_status, p_canal,
          0, 0, 0)
  RETURNING id_venda INTO v_id_venda;

  -- Itens
  FOR i IN 1..p_ids_produto.COUNT LOOP
    IF p_qtds(i) IS NULL OR p_qtds(i) <= 0 THEN
      RAISE_APPLICATION_ERROR(-20007, 'Quantidade inválida no item ' || i);
    END IF;

    -- Produto existe e ativo + pega preço
    SELECT preco_unit INTO v_preco
      FROM tb_produto
     WHERE id_produto = p_ids_produto(i)
       AND ativo = 'S';

    v_desc := 0;
    IF p_descs_item IS NOT NULL AND p_descs_item(i) IS NOT NULL THEN
      v_desc := p_descs_item(i);
      IF v_desc < 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Desconto negativo no item ' || i);
      END IF;
    END IF;

    v_total_item := ROUND((v_preco * p_qtds(i)) - v_desc, 2);
    IF v_total_item < 0 THEN
      RAISE_APPLICATION_ERROR(-20009, 'Desconto maior que o valor do item ' || i);
    END IF;

    INSERT INTO tb_venda_item (id_venda, id_produto, quantidade, preco_unit, desconto_item, valor_total)
    VALUES (v_id_venda, p_ids_produto(i), p_qtds(i), v_preco, v_desc, v_total_item);

    v_bruto := v_bruto + ROUND(v_preco * p_qtds(i), 2);
    v_desc_total := v_desc_total + v_desc;
  END LOOP;

  v_liquido := v_bruto - v_desc_total;

  -- Fecha venda ao final (didático)
  UPDATE tb_venda
     SET status = 'FECHADA',
         valor_bruto = v_bruto,
         desconto_total = v_desc_total,
         valor_liquido = v_liquido
   WHERE id_venda = v_id_venda;

  p_id_venda_out := v_id_venda;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    -- Pode acontecer se produto não existir/ativo
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20010, 'Produto inexistente/inativo em algum item.');
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/
SHOW ERRORS;
