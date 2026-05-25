-- 03_seed_ajustado.sql
-- Dados simulados para Oracle 23ai / APEX
-- Recomendado executar após o script DDL.

-- 1) CATEGORIAS
INSERT INTO tb_categoria (nome) VALUES ('Eletrônicos');
INSERT INTO tb_categoria (nome) VALUES ('Informática');
INSERT INTO tb_categoria (nome) VALUES ('Acessórios');
INSERT INTO tb_categoria (nome) VALUES ('Casa e Cozinha');
INSERT INTO tb_categoria (nome) VALUES ('Escritório');
INSERT INTO tb_categoria (nome) VALUES ('Áudio e Vídeo');
INSERT INTO tb_categoria (nome) VALUES ('Games');
INSERT INTO tb_categoria (nome) VALUES ('Serviços');

COMMIT;

-- 2) PRODUTOS
DECLARE
  v_cat NUMBER;
BEGIN
  FOR i IN 1..30 LOOP
    SELECT id_categoria
    INTO v_cat
    FROM (
      SELECT id_categoria
      FROM tb_categoria
      ORDER BY id_categoria
    )
    WHERE ROWNUM = 1
    OFFSET MOD(i - 1, 8) ROWS FETCH NEXT 1 ROWS ONLY;

    INSERT INTO tb_produto (id_categoria, sku, nome, preco_unit, ativo)
    VALUES (
      v_cat,
      'SKU-' || TO_CHAR(i, 'FM0000'),
      CASE MOD(i - 1, 8) + 1
        WHEN 1 THEN 'Smartphone Modelo ' || i
        WHEN 2 THEN 'Notebook Série ' || i
        WHEN 3 THEN 'Mouse/Teclado Kit ' || i
        WHEN 4 THEN 'Cafeteira/Utensílio ' || i
        WHEN 5 THEN 'Cadeira/Organizador ' || i
        WHEN 6 THEN 'Fone/Soundbar ' || i
        WHEN 7 THEN 'Controle/Jogo ' || i
        ELSE 'Garantia/Instalação ' || i
      END,
      ROUND(DBMS_RANDOM.VALUE(29.90, 7999.90), 2),
      'S'
    );
  END LOOP;
END;
/

COMMIT;

-- 3) VENDEDORES
DECLARE
  TYPE t_arr IS TABLE OF VARCHAR2(50);

  nomes t_arr := t_arr(
    'Ana','Bruno','Carla','Diego','Fernanda','Gustavo','Helena','Igor',
    'Juliana','Kaio','Larissa','Marcos','Natália','Otávio','Patrícia','Rafael'
  );

  sobrenomes t_arr := t_arr(
    'Silva','Souza','Oliveira','Santos','Pereira','Costa','Rodrigues','Almeida',
    'Nogueira','Carvalho','Gomes','Ribeiro','Fernandes','Barbosa','Araújo','Cardoso'
  );

  v_nome VARCHAR2(120);
BEGIN
  DBMS_RANDOM.SEED(12345);

  FOR i IN 1..8 LOOP
    v_nome := nomes(TRUNC(DBMS_RANDOM.VALUE(1, nomes.COUNT + 1))) || ' ' ||
              sobrenomes(TRUNC(DBMS_RANDOM.VALUE(1, sobrenomes.COUNT + 1)));

    INSERT INTO tb_vendedor (nome, email, dt_admissao, ativo)
    VALUES (
      v_nome,
      'vendedor' || TO_CHAR(i, 'FM000') || '@empresa.com',
      TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(30, 1200)),
      'S'
    );
  END LOOP;
END;
/

COMMIT;

-- 4) CLIENTES
DECLARE
  TYPE t_arr IS TABLE OF VARCHAR2(50);

  nomes t_arr := t_arr(
    'Aline','Beatriz','Caio','Daniel','Eduardo','Felipe','Gabriela','Hugo',
    'Isabela','João','Kelly','Lucas','Maria','Nicolas','Olívia','Paulo',
    'Quezia','Renato','Sofia','Tiago','Ursula','Vitor','William','Yasmin'
  );

  sobrenomes t_arr := t_arr(
    'Silva','Souza','Oliveira','Santos','Pereira','Costa','Rodrigues','Almeida',
    'Nogueira','Carvalho','Gomes','Ribeiro','Fernandes','Barbosa','Araújo','Cardoso'
  );

  v_nome VARCHAR2(120);
  v_cpf  VARCHAR2(11);
BEGIN
  DBMS_RANDOM.SEED(54321);

  FOR i IN 1..60 LOOP
    v_nome := nomes(TRUNC(DBMS_RANDOM.VALUE(1, nomes.COUNT + 1))) || ' ' ||
              sobrenomes(TRUNC(DBMS_RANDOM.VALUE(1, sobrenomes.COUNT + 1)));

    v_cpf := LPAD(i, 11, '0');

    INSERT INTO tb_cliente (
      nome, email, cpf, telefone, dt_cadastro, ativo
    )
    VALUES (
      v_nome,
      'cliente' || TO_CHAR(i, 'FM000') || '@email.com',
      v_cpf,
      '(21) 9' ||
      TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000, 9999))) ||
      '-' ||
      TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000, 9999))),
      TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(1, 1500)),
      'S'
    );
  END LOOP;
END;
/

COMMIT;

-- 5) CALENDÁRIO - ÚLTIMOS 24 MESES
DECLARE
  v_dt  DATE := ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -24);
  v_end DATE := ADD_MONTHS(TRUNC(SYSDATE, 'MM'), 1) - 1;
BEGIN
  WHILE v_dt <= v_end LOOP
    INSERT INTO tb_calendario (
      dt_ref, ano, mes, dia, trimestre,
      nome_mes, dia_semana, nome_dia_semana
    )
    VALUES (
      v_dt,
      EXTRACT(YEAR FROM v_dt),
      EXTRACT(MONTH FROM v_dt),
      EXTRACT(DAY FROM v_dt),
      TO_NUMBER(TO_CHAR(v_dt, 'Q')),
      TRIM(TO_CHAR(v_dt, 'MONTH', 'NLS_DATE_LANGUAGE=PORTUGUESE')),
      TO_NUMBER(TO_CHAR(v_dt, 'D')),
      TRIM(TO_CHAR(v_dt, 'DAY', 'NLS_DATE_LANGUAGE=PORTUGUESE'))
    );

    v_dt := v_dt + 1;
  END LOOP;
END;
/

COMMIT;

-- 6) VENDAS + ITENS
DECLARE
  v_id_cliente   NUMBER;
  v_id_vendedor  NUMBER;
  v_dt_venda     DATE;
  v_status       VARCHAR2(20);
  v_canal        VARCHAR2(20);

  v_itens        NUMBER;
  v_id_venda     NUMBER;

  v_id_produto   NUMBER;
  v_qtd          NUMBER;
  v_preco        NUMBER(12,2);
  v_desc_item    NUMBER(12,2);
  v_total_item   NUMBER(14,2);

  v_bruto        NUMBER(14,2);
  v_desc_total   NUMBER(14,2);
  v_liquido      NUMBER(14,2);

  FUNCTION pick_canal RETURN VARCHAR2 IS
    x NUMBER := TRUNC(DBMS_RANDOM.VALUE(1, 5));
  BEGIN
    RETURN CASE x
      WHEN 1 THEN 'LOJA'
      WHEN 2 THEN 'APP'
      WHEN 3 THEN 'SITE'
      ELSE 'TELEFONE'
    END;
  END;

  FUNCTION pick_status RETURN VARCHAR2 IS
    x NUMBER := TRUNC(DBMS_RANDOM.VALUE(1, 101));
  BEGIN
    IF x <= 85 THEN
      RETURN 'FECHADA';
    ELSIF x <= 95 THEN
      RETURN 'CANCELADA';
    ELSE
      RETURN 'ABERTA';
    END IF;
  END;

BEGIN
  DBMS_RANDOM.SEED(20260116);

  FOR s IN 1..200 LOOP

    SELECT id_cliente
    INTO v_id_cliente
    FROM (
      SELECT id_cliente
      FROM tb_cliente
      ORDER BY DBMS_RANDOM.VALUE
    )
    WHERE ROWNUM = 1;

    SELECT id_vendedor
    INTO v_id_vendedor
    FROM (
      SELECT id_vendedor
      FROM tb_vendedor
      ORDER BY DBMS_RANDOM.VALUE
    )
    WHERE ROWNUM = 1;

    v_dt_venda := TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(0, 180));
    v_status   := pick_status();
    v_canal    := pick_canal();

    INSERT INTO tb_venda (
      id_cliente, id_vendedor, dt_venda, status, canal,
      valor_bruto, desconto_total, valor_liquido
    )
    VALUES (
      v_id_cliente, v_id_vendedor, v_dt_venda, v_status, v_canal,
      0, 0, 0
    )
    RETURNING id_venda INTO v_id_venda;

    v_itens      := TRUNC(DBMS_RANDOM.VALUE(1, 6));
    v_bruto      := 0;
    v_desc_total := 0;

    FOR i IN 1..v_itens LOOP

      SELECT id_produto, preco_unit
      INTO v_id_produto, v_preco
      FROM (
        SELECT id_produto, preco_unit
        FROM tb_produto
        WHERE ativo = 'S'
        ORDER BY DBMS_RANDOM.VALUE
      )
      WHERE ROWNUM = 1;

      v_qtd := TRUNC(DBMS_RANDOM.VALUE(1, 6));

      IF DBMS_RANDOM.VALUE(0, 1) < 0.35 THEN
        v_desc_item := ROUND((v_preco * v_qtd) * DBMS_RANDOM.VALUE(0.01, 0.10), 2);
      ELSE
        v_desc_item := 0;
      END IF;

      v_total_item := ROUND((v_preco * v_qtd) - v_desc_item, 2);

      INSERT INTO tb_venda_item (
        id_venda, id_produto, quantidade,
        preco_unit, desconto_item, valor_total
      )
      VALUES (
        v_id_venda, v_id_produto, v_qtd,
        v_preco, v_desc_item, v_total_item
      );

      v_bruto      := v_bruto + ROUND(v_preco * v_qtd, 2);
      v_desc_total := v_desc_total + v_desc_item;

    END LOOP;

    v_liquido := v_bruto - v_desc_total;

    IF v_status = 'CANCELADA' THEN
      v_bruto      := 0;
      v_desc_total := 0;
      v_liquido    := 0;
    END IF;

    UPDATE tb_venda
    SET valor_bruto    = v_bruto,
        desconto_total = v_desc_total,
        valor_liquido  = v_liquido
    WHERE id_venda = v_id_venda;

  END LOOP;
END;
/

COMMIT;
