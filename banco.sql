-- =============================================
-- SISTEMA EMPRESARIAL - BANCO DE DADOS COMPLETO
-- =============================================

-- Habilitar extensões
CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA extensions;

-- =============================================
-- SCHEMAS
-- =============================================
CREATE SCHEMA IF NOT EXISTS business;
CREATE SCHEMA IF NOT EXISTS financial;
CREATE SCHEMA IF NOT EXISTS inventory;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS monitoring;
CREATE SCHEMA IF NOT EXISTS validation;
CREATE SCHEMA IF NOT EXISTS data_governance;

-- =============================================
-- VALIDAÇÕES (CPF, CNPJ, EMAIL)
-- =============================================
CREATE OR REPLACE FUNCTION validation.validate_cpf(p_cpf TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_cpf TEXT;
    v_sum INTEGER;
    v_digit1 INTEGER;
    v_digit2 INTEGER;
BEGIN
    v_cpf := REGEXP_REPLACE(p_cpf, '[^\d]', '', 'g');
    IF length(v_cpf) != 11 THEN RETURN FALSE; END IF;

    v_sum := 0;
    FOR i IN 1..9 LOOP
        v_sum := v_sum + (CAST(SUBSTRING(v_cpf, i, 1) AS INTEGER) * (11 - i));
    END LOOP;
    v_digit1 := 11 - (v_sum % 11);
    IF v_digit1 >= 10 THEN v_digit1 := 0; END IF;

    v_sum := 0;
    FOR i IN 1..10 LOOP
        v_sum := v_sum + (CAST(SUBSTRING(v_cpf, i, 1) AS INTEGER) * (12 - i));
    END LOOP;
    v_digit2 := 11 - (v_sum % 11);
    IF v_digit2 >= 10 THEN v_digit2 := 0; END IF;

    RETURN (CAST(SUBSTRING(v_cpf, 10, 1) AS INTEGER) = v_digit1 AND
            CAST(SUBSTRING(v_cpf, 11, 1) AS INTEGER) = v_digit2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION validation.validate_cnpj(p_cnpj TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_cnpj TEXT;
    v_sum INTEGER;
    v_digit1 INTEGER;
    v_digit2 INTEGER;
BEGIN
    v_cnpj := REGEXP_REPLACE(p_cnpj, '[^\d]', '', 'g');
    IF length(v_cnpj) != 14 THEN RETURN FALSE; END IF;

    v_sum := (CAST(SUBSTRING(v_cnpj, 1, 1) AS INTEGER) * 5) +
             (CAST(SUBSTRING(v_cnpj, 2, 1) AS INTEGER) * 4) +
             (CAST(SUBSTRING(v_cnpj, 3, 1) AS INTEGER) * 3) +
             (CAST(SUBSTRING(v_cnpj, 4, 1) AS INTEGER) * 2) +
             (CAST(SUBSTRING(v_cnpj, 5, 1) AS INTEGER) * 9) +
             (CAST(SUBSTRING(v_cnpj, 6, 1) AS INTEGER) * 8) +
             (CAST(SUBSTRING(v_cnpj, 7, 1) AS INTEGER) * 7) +
             (CAST(SUBSTRING(v_cnpj, 8, 1) AS INTEGER) * 6) +
             (CAST(SUBSTRING(v_cnpj, 9, 1) AS INTEGER) * 5) +
             (CAST(SUBSTRING(v_cnpj, 10, 1) AS INTEGER) * 4) +
             (CAST(SUBSTRING(v_cnpj, 11, 1) AS INTEGER) * 3) +
             (CAST(SUBSTRING(v_cnpj, 12, 1) AS INTEGER) * 2);
    v_digit1 := 11 - (v_sum % 11);
    IF v_digit1 >= 10 THEN v_digit1 := 0; END IF;

    v_sum := (CAST(SUBSTRING(v_cnpj, 1, 1) AS INTEGER) * 6) +
             (CAST(SUBSTRING(v_cnpj, 2, 1) AS INTEGER) * 5) +
             (CAST(SUBSTRING(v_cnpj, 3, 1) AS INTEGER) * 4) +
             (CAST(SUBSTRING(v_cnpj, 4, 1) AS INTEGER) * 3) +
             (CAST(SUBSTRING(v_cnpj, 5, 1) AS INTEGER) * 2) +
             (CAST(SUBSTRING(v_cnpj, 6, 1) AS INTEGER) * 9) +
             (CAST(SUBSTRING(v_cnpj, 7, 1) AS INTEGER) * 8) +
             (CAST(SUBSTRING(v_cnpj, 8, 1) AS INTEGER) * 7) +
             (CAST(SUBSTRING(v_cnpj, 9, 1) AS INTEGER) * 6) +
             (CAST(SUBSTRING(v_cnpj, 10, 1) AS INTEGER) * 5) +
             (CAST(SUBSTRING(v_cnpj, 11, 1) AS INTEGER) * 4) +
             (CAST(SUBSTRING(v_cnpj, 12, 1) AS INTEGER) * 3) +
             (v_digit1 * 2);
    v_digit2 := 11 - (v_sum % 11);
    IF v_digit2 >= 10 THEN v_digit2 := 0; END IF;

    RETURN (CAST(SUBSTRING(v_cnpj, 13, 1) AS INTEGER) = v_digit1 AND
            CAST(SUBSTRING(v_cnpj, 14, 1) AS INTEGER) = v_digit2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =============================================
-- CLIENTES
-- =============================================
CREATE TABLE business.clientes (
    id BIGSERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    cnpj_cpf TEXT NOT NULL UNIQUE,
    telefone TEXT,
    email TEXT CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
    endereco JSONB,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- Validação do documento
ALTER TABLE business.clientes ADD CONSTRAINT chk_documento_valido
CHECK (validation.validate_cpf(cnpj_cpf) OR validation.validate_cnpj(cnpj_cpf));

-- Índices
CREATE INDEX idx_clientes_cnpj_cpf ON business.clientes(cnpj_cpf);
CREATE INDEX idx_clientes_email ON business.clientes(email);

-- Trigger para atualizar "atualizado_em"
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_clientes
BEFORE UPDATE ON business.clientes
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE business.clientes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuários veem clientes" ON business.clientes
FOR SELECT TO authenticated USING (true);

CREATE POLICY "Usuários inserem clientes" ON business.clientes
FOR INSERT TO authenticated WITH CHECK (true);
