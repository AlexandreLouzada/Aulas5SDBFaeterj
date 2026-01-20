-- 04_plsql/03_triggers.sql

-- 1) Auditoria de TB_VENDA
CREATE OR REPLACE TRIGGER trg_aud_tb_venda
AFTER INSERT OR UPDATE OR DELETE ON tb_venda
FOR EACH ROW
DECLARE
  v_op VARCHAR2(10);
  v_det VARCHAR2(4000);
BEGIN
  IF INSERTING THEN
    v_op := 'INSERT';
    v_det := 'Venda criada. Status=' || :NEW.status || ', Canal=' || :NEW.canal ||
             ', Cliente=' || :NEW.id_cliente || ', Vendedor=' || :NEW.id_vendedor ||
             ', Liquido=' || :NEW.valor_liquido;
    INSERT INTO tb_auditoria_venda (id_venda, operacao, detalhes)
    VALUES (:NEW.id_venda, v_op, v_det);

  ELSIF UPDATING THEN
    v_op := 'UPDATE';
    v_det := 'Status: ' || :OLD.status || ' -> ' || :NEW.status ||
             ' | Canal: ' || :OLD.canal || ' -> ' || :NEW.canal ||
             ' | Liquido: ' || :OLD.valor_liquido || ' -> ' || :NEW.valor_liquido;
    INSERT INTO tb_auditoria_venda (id_venda, operacao, detalhes)
    VALUES (:NEW.id_venda, v_op, v_det);

  ELSIF DELETING THEN
    v_op := 'DELETE';
    v_det := 'Venda removida. Status=' || :OLD.status || ', Canal=' || :OLD.canal ||
             ', Cliente=' || :OLD.id_cliente || ', Vendedor=' || :OLD.id_vendedor ||
             ', Liquido=' || :OLD.valor_liquido;
    INSERT INTO tb_auditoria_venda (id_venda, operacao, detalhes)
    VALUES (:OLD.id_venda, v_op, v_det);
  END IF;
END;
/
SHOW ERRORS;

-- 2) Recalcular totais da venda quando alterar itens
CREATE OR REPLACE TRIGGER trg_recalc_totais_venda
AFTER INSERT OR UPDATE OR DELETE ON tb_venda_item
FOR EACH ROW
DECLARE
  v_id_venda NUMBER;
  v_bruto    NUMBER(14,2);
  v_desc     NUMBER(14,2);
  v_liq      NUMBER(14,2);
BEGIN
  v_id_venda := NVL(:NEW.id_venda, :OLD.id_venda);

  SELECT NVL(SUM(preco_unit * quantidade),0),
         NVL(SUM(desconto_item),0),
         NVL(SUM(valor_total),0)
    INTO v_bruto, v_desc, v_liq
    FROM tb_venda_item
   WHERE id_venda = v_id_venda;

  UPDATE tb_venda
     SET valor_bruto = v_bruto,
         desconto_total = v_desc,
         valor_liquido = v_liq
   WHERE id_venda = v_id_venda;

END;
/
SHOW ERRORS;
