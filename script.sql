CREATE SCHEMA uni7_bd1;
USE uni7_bd1;

# ---------------------------
-- Criação Tabelas
# ---------------------------

CREATE TABLE Cliente (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Telefone VARCHAR(15)
);

CREATE TABLE Jogo (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Preco DECIMAL(10, 2) NOT NULL,
    Categoria VARCHAR(50),
    Estoque INT NOT NULL
);

CREATE TABLE Funcionario (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Nome VARCHAR(50),
    Salario DECIMAL(10, 2)
);

CREATE TABLE Venda (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Data DATETIME DEFAULT CURRENT_TIMESTAMP,
    Total DECIMAL(10, 2),
    ClienteID INT,
    FuncionarioID INT,
    FOREIGN KEY (ClienteID) REFERENCES Cliente(ID),
    FOREIGN KEY (FuncionarioID) REFERENCES Funcionario(ID)
);

CREATE TABLE ItemVenda (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    VendaID INT,
    JogoID INT,
    Quantidade INT NOT NULL,
    Subtotal DECIMAL(10, 2),
    FOREIGN KEY (VendaID) REFERENCES Venda(ID),
    FOREIGN KEY (JogoID) REFERENCES Jogo(ID)
);

# ---------------------------
-- Criação Trigger
# ---------------------------

-- Trigger: Atualizar Valor Total Venda
DELIMITER $$
-- Trigger para INSERT
CREATE TRIGGER AtualizarTotalVenda_Insert
AFTER INSERT ON ItemVenda
FOR EACH ROW
BEGIN
    UPDATE Venda
    SET Total = (
        SELECT SUM(Subtotal)
        FROM ItemVenda 
        WHERE VendaID = NEW.VendaID
    )
    WHERE ID = NEW.VendaID;
END$$

-- Trigger para UPDATE
CREATE TRIGGER AtualizarTotalVenda_Update
AFTER UPDATE ON ItemVenda
FOR EACH ROW
BEGIN
    UPDATE Venda
    SET Total = (
        SELECT SUM(Subtotal)
        FROM ItemVenda 
        WHERE VendaID = OLD.VendaID
    )
    WHERE ID = OLD.VendaID;
END$$

-- Trigger para DELETE
CREATE TRIGGER AtualizarTotalVenda_Delete
AFTER DELETE ON ItemVenda
FOR EACH ROW
BEGIN
    UPDATE Venda
    SET Total = (
        SELECT SUM(Subtotal)
        FROM ItemVenda 
        WHERE VendaID = OLD.VendaID
    )
    WHERE ID = OLD.VendaID;
END$$
DELIMITER ;

# ---------------------------
-- Criação PROCEDURE
# ---------------------------

-- Procedure: Alimentar tabela de Itens da Venda
DELIMITER $$
CREATE PROCEDURE AlimentarVendaItem(vendaID INT)
BEGIN
	DECLARE i INT DEFAULT 1;
    DECLARE jogoID INT;
    
    WHILE i <= 2 DO
    
		SET jogoID = (SELECT ID FROM Jogo ORDER BY RAND() LIMIT 1);
        
        INSERT INTO ItemVenda (VendaID, JogoID, Quantidade, Subtotal) VALUES
				(vendaID, jogoID, 1, (SELECT Preco FROM Jogo WHERE ID = jogoID));
        SET i = i + 1;
    END WHILE;

END$$
DELIMITER ;

-- Procedure: Alimentar dados nas Tabelas
DELIMITER $$
CREATE PROCEDURE AlimentarDados()
BEGIN
    
    DECLARE i INT DEFAULT 1;
    DECLARE cliente INT DEFAULT 1;
    DECLARE funcionario INT DEFAULT 1;
    
    -- Inserir 20 registros na tabela Cliente
    WHILE i <= 20 DO
        INSERT INTO Cliente (Nome, Email, Telefone) VALUES
        (CONCAT('Cliente ', i), CONCAT('cliente', i, '@email.com'), CONCAT('99999', LPAD(i, 5, '0')));
        SET i = i + 1;
    END WHILE;

    -- Inserir 20 registros na tabela Funcionário
    SET i = 1;
    WHILE i <= 20 DO
        INSERT INTO Funcionario (Nome, Salario) VALUES
        (CONCAT('Funcionário ', i), RAND() * 500);
        SET i = i + 1;
    END WHILE;

    -- Inserir 20 registros na tabela Jogo
    SET i = 1;
    WHILE i <= 20 DO
        INSERT INTO Jogo (Nome, Preco, Categoria, Estoque) VALUES
        (CONCAT('Jogo ', i), RAND() * 100, 'Categoria', FLOOR(RAND() * 50) + 1);
        SET i = i + 1;
    END WHILE;

    -- Inserir 20 registros na tabela Venda e VendaItem
    SET i = 1;
    
    WHILE i <= 20 DO
    
		SET cliente = (SELECT ID FROM Cliente ORDER BY RAND() LIMIT 1);
        SET funcionario = (SELECT ID FROM Funcionario ORDER BY RAND() LIMIT 1);
        
        INSERT INTO Venda (Total, ClienteID, FuncionarioID, Data) VALUES
        (0, cliente, funcionario, DATE_ADD(CURRENT_DATE, INTERVAL FLOOR(RAND() * 30) DAY));
        
        CALL AlimentarVendaItem(LAST_INSERT_ID());
        
        SET i = i + 1;
    END WHILE;

END$$
DELIMITER ;

# ---------------------------
-- Chamadas
# ---------------------------

CALL AlimentarDados();

-- Realizando UPDATE
UPDATE Cliente SET Nome = 'Cliente Atualizado' WHERE ID <= 4;
UPDATE Jogo SET Estoque = Estoque - 2 WHERE ID <= 4;
UPDATE Venda SET Total = Total * 1.1 WHERE ID <= 4;

-- Deletando alguns dados
DELETE FROM ItemVenda where VendaID = 1;
DELETE FROM Venda where ID = 1;

-- Atualizando dados
UPDATE Cliente SET Telefone = '0000000000' WHERE ID <= 6;
UPDATE Jogo SET Preco = Preco * 1.05 WHERE ID <= 6;

-- INNER JOIN: Mostrar vendas, clientes e funcionários associados
SELECT v.ID as codigoVenda, 
	   v.Data as DataHoraVenda,
       v.total as TotalVenda,
       c.Nome as Cliente,
       f.Nome as Funcionario
FROM Venda v
INNER JOIN Cliente c ON v.ClienteID = c.ID
INNER JOIN Funcionario f on v.FuncionarioID = f.ID;

-- Mostrar jogos e, se houver, itens de venda associados
SELECT j.Nome,
	   iv.vendaID as CodigoVenda,
	   iv.Quantidade as QuantidadeVendida
FROM Jogo j
LEFT JOIN ItemVenda iv ON j.ID = iv.JogoID;

--  Verificar vendas e clientes mesmo que não hajam clientes associados.
SELECT c.ID as CodigoCliente,
	   c.Nome as Cliente, 
	   v.id as CodigoVenda
FROM Venda as v
RIGHT JOIN cliente as c ON v.clienteID = c.ID;

-- View com os gastos por cliente
CREATE VIEW ViewClientesVendas AS
SELECT c.id as CodigoCliente, c.Nome AS Cliente, COUNT(v.ID) AS TotalVendas, SUM(v.Total) AS TotalGasto
FROM Cliente c
LEFT JOIN Venda v ON c.ID = v.ClienteID
GROUP BY c.ID;

-- Utilizando uma Variável
SET @quantidadeJogos = (SELECT COUNT(*) FROM Jogo);
SELECT CONCAT('Total de jogos disponíveis: ', @quantidadeJogos);