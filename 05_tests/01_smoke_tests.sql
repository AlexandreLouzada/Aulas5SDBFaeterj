-- 05_tests/01_smoke_tests.sql

-- 1) Conferir volume básico
SELECT (SELECT COUNT(*) FROM tb_cliente)   AS clientes,
       (SELECT COUNT(*) FROM tb_vendedor)  AS vendedores,
       (SELECT COUNT(*) FROM tb_categoria) AS categorias,
       (SELECT COUNT(*) FROM tb_produto)   AS produtos,
       (SELECT COUNT(*) FROM tb_venda)     AS vendas,
       (SELECT COUNT(*) FROM tb_venda_item) AS itens
FROM dual;

-- 2) Receita por status
SELECT status, COUNT(*) qtd, SUM(valor_liquido) receita
FROM tb_venda
GROUP BY status
ORDER BY 2 DESC;

-- 3) Auditoria (se trigger estiver criada, aqui cresce ao mexer em tb_venda)
SELECT * FROM tb_auditoria_venda
ORDER BY dt_evento DESC
FETCH FIRST 20 ROWS ONLY;
