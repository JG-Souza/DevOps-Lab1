require("dotenv").config();

const express = require("express");
const { Pool } = require("pg");

// --- CONFIGURAÇÃO ---
const PORT = process.env.PORT || 3000;

// Configuração do Pool de Conexão com o PostgreSQL
const pool = new Pool({
  user: process.env.DB_USER || "postgres",
  host: process.env.DB_HOST || "localhost",
  database: process.env.DB_NAME || "visit_counter_db",
  password: process.env.DB_PASSWORD || "password",
  port: process.env.DB_PORT || 5432,
});

// --- INICIALIZAÇÃO DO BANCO DE DADOS ---
// Função que garante que a tabela 'visits' exista.
const initializeDatabase = async () => {
  try {
    const client = await pool.connect();
    console.log("Conectado ao PostgreSQL com sucesso!");

    await client.query(`
      CREATE TABLE IF NOT EXISTS visits (
        id INT PRIMARY KEY,
        count INT NOT NULL
      );
    `);

    // Insere a linha inicial do contador se ela não existir
    await client.query(`
      INSERT INTO visits (id, count)
      VALUES (1, 0)
      ON CONFLICT (id) DO NOTHING;
    `);

    client.release();
    console.log("Banco de dados inicializado e pronto.");
  } catch (error) {
    console.error("Erro ao inicializar o banco de dados:", error);
    // Encerra o processo se não conseguir conectar/inicializar o DB após algumas tentativas
    process.exit(1);
  }
};

// --- APLICAÇÃO EXPRESS ---
const app = express();

app.get("/", async (req, res) => {
  try {
    // Incrementa o contador e retorna o novo valor em uma única transação
    const result = await pool.query(
      "UPDATE visits SET count = count + 1 WHERE id = 1 RETURNING count;"
    );

    if (result.rows.length === 0) {
      throw new Error("Contador não encontrado no banco de dados.");
    }

    const visitCount = result.rows[0].count;
    res.status(200).send(`Olá! Esta página foi visitada ${visitCount} vezes.`);
  } catch (error) {
    console.error("Erro ao processar a requisição:", error);
    res
      .status(500)
      .send("Ocorreu um erro no servidor. Não foi possível contar a visita.");
  }
});

// --- INICIALIZAÇÃO DO SERVIDOR ---
const startServer = async () => {
  await initializeDatabase();
  app.listen(PORT, () => {
    console.log(`Servidor rodando na porta ${PORT}`);
  });
};

startServer();
