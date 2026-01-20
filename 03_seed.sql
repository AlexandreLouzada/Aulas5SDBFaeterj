-- 03_seed.sql
-- Dados simulados: clientes, vendedores, categorias, produtos, calendário, vendas e itens.
-- Usa DBMS_RANDOM. Recomendado executar em ambiente de desenvolvimento.

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

-- 2) PRODUTOS (30 itens)
DECLARE
  v_cat NUMBER;
BEGIN
  FOR i IN 1..30 LOOP
    v_cat := MOD(i, 8) + 1;

    INSERT INTO tb_produto (id_categoria, sku, nome, preco_unit, ativo)
    VALUES (
      v_cat,
      'SKU-' || TO_CHAR(i, 'FM0000'),
      CASE v_cat
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

-- 3) VENDEDORES (8)
DECLARE
  TYPE t_arr IS TABLE OF VARCHAR2(50);
  nomes t_arr := t_arr('Ana','Bruno','Carla','Diego','Fernanda','Gustavo','Helena','Igor',
                       'Juliana','Kaio','Larissa','Marcos','Natália','Otávio','Patrícia','Rafael');
  sobrenomes t_arr := t_arr('Silva','Souza','Oliveira','Santos','Pereira','Costa','Rodrigues','Almeida',
                            'Nogueira','Carvalho','Gomes','Ribeiro','Fernandes','Barbosa','Araújo','Cardoso');
  v_nome VARCHAR2(120);
BEGIN
  DBMS_RANDOM.SEED(12345);

  FOR i IN 1..8 LOOP
    v_nome := nomes(TRUNC(DBMS_RANDOM.VALUE(1, nomes.COUNT+1))) || ' ' ||
              sobrenomes(TRUNC(DBMS_RANDOM.VALUE(1, sobrenomes.COUNT+1)));

    INSERT INTO tb_vendedor (nome, email, dt_admissao, ativo)
    VALUES (
      v_nome,
      LOWER(REPLACE(v_nome,' ','_')) || '@empresa.com',
      TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(30, 1200)),
      'S'
    );
  END LOOP;
END;
/
COMMIT;

-- 4) CLIENTES (60)
DECLARE
  TYPE t_arr IS TABLE OF VARCHAR2(50);
  nomes t_arr := t_arr('Aline','Beatriz','Caio','Daniel','Eduardo','Felipe','Gabriela','Hugo',
                       'Isabela','João','Kelly','Lucas','Maria','Nicolas','Olívia','Paulo',
                       'Quezia','Renato','Sofia','Tiago','Ursula','Vitor','William','Yasmin');
  sobrenomes t_arr := t_arr('Silva','Souza','Oliveira','Santos','Pereira','Costa','Rodrigues','Almeida',
                            'Nogueira','Carvalho','Gomes','Ribeiro','Fernandes','Barbosa','Araújo','Cardoso');

  v_nome VARCHAR2(120);
  v_cpf  VARCHAR2(11);
BEGIN
  DBMS_RANDOM.SEED(54321);

  FOR i IN 1..60 LOOP
    v_nome := nomes(TRUNC(DBMS_RANDOM.VALUE(1, nomes.COUNT+1))) || ' ' ||
              sobrenomes(TRUNC(DBMS_RANDOM.VALUE(1, sobrenomes.COUNT+1)));

    -- cpf "simulado" (apenas para fins didáticos)
    v_cpf := LPAD(TRUNC(DBMS_RANDOM.VALUE(100000000, 999999999)), 9, '0') ||
             LPAD(TRUNC(DBMS_RANDOM.VALUE(10, 99)), 2, '0');

    INSERT INTO tb_cliente (nome, email, cpf, telefone, dt_cadastro, ativo)
    VALUES (
      v_nome,
      'cliente' || TO_CHAR(i,'FM000') || '@email.com',
      v_cpf,
      '(21) 9' || TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000, 9999))) || '-' || TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000, 9999))),
      TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(1, 1500)),
      'S'
    );
  END LOOP;
END;
/
COMMIT;

-- 5) CALENDÁRIO (últimos 24 meses)
DECLARE
  v_dt DATE := ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -24);
  v_end DATE := ADD_MONTHS(TRUNC(SYSDATE, 'MM'), 1) - 1;
  v_dow NUMBER;
BEGIN
  WHILE v_dt <= v_end LOOP
    -- Dia da semana: ajustando para 1..7 (Dom..Sáb) via TO_CHAR('D') depende de NLS
    -- Mantemos didático: usa padrão do ambiente.
    v_dow := TO_NUMBER(TO_CHAR(v_dt, 'D'));

    INSERT INTO tb_calendario (dt_ref, ano, mes, dia, trimestre, nome_mes, dia_semana, nome_dia_semana)
    VALUES (
      v_dt,
      EXTRACT(YEAR FROM v_dt),
      EXTRACT(MONTH FROM v_dt),
      EXTRACT(DAY FROM v_dt),
      TO_NUMBER(TO_CHAR(v_dt, 'Q')),
      TRIM(TO_CHAR(v_dt, 'MONTH')),
      v_dow,
      TRIM(TO_CHAR(v_dt, 'DAY'))
    );

    v_dt := v_dt + 1;
  END LOOP;
END;
/
COMMIT;

-- 6) VENDAS + ITENS (200 vendas / 1..5 itens por venda)
DECLARE
  v_id_cliente  NUMBER;
  v_id_vendedor NUMBER;
  v_dt_venda    DATE;
  v_status      VARCHAR2(20);
  v_canal       VARCHAR2(20);

  v_itens       NUMBER;
  v_id_venda    NUMBER;

  v_id_produto  NUMBER;
  v_qtd         NUMBER;
  v_preco       NUMBER(12,2);
  v_desc_item   NUMBER(12,2);
  v_total_item  NUMBER(14,2);

  v_bruto       NUMBER(14,2);
  v_desc_total  NUMBER(14,2);
  v_liquido     NUMBER(14,2);

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
    -- 85% fechadas, 10% canceladas, 5% abertas
    IF x <= 85 THEN RETURN 'FECHADA';
    ELSIF x <= 95 THEN RETURN 'CANCELADA';
    ELSE RETURN 'ABERTA';
    END IF;
  END;

BEGIN
  DBMS_RANDOM.SEED(20260116);

  FOR s IN 1..200 LOOP
    v_id_cliente  := TRUNC(DBMS_RANDOM.VALUE(1, 61)); -- 60 clientes
    v_id_vendedor := TRUNC(DBMS_RANDOM.VALUE(1, 9));  -- 8 vendedores
    v_dt_venda    := TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(0, 180));
    v_status      := pick_status();
    v_canal       := pick_canal();

    INSERT INTO tb_venda (id_cliente, id_vendedor, dt_venda, status, canal, valor_bruto, desconto_total, valor_liquido)
    VALUES (v_id_cliente, v_id_vendedor, v_dt_venda, v_status, v_canal, 0, 0, 0)
    RETURNING id_venda INTO v_id_venda;

    v_itens := TRUNC(DBMS_RANDOM.VALUE(1, 6)); -- 1..5 itens
    v_bruto := 0;
    v_desc_total := 0;

    FOR i IN 1..v_itens LOOP
      v_id_produto := TRUNC(DBMS_RANDOM.VALUE(1, 31)); -- 30 produtos
      v_qtd        := TRUNC(DBMS_RANDOM.VALUE(1, 6));  -- 1..5

      SELECT preco_unit INTO v_preco
      FROM tb_produto
      WHERE id_produto = v_id_produto;

      -- desconto item: até 10% do valor do item, ocasional
      IF DBMS_RANDOM.VALUE(0, 1) < 0.35 THEN
        v_desc_item := ROUND((v_preco * v_qtd) * DBMS_RANDOM.VALUE(0.01, 0.10), 2);
      ELSE
        v_desc_item := 0;
      END IF;

      v_total_item := ROUND((v_preco * v_qtd) - v_desc_item, 2);

      INSERT INTO tb_venda_item (id_venda, id_produto, quantidade, preco_unit, desconto_item, valor_total)
      VALUES (v_id_venda, v_id_produto, v_qtd, v_preco, v_desc_item, v_total_item);

      v_bruto := v_bruto + ROUND(v_preco * v_qtd, 2);
      v_desc_total := v_desc_total + v_desc_item;
    END LOOP;

    v_liquido := v_bruto - v_desc_total;

    -- Se CANCELADA, zera valores (didático)
    IF v_status = 'CANCELADA' THEN
      v_bruto := 0; v_desc_total := 0; v_liquido := 0;
    END IF;

    UPDATE tb_venda
    SET valor_bruto = v_bruto,
        desconto_total = v_desc_total,
        valor_liquido = v_liquido
    WHERE id_venda = v_id_venda;

  END LOOP;
END;
/
COMMIT;
