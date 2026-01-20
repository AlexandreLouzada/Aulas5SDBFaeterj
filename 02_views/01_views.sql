-- 02_views/01_views.sql

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
