-- Total de vendas por status
SELECT status, COUNT(*) qtd, SUM(valor_liquido) receita
FROM tb_venda
GROUP BY status
ORDER BY 2 DESC;

-- Top 10 clientes por receita
SELECT cliente_nome, SUM(valor_liquido) receita
FROM v_vendas_resumo
WHERE status = 'FECHADA'
GROUP BY cliente_nome
ORDER BY receita DESC
FETCH FIRST 10 ROWS ONLY;

-- Receita por categoria/mês (para dashboard)
SELECT * FROM v_vendas_por_categoria
ORDER BY mes_ref DESC, receita_total DESC;
