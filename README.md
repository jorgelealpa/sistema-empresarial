# 🏢 Sistema Empresarial - Banco de Dados

Um sistema completo para gestão empresarial com PostgreSQL, focado em segurança, auditoria, RLS (Row Level Security) e boas práticas.

## 📁 Estrutura

- `banco.sql`: Script completo do banco (tabelas, funções, RLS, triggers, validações).
- `schemas/`: Divisão por áreas (clientes, projetos, financeiro, estoque).
- `security/`: Políticas, criptografia, auditoria.
- `monitoring/`: Funções de desempenho e alertas.

## ✅ Funcionalidades

- ✅ Validação de CPF/CNPJ
- ✅ RLS para multi-tenancy
- ✅ Auditoria avançada
- ✅ Criptografia de dados sensíveis
- ✅ Monitoramento de queries lentas
- ✅ Materialized views para BI

## 🚀 Como usar

1. Clone o repositório
2. Execute `banco.sql` no seu PostgreSQL
3. Conecte à sua aplicação (Supabase, Django, Node.js, etc)

---

Feito com ❤️ para sistemas escaláveis e seguros.
