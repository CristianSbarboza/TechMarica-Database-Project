DROP DATABASE TechMaricaDB;
CREATE DATABASE IF NOT EXISTS TechMaricaDB;
USE TechMaricaDB;

CREATE TABLE Funcionarios (
    id_func INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    area_atuacao VARCHAR(50) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE Maquinas (
    id_maquina INT AUTO_INCREMENT PRIMARY KEY,
    nome_maquina VARCHAR(50) NOT NULL,
    modelo VARCHAR(50),
    localizacao VARCHAR(50)
);

CREATE TABLE Produtos (
    id_produto INT AUTO_INCREMENT PRIMARY KEY,
    codigo_interno VARCHAR(20) UNIQUE NOT NULL,
    nome_comercial VARCHAR(100) NOT NULL,
    responsavel_tecnico VARCHAR(100) NOT NULL,
    custo_estimado DECIMAL(10, 2) NOT NULL,
    data_cadastro DATE DEFAULT (CURRENT_DATE) 
);

CREATE TABLE OrdensProducao (
    id_ordem INT AUTO_INCREMENT PRIMARY KEY,
    id_produto INT NOT NULL,
    id_maquina INT NOT NULL,
    id_funcionario INT NOT NULL,
    data_inicio DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_conclusao DATETIME NULL,
    status VARCHAR(20) DEFAULT 'AGUARDANDO',
    
    CONSTRAINT fk_ordem_produto FOREIGN KEY (id_produto) REFERENCES Produtos(id_produto),
    CONSTRAINT fk_ordem_maquina FOREIGN KEY (id_maquina) REFERENCES Maquinas(id_maquina),
    CONSTRAINT fk_ordem_func FOREIGN KEY (id_funcionario) REFERENCES Funcionarios(id_func)
);

INSERT INTO Funcionarios (nome, area_atuacao, ativo) VALUES
('Marcio Garrido', 'Engenharia', TRUE),
('Fabricio Dias', 'Supervisão de Linha', TRUE),
('Thiago Bombista', 'Manutenção', FALSE),
('Douglas Barboza', 'Qualidade', TRUE),
('Christiane Martins', 'Logística', TRUE);

INSERT INTO Maquinas (nome_maquina, modelo, localizacao) VALUES
('Soldadora Wave', 'SW-2000', 'Setor A'),
('Montadora SMD', 'PickPlace-X', 'Setor B'),
('Estufa de Cura', 'HeatMaster 500', 'Setor C');

INSERT INTO Produtos (codigo_interno, nome_comercial, responsavel_tecnico, custo_estimado, data_cadastro) VALUES
('TM-001', 'Sensor de Umidade IoT', 'Douglas Barboza', 45.50, '2020-01-15'),
('TM-002', 'Módulo GPS Maricá', 'Marcio Garrido', 120.00, '2021-05-20'),
('TM-003', 'Placa Controladora V2', 'Marcio Garrido', 85.90, '2022-03-10'),
('TM-004', 'Display OLED 5pol', 'Fabricio Dias', 200.00, '2023-08-01'),
('TM-005', 'Bateria Lítio Tech', 'Christiane Martins', 35.00, '2023-12-10');

INSERT INTO OrdensProducao (id_produto, id_maquina, id_funcionario, data_inicio, status) VALUES
(1, 2, 1, '2024-01-10 08:00:00', 'FINALIZADA'),
(2, 1, 2, '2024-02-15 09:30:00', 'EM PRODUÇÃO'),
(3, 3, 4, '2024-03-01 10:00:00', 'AGUARDANDO'),
(4, 2, 1, '2024-03-05 14:00:00', 'EM PRODUÇÃO'),
(1, 1, 2, '2024-03-10 16:00:00', 'FINALIZADA');


-- Consultadas avançadas
SELECT 
    OP.id_ordem,
    P.nome_comercial AS Produto,
    M.nome_maquina AS Maquina,
    F.nome AS Autorizado_Por,
    DATE_FORMAT(OP.data_inicio, '%d/%m/%Y %H:%i') AS Data_Inicio,
    OP.status
FROM OrdensProducao OP
JOIN Produtos P ON OP.id_produto = P.id_produto
JOIN Maquinas M ON OP.id_maquina = M.id_maquina
JOIN Funcionarios F ON OP.id_funcionario = F.id_func;


SELECT * FROM Funcionarios WHERE ativo = FALSE;

SELECT 
    responsavel_tecnico, 
    COUNT(*) AS total_produtos
FROM Produtos
GROUP BY responsavel_tecnico;

SELECT * FROM Produtos WHERE nome_comercial LIKE 'S%';

SELECT 
    nome_comercial,
    data_cadastro,
    TIMESTAMPDIFF(YEAR, data_cadastro, CURDATE()) AS anos_catalogo
FROM Produtos;

-- view

CREATE OR REPLACE VIEW vw_PainelProducao AS
SELECT 
    OP.id_ordem,
    P.nome_comercial AS Produto,
    P.custo_estimado,
    M.nome_maquina,
    F.nome AS Supervisor,
    OP.status,
    CASE 
        WHEN OP.status = 'FINALIZADA' THEN 'Lote Pronto'
        WHEN OP.status = 'EM PRODUÇÃO' THEN 'Em Andamento'
        ELSE 'Na Fila'
    END AS Situacao_Gerencial
FROM OrdensProducao OP
JOIN Produtos P ON OP.id_produto = P.id_produto
JOIN Maquinas M ON OP.id_maquina = M.id_maquina
JOIN Funcionarios F ON OP.id_funcionario = F.id_func;

-- sera que vai?
SELECT * FROM vw_PainelProducao;


DELIMITER $$
CREATE PROCEDURE sp_NovaOrdemProducao (
    IN p_id_produto INT,
    IN p_id_funcionario INT,
    IN p_id_maquina INT
)
BEGIN
    INSERT INTO OrdensProducao (id_produto, id_maquina, id_funcionario, data_inicio, status)
    VALUES (p_id_produto, p_id_maquina, p_id_funcionario, NOW(), 'EM PRODUÇÃO');

    SELECT CONCAT('Ordem de Produção para o produto ID ', p_id_produto, ' criada com sucesso!') AS Mensagem;
END $$

DELIMITER ;

CALL sp_NovaOrdemProducao(3, 2, 1);


-- Trigger

DELIMITER $$
CREATE TRIGGER trg_FinalizaOrdem
BEFORE UPDATE ON OrdensProducao
FOR EACH ROW
BEGIN
    IF OLD.data_conclusao IS NULL AND NEW.data_conclusao IS NOT NULL THEN
        SET NEW.status = 'FINALIZADA';
    END IF;
END $$

DELIMITER ;

SELECT id_ordem, status, data_conclusao FROM OrdensProducao WHERE id_ordem = 2;

UPDATE OrdensProducao SET data_conclusao = NOW() WHERE id_ordem = 2;

SELECT id_ordem, status, data_conclusao FROM OrdensProducao WHERE id_ordem = 2;