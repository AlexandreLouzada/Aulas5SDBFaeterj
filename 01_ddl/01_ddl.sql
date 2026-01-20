-- 02_ddl.sql
-- Modelo físico: Vendas e Análise Comercial (Oracle 23ai)
-- Compatível com SQL Developer e Oracle APEX.

-- =========================
-- TABELAS MESTRAS
-- =========================

CREATE TABLE tb_cliente (
  id_cliente       NUMBER GENERATED ALWAYS AS IDENTITY,
  nome             VARCHAR2(120) NOT NULL,
  email            VARCHAR2(120) NOT NULL,
  cpf              VARCHAR2(11)  NOT NULL,
  telefone         VARCHAR2(20),
  dt_cadastro      DATE DEFAULT SYSDATE NOT NULL,
  ativo            CHAR(1) DEFAULT 'S' NOT NULL,
  CONSTRAINT pk_tb_cliente PRIMARY KEY (id_cliente),
  CONSTRAINT uq_tb_cliente_email UNIQUE (email),
  CONSTRAINT uq_tb_cliente_cpf   UNIQUE (cpf),
  CONSTRAINT ck_tb_cliente_ativo CHECK (ativo IN ('S','N'))
);

CREATE TABLE tb_vendedor (
  id_vendedor      NUMBER GENERATED ALWAYS AS IDENTITY,
  nome             VARCHAR2(120) NOT NULL,
  email            VARCHAR2(120) NOT NULL,
  dt_admissao      DATE DEFAULT (TRUNC(SYSDATE) - 365) NOT NULL,
  ativo            CHAR(1) DEFAULT 'S' NOT NULL,
  CONSTRAINT pk_tb_vendedor PRIMARY KEY (id_vendedor),
  CONSTRAINT uq_tb_vendedor_email UNIQUE (email),
  CONSTRAINT ck_tb_vendedor_ativo CHECK (ativo IN ('S','N'))
);

CREATE TABLE tb_categoria (
  id_categoria     NUMBER GENERATED ALWAYS AS IDENTITY,
  nome             VARCHAR2(80) NOT NULL,
  CONSTRAINT pk_tb_categoria PRIMARY KEY (id_categoria),
  CONSTRAINT uq_tb_categoria_nome UNIQUE (nome)
);

CREATE TABLE tb_produto (
  id_produto       NUMBER GENERATED ALWAYS AS IDENTITY,
  id_categoria     NUMBER NOT NULL,
  sku              VARCHAR2(30) NOT NULL,
  nome             VARCHAR2(120) NOT NULL,
  preco_unit       NUMBER(12,2) NOT NULL,
  ativo            CHAR(1) DEFAULT 'S' NOT NULL,
  dt_cadastro      DATE DEFAULT SYSDATE NOT NULL,
  CONSTRAINT pk_tb_produto PRIMARY KEY (id_produto),
  CONSTRAINT uq_tb_produto_sku UNIQUE (sku),
  CONSTRAINT ck_tb_produto_preco CHECK (preco_unit > 0),
  CONSTRAINT ck_tb_produto_ativo CHECK (ativo IN ('S','N')),
  CONSTRAINT fk_tb_produto_categoria
    FOREIGN KEY (id_categoria) REFERENCES tb_categoria (id_categoria)
);

-- =========================
-- TABELAS TRANSACIONAIS
-- =========================

CREATE TABLE tb_venda (
  id_venda         NUMBER GENERATED ALWAYS AS IDENTITY,
  id_cliente       NUMBER NOT NULL,
  id_vendedor      NUMBER NOT NULL,
  dt_venda         DATE DEFAULT SYSDATE NOT NULL,
  status           VARCHAR2(20) DEFAULT 'FECHADA' NOT NULL,
  canal            VARCHAR2(20) DEFAULT 'LOJA' NOT NULL,
  valor_bruto      NUMBER(14,2) DEFAULT 0 NOT NULL,
  desconto_total   NUMBER(14,2) DEFAULT 0 NOT NULL,
  valor_liquido    NUMBER(14,2) DEFAULT 0 NOT NULL,
  CONSTRAINT pk_tb_venda PRIMARY KEY (id_venda),
  CONSTRAINT fk_tb_venda_cliente  FOREIGN KEY (id_cliente)  REFERENCES tb_cliente (id_cliente),
  CONSTRAINT fk_tb_venda_vendedor FOREIGN KEY (id_vendedor) REFERENCES tb_vendedor (id_vendedor),
  CONSTRAINT ck_tb_venda_status CHECK (status IN ('ABERTA','FECHADA','CANCELADA')),
  CONSTRAINT ck_tb_venda_canal  CHECK (canal  IN ('LOJA','APP','SITE','TELEFONE')),
  CONSTRAINT ck_tb_venda_valores CHECK (valor_bruto >= 0 AND desconto_total >= 0 AND valor_liquido >= 0)
);

CREATE TABLE tb_venda_item (
  id_item          NUMBER GENERATED ALWAYS AS IDENTITY,
  id_venda         NUMBER NOT NULL,
  id_produto       NUMBER NOT NULL,
  quantidade       NUMBER(10) NOT NULL,
  preco_unit       NUMBER(12,2) NOT NULL,
  desconto_item    NUMBER(12,2) DEFAULT 0 NOT NULL,
  valor_total      NUMBER(14,2) NOT NULL,
  CONSTRAINT pk_tb_venda_item PRIMARY KEY (id_item),
  CONSTRAINT fk_tb_item_venda   FOREIGN KEY (id_venda)   REFERENCES tb_venda (id_venda) ON DELETE CASCADE,
  CONSTRAINT fk_tb_item_produto FOREIGN KEY (id_produto) REFERENCES tb_produto (id_produto),
  CONSTRAINT ck_tb_item_qtd CHECK (quantidade > 0),
  CONSTRAINT ck_tb_item_preco CHECK (preco_unit > 0),
  CONSTRAINT ck_tb_item_desc CHECK (desconto_item >= 0),
  CONSTRAINT ck_tb_item_total CHECK (valor_total >= 0)
);

-- =========================
-- TABELA AUXILIAR (CALENDÁRIO)
-- =========================

CREATE TABLE tb_calendario (
  dt_ref           DATE NOT NULL,
  ano              NUMBER(4) NOT NULL,
  mes              NUMBER(2) NOT NULL,
  dia              NUMBER(2) NOT NULL,
  trimestre        NUMBER(1) NOT NULL,
  nome_mes         VARCHAR2(15) NOT NULL,
  dia_semana       NUMBER(1) NOT NULL, -- 1=Dom .. 7=Sáb (ajustável)
  nome_dia_semana  VARCHAR2(15) NOT NULL,
  CONSTRAINT pk_tb_calendario PRIMARY KEY (dt_ref)
);

-- =========================
-- AUDITORIA (para usar nas aulas de Trigger)
-- =========================

CREATE TABLE tb_auditoria_venda (
  id_auditoria     NUMBER GENERATED ALWAYS AS IDENTITY,
  id_venda         NUMBER,
  operacao         VARCHAR2(10) NOT NULL, -- INSERT/UPDATE/DELETE
  usuario_bd       VARCHAR2(128) DEFAULT USER NOT NULL,
  dt_evento        TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
  detalhes         VARCHAR2(4000),
  CONSTRAINT pk_tb_auditoria_venda PRIMARY KEY (id_auditoria)
);

-- =========================
-- ÍNDICES (performance realista)
-- =========================

CREATE INDEX ix_venda_dt       ON tb_venda (dt_venda);
CREATE INDEX ix_venda_cliente  ON tb_venda (id_cliente);
CREATE INDEX ix_venda_vendedor ON tb_venda (id_vendedor);

CREATE INDEX ix_item_venda     ON tb_venda_item (id_venda);
CREATE INDEX ix_item_produto   ON tb_venda_item (id_produto);

CREATE INDEX ix_prod_categoria ON tb_produto (id_categoria);

-- =========================
-- VIEWS (DEV + DADOS)
-- =========================

-- View resumo de vendas (boa para relatórios e APIs)
CREATE OR REPLACE VIEW v_vendas_resumo AS
SELECT
  v.id_venda,
  v.dt_venda,
  v.status,
  v.canal,
  c.id_cliente,
  c.nome  AS cliente_nome,
  ven.id_vendedor,
  ven.nome AS vendedor_nome,
  v.valor_bruto,
  v.desconto_total,
  v.valor_liquido
FROM tb_venda v
JOIN tb_cliente  c   ON c.id_cliente = v.id_cliente
JOIN tb_vendedor ven ON ven.id_vendedor = v.id_vendedor;

-- View analítica por categoria (base para dashboards)
CREATE OR REPLACE VIEW v_vendas_por_categoria AS
SELECT
  TRUNC(v.dt_venda, 'MM') AS mes_ref,
  cat.nome AS categoria,
  SUM(i.quantidade) AS qtd_itens,
  SUM(i.valor_total) AS receita_total
FROM tb_venda v
JOIN tb_venda_item i ON i.id_venda = v.id_venda
JOIN tb_produto p    ON p.id_produto = i.id_produto
JOIN tb_categoria cat ON cat.id_categoria = p.id_categoria
WHERE v.status = 'FECHADA'
GROUP BY TRUNC(v.dt_venda, 'MM'), cat.nome;

-- View para ranking (funções analíticas)
CREATE OR REPLACE VIEW v_rank_vendedores_mes AS
SELECT
  TRUNC(v.dt_venda, 'MM') AS mes_ref,
  ven.nome AS vendedor,
  SUM(v.valor_liquido) AS receita,
  DENSE_RANK() OVER (PARTITION BY TRUNC(v.dt_venda, 'MM')
                     ORDER BY SUM(v.valor_liquido) DESC) AS posicao
FROM tb_venda v
JOIN tb_vendedor ven ON ven.id_vendedor = v.id_vendedor
WHERE v.status = 'FECHADA'
GROUP BY TRUNC(v.dt_venda, 'MM'), ven.nome;
