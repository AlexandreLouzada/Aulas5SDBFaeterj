-- 02_views/02_views_apex.sql
-- Views e dimensões para APEX (filtros, dashboards, relatórios)

-- 1) Dimensão tempo (já existe tb_calendario; esta view deixa pronto p/ filtros)
CREATE OR REPLACE VIEW v_dim_tempo AS
SELECT
  dt_ref,
  ano,
  mes,
  dia,
  trimestre,
  INITCAP(TRIM(nome_mes)) AS nome_mes,
  dia_semana,
  INITCAP(TRIM(nome_dia_semana)) AS nome_dia_semana,
  TO_CHAR(dt_ref, 'YYYY-MM') AS ano_mes,
  TO_CHAR(dt_ref, 'YYYY-"T"Q') AS ano_trim
FROM tb_calendario;

-- 2) Dimensão cliente (campos úteis para busca e filtros)
CREATE OR REPLACE VIEW v_dim_cliente AS
SELECT
  id_cliente,
  nome,
  email,
  cpf,
  telefone,
  dt_cadastro,
  ativo
FROM tb_cliente;

-- 3) Dimensão vendedor
CREATE OR REPLACE VIEW v_dim_vendedor AS
SELECT
  id_vendedor,
  nome,
  email,
  dt_admissao,
  ativo
FROM tb_vendedor;

-- 4) Dimensão produto (inclui categoria para relatórios)
CREATE OR REPLACE VIEW v_dim_produto AS
SELECT
  p.id_produto,
  p.sku,
  p.nome AS produto,
  p.preco_unit,
  p.ativo,
  p.dt_cadastro,
  c.id_categoria,
  c.nome AS categoria
FROM tb_produto p
JOIN tb_categoria c ON c.id_categoria = p.id_categoria;

-- 5) Fato venda (cabeçalho) - APEX-friendly
CREATE OR REPLACE VIEW v_fato_venda AS
SELECT
  v.id_venda,
  v.dt_venda,
  TRUNC(v.dt_venda) AS dt_venda_dia,
  TRUNC(v.dt_venda, 'MM') AS dt_venda_mes,
  v.status,
  v.canal,
  v.id_cliente,
  v.id_vendedor,
  v.valor_bruto,
  v.desconto_total,
  v.valor_liquido
FROM tb_venda v;

-- 6) Fato itens (detalhe) - APEX-friendly
CREATE OR REPLACE VIEW v_fato_venda_item AS
SELECT
  i.id_item,
  i.id_venda,
  i.id_produto,
  i.quantidade,
  i.preco_unit,
  i.desconto_item,
  i.valor_total
FROM tb_venda_item i;

-- 7) “Flat view” para relatórios (junção pronta: venda + cliente + vendedor + produto + categoria)
-- Útil para Interactive Report/Interactive Grid
CREATE OR REPLACE VIEW v_rel_vendas_flat AS
SELECT
  v.id_venda,
  v.dt_venda,
  TRUNC(v.dt_venda, 'MM') AS mes_ref,
  v.status,
  v.canal,

  c.id_cliente,
  c.nome AS cliente,
  c.email AS cliente_email,

  ven.id_vendedor,
  ven.nome AS vendedor,

  i.id_item,
  i.quantidade,
  i.preco_unit,
  i.desconto_item,
  i.valor_total,

  p.id_produto,
  p.sku,
  p.nome AS produto,
  cat.id_categoria,
  cat.nome AS categoria
FROM tb_venda v
JOIN tb_cliente c       ON c.id_cliente = v.id_cliente
JOIN tb_vendedor ven    ON ven.id_vendedor = v.id_vendedor
JOIN tb_venda_item i    ON i.id_venda = v.id_venda
JOIN tb_produto p       ON p.id_produto = i.id_produto
JOIN tb_categoria cat   ON cat.id_categoria = p.id_categoria;

-- 8) KPIs prontos (para Cards no APEX)
-- KPIs: hoje, 7 dias, 30 dias, mês atual
CREATE OR REPLACE VIEW v_kpi_vendas AS
SELECT
  SUM(CASE WHEN v.status='FECHADA' AND TRUNC(v.dt_venda)=TRUNC(SYSDATE) THEN v.valor_liquido ELSE 0 END) AS receita_hoje,
  SUM(CASE WHEN v.status='FECHADA' AND v.dt_venda>=TRUNC(SYSDATE)-7 THEN v.valor_liquido ELSE 0 END)   AS receita_7d,
  SUM(CASE WHEN v.status='FECHADA' AND v.dt_venda>=TRUNC(SYSDATE)-30 THEN v.valor_liquido ELSE 0 END)  AS receita_30d,
  SUM(CASE WHEN v.status='FECHADA' AND TRUNC(v.dt_venda,'MM')=TRUNC(SYSDATE,'MM') THEN v.valor_liquido ELSE 0 END) AS receita_mes_atual,
  COUNT(CASE WHEN v.status='FECHADA' AND TRUNC(v.dt_venda,'MM')=TRUNC(SYSDATE,'MM') THEN 1 END) AS qtd_vendas_mes_atual
FROM tb_venda v;

-- 9) Série temporal (linha/área) - Receita por dia (últimos 30 dias)
CREATE OR REPLACE VIEW v_serie_receita_dia_30d AS
SELECT
  t.dt_ref AS dia,
  NVL(SUM(v.valor_liquido), 0) AS receita
FROM v_dim_tempo t
LEFT JOIN tb_venda v
  ON TRUNC(v.dt_venda) = t.dt_ref
 AND v.status = 'FECHADA'
WHERE t.dt_ref BETWEEN TRUNC(SYSDATE)-30 AND TRUNC(SYSDATE)
GROUP BY t.dt_ref
ORDER BY t.dt_ref;

-- 10) Barras: Receita por categoria (mês atual)
CREATE OR REPLACE VIEW v_receita_categoria_mes_atual AS
SELECT
  cat.nome AS categoria,
  SUM(i.valor_total) AS receita
FROM tb_venda v
JOIN tb_venda_item i  ON i.id_venda = v.id_venda
JOIN tb_produto p     ON p.id_produto = i.id_produto
JOIN tb_categoria cat ON cat.id_categoria = p.id_categoria
WHERE v.status='FECHADA'
  AND TRUNC(v.dt_venda,'MM')=TRUNC(SYSDATE,'MM')
GROUP BY cat.nome
ORDER BY receita DESC;

-- 11) Top 10 clientes (mês atual)
CREATE OR REPLACE VIEW v_top_clientes_mes_atual AS
SELECT
  c.nome AS cliente,
  SUM(v.valor_liquido) AS receita
FROM tb_venda v
JOIN tb_cliente c ON c.id_cliente = v.id_cliente
WHERE v.status='FECHADA'
  AND TRUNC(v.dt_venda,'MM')=TRUNC(SYSDATE,'MM')
GROUP BY c.nome
ORDER BY receita DESC
FETCH FIRST 10 ROWS ONLY;
